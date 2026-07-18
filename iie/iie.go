// Package iie implements the Apple IIe 128K memory system: 64K main RAM,
// 64K auxiliary RAM, the RAMRD/RAMWRT/ALTZP soft switches, and Language
// Card bank switching in both banks.
//
// It is a pure memory model with no video or peripheral emulation, designed
// to sit behind a 6502 core's Memory interface (Read(uint16) byte /
// Write(uint16, byte)). Display-coupled switches (80STORE/PAGE2/HIRES) are
// not implemented: with 80STORE off (the only supported state), RAMRD and
// RAMWRT govern all of $0200-$BFFF, which matches real hardware. Accesses
// to unimplemented $C0xx locations are counted in Unhandled so a harness
// can detect code that strays outside the supported subset.
//
// Switch semantics follow Understanding the Apple IIe (Sather), ch. 5:
//
//	$C002/$C003 w  RAMRD off/on   read main/aux in $0200-$BFFF
//	$C004/$C005 w  RAMWRT off/on  write main/aux in $0200-$BFFF
//	$C008/$C009 w  ALTZP off/on   main/aux for $0000-$01FF and LC RAM
//	$C011 r bit7   LC bank 2 selected
//	$C012 r bit7   LC RAM read enabled
//	$C013 r bit7   RAMRD on
//	$C014 r bit7   RAMWRT on
//	$C016 r bit7   ALTZP on
//	$C080-$C08F rw Language Card banking (see lcAccess)
package iie

// Memory is an Apple IIe 128K memory system.
type Memory struct {
	// Main and Aux hold the two 64K banks. The $D000-$DFFF region of each
	// holds Language Card bank 1; bank 2 lives in the D000Bank2 arrays.
	Main [0x10000]byte
	Aux  [0x10000]byte

	MainD000Bank2 [0x1000]byte
	AuxD000Bank2  [0x1000]byte

	// ROM is the $D000-$FFFF image returned when the Language Card has ROM
	// read enabled. Left zeroed if no ROM is loaded.
	ROM [0x3000]byte

	// Soft-switch state.
	RamRd  bool // reads of $0200-$BFFF come from aux
	RamWrt bool // writes of $0200-$BFFF go to aux
	AltZP  bool // $0000-$01FF and LC RAM come from aux

	LCReadRAM      bool // reads of $D000-$FFFF come from LC RAM, not ROM
	LCWriteEnabled bool // writes to $D000-$FFFF land in LC RAM
	LCBank2        bool // $D000-$DFFF maps to bank 2
	lcPrewrite     int  // consecutive odd-switch reads toward write enable

	// Unhandled counts accesses (by address) to $C0xx locations this model
	// does not implement, e.g. 80STORE, keyboard, or slot I/O.
	Unhandled map[uint16]int

	// Clock, if set, supplies the current CPU cycle count and enables the
	// $C019 VBL status read (RDVBLBAR: bit 7 low during vertical blanking
	// on the IIe). The frame is 17,030 cycles, of which 4,550 are VBL.
	Clock func() uint64
}

// Apple IIe video frame timing, in 1.0205 MHz CPU cycles.
const (
	FrameCycles = 17030 // 65 cycles x 262 lines
	VBLCycles   = 4550  // 65 cycles x 70 lines of vertical blanking
)

// New returns a Memory in the reset state: all switches off, LC reading
// ROM with writes disabled, bank 2 selected. Programs must run the same
// soft-switch setup they would need on real hardware.
func New() *Memory {
	return &Memory{
		LCBank2:   true,
		Unhandled: map[uint16]int{},
	}
}

// bank returns aux if the flag is set, else main.
func (m *Memory) bank(aux bool) *[0x10000]byte {
	if aux {
		return &m.Aux
	}
	return &m.Main
}

// lcRAM returns a pointer to the byte backing the LC RAM at addr
// ($D000-$FFFF), honoring ALTZP and bank 2.
func (m *Memory) lcRAM(addr uint16) *byte {
	if m.LCBank2 && addr < 0xE000 {
		if m.AltZP {
			return &m.AuxD000Bank2[addr-0xD000]
		}
		return &m.MainD000Bank2[addr-0xD000]
	}
	return &m.bank(m.AltZP)[addr]
}

