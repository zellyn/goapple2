package cards

import (
	"fmt"

	"github.com/zellyn/goapple2/disk"
)

type Disk interface {
	Read() byte
	Skip(int)
	Write(byte)
	SetHalfTrack(byte)
	HalfTrack() byte
	SetVolume(byte)
	Volume() byte
	Writeable() bool
}

const (
	MODE_READ  = 0
	MODE_WRITE = 1
	MODE_SHIFT = 0
	MODE_LOAD  = 2
)

type DiskCard struct {
	rom          [256]byte
	cm           CardManager
	slot         byte
	slotbit      byte
	disks        [2]Disk
	active       int
	phases       byte
	mode         byte
	onOff        bool
	dataRegister byte
	lastAccess   int
}

func NewDiskCard(rom []byte, slot byte, cm CardManager) (*DiskCard, error) {
	if len(rom) != 256 {
		return nil, fmt.Errorf("Wrong size ROM: expected 256, got %d", len(rom))
	}
	dc := &DiskCard{
		cm:      cm,
		slot:    slot,
		slotbit: 1 << slot,
		disks:   [2]Disk{disk.NewDummy(disk.DEFAULT_VOLUME), disk.NewDummy(disk.DEFAULT_VOLUME)},
	}
	copy(dc.rom[:], rom)
	return dc, nil
}

func (dc *DiskCard) String() string {
	return fmt.Sprintf("Disk Card (slot %d)", dc.slot)
}

func (dc *DiskCard) Slot() byte {
	return dc.slot
}

func (dc *DiskCard) ROMDisabled() {
	// Disk card doesn't have a $C(8-F)xx ROM
}

func (dc *DiskCard) handlePhase(phase byte, onOff bool) {
	if !dc.onOff {
		return
	}
	phaseBit := byte(1 << phase)
	if onOff {
		dc.phases |= phaseBit
	} else {
		dc.phases &^= phaseBit
	}

	disk := dc.disks[dc.active]
	newTrack := int(disk.HalfTrack())
	switch dc.phases {
	case 1:
		newTrack = (newTrack + 1) / 4 * 4
	case 2:
		newTrack = (newTrack/4)*4 + 1
	case 4:
		if newTrack != 0 {
			newTrack = (newTrack-1)/4*4 + 2
		}
	case 8:
		if newTrack < 2 {
			newTrack = 0
		} else {
			newTrack = (newTrack-2)/4*4 + 3
		}
	default:
		return
	}
	if newTrack < 0 {
		newTrack = 0
	}
	if newTrack > 68 {
		newTrack = 68
	}
	if disk.HalfTrack() != byte(newTrack) {
		disk.SetHalfTrack(byte(newTrack))
	}
}

func (dc *DiskCard) handleAccess(address byte) {
	if address < 8 {
		phase := address / 2
		onOff := (address & 1) == 1
		dc.handlePhase(phase, onOff)
		return
	}
	switch address {
	case 0x8:
		dc.onOff = false
	case 0x9:
		dc.onOff = true
	case 0xA, 0xB:
		which := int(address & 1)
		if dc.active != which {
			dc.active = which
			dc.handlePhase(0, dc.phases&1 == 1) // No change: force update
		}
	case 0xC, 0xD:
		dc.mode = dc.mode&^2 | address&1<<2
	case 0xE, 0xF:
		dc.mode = dc.mode&^1 | address&1
	}
}

func (dc *DiskCard) Read16(address byte) byte {
	dc.handleAccess(address)
	if address != 0xC && address != 0xE {
		return 0xFF
	}
	if dc.onOff {
		switch dc.mode {
		case MODE_READ | MODE_SHIFT:
			// Normal read
			return dc.readOne()
		case MODE_READ | MODE_LOAD:
			// Check write-protect
			if dc.disks[dc.active].Writeable() {
				return 0x00
			} else {
				return 0xFF
			}
		case MODE_WRITE | MODE_SHIFT:
			// Doesn't do anything in our simulation: just return last data
			return dc.dataRegister
		case MODE_WRITE | MODE_LOAD:
			// Nonsense for reading: just return last data
			return dc.dataRegister
		}
	}
	return 0xFF
}

func (dc *DiskCard) Write16(address byte, value byte) {
	dc.handleAccess(address)
	if dc.onOff {
		switch dc.mode {
		case MODE_READ | MODE_SHIFT:
			// Normal read
			panic("Write while in read mode")
		case MODE_READ | MODE_LOAD:
			// Check write-protect
			panic("Write while in check-write-protect mode")
		case MODE_WRITE | MODE_SHIFT:
			// Shifting data to disk
			panic("Write while in shift mode")
		case MODE_WRITE | MODE_LOAD:
			if dc.disks[dc.active].Writeable() {
				dc.writeOne(value)
			}
		}
	}
}

func (dc *DiskCard) readOne() byte {
	if dc.lastAccess < 4 {
		return dc.dataRegister
	}
	disk := dc.disks[dc.active]
	if dc.lastAccess > 300 {
		disk.Skip(dc.lastAccess / 36)
	}
	dc.lastAccess = 0
	dc.dataRegister = disk.Read()
	return dc.dataRegister
}

func (dc *DiskCard) writeOne(value byte) {
	disk := dc.disks[dc.active]
	dc.dataRegister = value
	disk.Write(value)
}

func (dc *DiskCard) Read(address uint16) byte {
	panic(fmt.Sprintf("%s got read to $%04X", dc.String(), address))
}

func (dc *DiskCard) Write(address uint16, value byte) {
	panic(fmt.Sprintf("%s got write to $%04X", dc.String(), address))
}

func (dc *DiskCard) Read256(address byte) byte {
	return dc.rom[address]
}

func (dc *DiskCard) Write256(address byte, value byte) {
	// Firmware is ROM: do nothing
}

func (dc *DiskCard) LoadDisk(d Disk, which int) {
	dc.disks[which] = d
}

func (dc *DiskCard) WantTicker() bool {
	return true
}

func (dc *DiskCard) Tick() {
	dc.lastAccess++
}