// Read reads a byte through the current banking. Reads of $C08x have the
// usual Language Card switching side effects.
func (m *Memory) Read(addr uint16) byte {
	switch {
	case addr < 0x0200:
		return m.bank(m.AltZP)[addr]
	case addr < 0xC000:
		return m.bank(m.RamRd)[addr]
	case addr < 0xD000:
		return m.ioRead(addr)
	default:
		if m.LCReadRAM {
			return *m.lcRAM(addr)
		}
		return m.ROM[addr-0xD000]
	}
}

// Write writes a byte through the current banking.
func (m *Memory) Write(addr uint16, val byte) {
	switch {
	case addr < 0x0200:
		m.bank(m.AltZP)[addr] = val
	case addr < 0xC000:
		m.bank(m.RamWrt)[addr] = val
	case addr < 0xD000:
		m.ioWrite(addr, val)
	default:
		if m.LCWriteEnabled {
			*m.lcRAM(addr) = val
		}
	}
}

// Peek reads a byte through the current banking with no side effects: I/O
// page reads return status bits where defined (or 0) without triggering
// Language Card switching. For debuggers and memory dumps.
func (m *Memory) Peek(addr uint16) byte {
	if addr >= 0xC000 && addr < 0xD000 {
		switch addr {
		case 0xC011:
			return status(m.LCBank2)
		case 0xC012:
			return status(m.LCReadRAM)
		case 0xC013:
			return status(m.RamRd)
		case 0xC014:
			return status(m.RamWrt)
		case 0xC016:
			return status(m.AltZP)
		case 0xC019:
			if m.Clock != nil {
				return status(m.Clock()%FrameCycles >= VBLCycles)
			}
		}
		return 0
	}
	return m.Read(addr)
}

// status returns $80 if b is set, else 0, matching IIe status-read bit 7.
func status(b bool) byte {
	if b {
		return 0x80
	}
	return 0
}

func (m *Memory) ioRead(addr uint16) byte {
	if addr >= 0xC080 && addr <= 0xC08F {
		m.lcAccess(addr, false)
		return 0xA0 // approximation of floating bus
	}
	switch addr {
	case 0xC011:
		return status(m.LCBank2)
	case 0xC012:
		return status(m.LCReadRAM)
	case 0xC013:
		return status(m.RamRd)
	case 0xC014:
		return status(m.RamWrt)
	case 0xC016:
		return status(m.AltZP)
	case 0xC018: // RD80STORE: always off
		return 0
	case 0xC019: // RDVBLBAR: bit 7 low during VBL (IIe sense)
		if m.Clock != nil {
			return status(m.Clock()%FrameCycles >= VBLCycles)
		}
	}
	m.Unhandled[addr]++
	return 0
}

func (m *Memory) ioWrite(addr uint16, val byte) {
	if addr >= 0xC080 && addr <= 0xC08F {
		m.lcAccess(addr, true)
		return
	}
	switch addr {
	case 0xC002:
		m.RamRd = false
	case 0xC003:
		m.RamRd = true
	case 0xC004:
		m.RamWrt = false
	case 0xC005:
		m.RamWrt = true
	case 0xC008:
		m.AltZP = false
	case 0xC009:
		m.AltZP = true
	default:
		m.Unhandled[addr]++
	}
}

// lcAccess handles a read or write access to $C080-$C08F.
//
//	bit 3 clear: bank 2       bit 3 set: bank 1
//	low bits 00 or 11: read LC RAM; 01 or 10: read ROM
//	odd address: two consecutive READS enable writing to LC RAM
//	even address: disable writing
func (m *Memory) lcAccess(addr uint16, write bool) {
	n := addr & 0x0F
	m.LCBank2 = n&8 == 0
	low2 := n & 3
	m.LCReadRAM = low2 == 0 || low2 == 3
	if n&1 == 1 {
		if write {
			m.lcPrewrite = 0
		} else {
			m.lcPrewrite++
			if m.lcPrewrite >= 2 {
				m.LCWriteEnabled = true
			}
		}
	} else {
		m.LCWriteEnabled = false
		m.lcPrewrite = 0
	}
}
