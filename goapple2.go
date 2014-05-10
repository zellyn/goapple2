package goapple2

import (
	"fmt"
	"io/ioutil"
	"log"
	"path/filepath"
	"strconv"

	"github.com/zellyn/go6502/cpu"
	"github.com/zellyn/goapple2/cards"
	"github.com/zellyn/goapple2/videoscan"
)

type PCActionType int

const (
	ActionDumpMem PCActionType = iota + 1
	ActionLogRegisters
	ActionTrace
	ActionSetLimit
	ActionHere
	ActionDiskStatus
)

type PCAction struct {
	Type   PCActionType
	String string
	Mask   byte
	Masked byte
	Delay  uint64
}

// Apple II struct
type Apple2 struct {
	mem             [65536]byte
	cpu             cpu.Cpu
	key             byte // BUG(zellyn): make reads/writes atomic
	keys            chan byte
	plotter         videoscan.Plotter
	scanner         *videoscan.Scanner
	Done            bool
	lastRead        byte
	cards           [8]cards.Card "Peripheral cards"
	cardMask        byte
	cardRomMask     byte
	cardRomConflict bool "True if more than one card is handling the 2k ROM area"
	cardRomHandler  byte
	card12kMask     byte
	card12kConflict bool "True if more than one card is handling the 12k ROM area"
	card12kHandler  byte
	cardTickerMask  byte
	pcActions       map[uint16][]*PCAction
	limit           int
	cycle           uint64
}

func NewApple2(p videoscan.Plotter, rom []byte, charRom [2048]byte) *Apple2 {
	a2 := &Apple2{
		// BUG(zellyn): this is not how the apple2 keyboard actually works
		keys:      make(chan byte, 16),
		pcActions: make(map[uint16][]*PCAction),
	}
	copy(a2.mem[len(a2.mem)-len(rom):len(a2.mem)], rom)
	a2.scanner = videoscan.NewScanner(a2, p, charRom)
	a2.cpu = cpu.NewCPU(a2, a2.Tick, cpu.VERSION_6502)
	a2.cpu.Reset()
	return a2
}

func (a2 *Apple2) AddCard(card cards.Card) error {
	slot := card.Slot()
	slotbit := byte(1 << slot)
	if slotbit&a2.cardMask > 0 {
		return fmt.Errorf("Slot %d already has a card: %s", slot, a2.cards[slot])
	}
	a2.cardMask |= slotbit
	if card.WantTicker() {
		a2.cardTickerMask |= slotbit
	}
	a2.cards[slot] = card
	return nil
}

func (a2 *Apple2) handleCardRom(address uint16, value byte, write bool) byte {
	return a2.EmptyRead()
}

func (a2 *Apple2) handleC00X(address uint16, value byte, write bool) byte {
	if address < 0xC080 {
		switch address & 0xC0F0 {
		// $C00X: Read keyboard
		case 0xC000:
			if a2.key&0x80 == 0 {
				select {
				case key := <-a2.keys:
					a2.key = key
				default:
				}
			}
			return a2.key
		// $C01X: Reset keyboard
		case 0xC010:
			a2.key &= 0x7F
			return a2.EmptyRead()
		}
		switch address {
		case 0xC050: // GRAPHICS
			fmt.Printf("$%04X: GRAPHICS\n", a2.cpu.PC())
			a2.scanner.SetGraphics(true)
		case 0xC051: // TEXT
			fmt.Printf("$%04X: NO GRAPHICS\n", a2.cpu.PC())
			a2.scanner.SetGraphics(false)
		case 0xC052: // NOMIX
			fmt.Printf("$%04X: NOMIX\n", a2.cpu.PC())
			a2.scanner.SetMix(false)
		case 0xC053: // MIX
			fmt.Printf("$%04X: MIX\n", a2.cpu.PC())
			a2.scanner.SetMix(true)
		case 0xC054: // PAGE 1
			fmt.Printf("$%04X: PAGE1\n", a2.cpu.PC())
			a2.scanner.SetPage(1)
		case 0xC055: // PAGE 2
			fmt.Printf("$%04X: PAGE2\n", a2.cpu.PC())
			a2.scanner.SetPage(2)
		case 0xC056: // LORES
			fmt.Printf("$%04X: LORES\n", a2.cpu.PC())
			a2.scanner.SetHires(false)
		case 0xC057: // HIRES
			fmt.Printf("$%04X: HIRES\n", a2.cpu.PC())
			a2.scanner.SetHires(true)
		}
	}

	if address < 0xC080 {
		return a2.EmptyRead()
	}

	if address < 0xC100 {
		slot := byte((address - 0xC080) >> 4)
		if a2.cards[slot] != nil {
			if write {
				a2.cards[slot].Write16(byte(address&0xF), value)
				return 0
			} else {
				return a2.cards[slot].Read16(byte(address & 0xF))
			}
		}
		return a2.EmptyRead()
	}

	if address < 0xC800 {
		slot := byte((address - 0xC000) >> 8)
		if a2.cards[slot] != nil {
			if write {
				a2.cards[slot].Write256(byte(address&0xFF), value)
				return 0
			} else {
				return a2.cards[slot].Read256(byte(address & 0xFF))
			}
		}
		return a2.EmptyRead()
	}

	// 0xCFFF disables 2k on all cards
	if address == 0xCFFF {
		for i := 0; a2.cardMask > 0; a2.cardMask >>= 1 {
			if a2.cardMask&1 > 0 {
				a2.cards[i].ROMDisabled()
			}
			i++
		}
		return a2.EmptyRead()
	}

	// Only addresses left are 0xC800-0xCFFE
	if a2.cardRomMask == 0 {
		return a2.EmptyRead()
	}
	if a2.cardRomConflict {
		panic(fmt.Sprintf("More than one card trying to provide 2K ROM: Mask=$%02X", a2.cardRomMask))
	}

	if write {
		a2.cards[a2.cardRomHandler].Write(address, value)
		return 0
	}
	return a2.cards[a2.cardRomHandler].Read(address)
}

// EmptyRead returns the value last read from RAM, lingering on the bus.
func (a2 *Apple2) EmptyRead() byte {
	return a2.lastRead
}

func (a2 *Apple2) Read(address uint16) byte {
	if address&0xF000 == 0xC000 {
		return a2.handleC00X(address, 0, false)
	}
	if address >= 0xD000 && a2.cardRomMask > 0 {
		if a2.card12kConflict {
			panic(fmt.Sprintf("More than one card trying to provide 12K ROM: Mask=$%02X", a2.card12kMask))
		}
		a2.lastRead = a2.cards[a2.card12kHandler].Read(address)
		return a2.lastRead
	}

	a2.lastRead = a2.mem[address]
	return a2.lastRead
}

func (a2 *Apple2) RamRead(address uint16) byte {
	a2.lastRead = a2.mem[address]
	return a2.lastRead
}

func (a2 *Apple2) Write(address uint16, value byte) {
	// if address == 0x46 {
	// 	fmt.Printf("Write to 0x46: PC==$%04X\n", a2.cpu.PC())
	// }
	if address >= 0xD000 {
		if a2.cardRomMask > 0 {
			if a2.card12kConflict {
				panic(fmt.Sprintf("More than one card trying to provide 12K ROM: Mask=$%02X", a2.card12kMask))
			}
			a2.cards[a2.card12kHandler].Write(address, value)
		}
		return
	}
	if address&0xF000 == 0xC000 {
		a2.handleC00X(address, value, true)
		return
	}
	a2.mem[address] = value

}

func (a2 *Apple2) Keypress(key byte) {
	a2.keys <- key | 0x80
}

func (a2 *Apple2) AddPCAction(address uint16, action PCAction) {
	a2.pcActions[address] = append(a2.pcActions[address], &action)
}

func (a2 *Apple2) Step() error {
	p := a2.cpu.P()
	if actions, ok := a2.pcActions[a2.cpu.PC()]; ok {
		for _, action := range actions {
			if p&action.Mask != action.Masked {
				continue
			}
			if action.Delay > 0 {
				fmt.Printf("Delaying %v: %d\n", action.Type, action.Delay)
				action.Delay--
				continue
			}
			switch action.Type {
			case ActionDumpMem:
				a2.DumpRAM(action.String)
			case ActionLogRegisters:
				a2.LogRegisters()
			case ActionTrace:
				a2.cpu.Print(action.String == "on" || action.String == "true")
			case ActionSetLimit:
				if i, err := strconv.Atoi(action.String); err == nil {
					a2.limit = i
				} else {
					panic(err)
				}
			case ActionHere:
				fmt.Printf("$%04X: (%d) %s - A=$%02X X=$%02X Y=$%02X SP=$%02X P=$%08b\n",
					a2.cpu.PC(), a2.cycle, action.String,
					a2.cpu.A(), a2.cpu.X(), a2.cpu.Y(), a2.cpu.SP(), a2.cpu.P())
			case ActionDiskStatus:
				fmt.Printf("$%04X: %v\n",
					a2.cpu.PC(), a2.cards[6])
			}
		}
	}
	err := a2.cpu.Step()
	if a2.limit > 0 {
		a2.limit--
		if a2.limit == 0 {
			a2.DumpRAM("limit-goa2.bin")
			panic("Limit reached")
		}
	}
	a2.cycle++
	return err
}

func (a2 *Apple2) Tick() {
	a2.scanner.Scan1()
	tickerMask := a2.cardTickerMask
	for i := 0; i < 8 && tickerMask > 0; i++ {
		if tickerMask&1 == 1 {
			a2.cards[i].Tick()
		}
		tickerMask >>= 1
	}
}

func (a2 *Apple2) Quit() {
	a2.Done = true
}

func (a2 *Apple2) HandleROM(onOff bool, slot byte) {
	if onOff {
		a2.cardRomMask |= (1 << slot)
		a2.cardRomHandler = slot
	} else {
		a2.cardRomMask &^= (1 << slot)
	}
	a2.cardRomConflict = a2.cardRomMask&(a2.cardRomMask-1) > 0
	if !onOff && !a2.cardRomConflict && a2.cardRomMask > 0 {
		// Removed a card: figure out new handler
		for i := byte(0); i < 7; i++ {
			if 1<<i == a2.cardRomMask {
				a2.cardRomHandler = i
				return
			}
		}
	}
}

func (a2 *Apple2) Handle12k(onOff bool, slot byte) {
	if onOff {
		a2.card12kMask |= slot
	} else {
		a2.card12kMask &^= slot
	}
	a2.card12kConflict = a2.card12kMask&(a2.card12kMask-1) > 0
	if !onOff && !a2.card12kConflict && a2.card12kMask > 0 {
		// Removed a card: figure out new handler
		for i := byte(0); i < 7; i++ {
			if 1<<i == a2.card12kMask {
				a2.card12kHandler = i
				return
			}
		}
	}
}

func (a2 *Apple2) LogRegisters() {
	c := a2.cpu
	log.Printf("Registers: PC=$%04X A=$%02X X=$%02X Y=$%02X SP=$%02X P=$%02X=$%08b",
		c.PC(), c.A(), c.X(), c.Y(), c.SP(), c.P(), c.P())
}

var dumpCount = 0

func (a2 *Apple2) DumpRAM(filename string) error {
	f := filename
	dumpCount++
	ts := "-" + fmt.Sprintf("%05d", dumpCount)
	if ext := filepath.Ext(filename); ext == "" {
		f = filename + ts
	} else {
		dir, file := filepath.Split(filename[:len(filename)-len(ext)])
		f = dir + file + ts + ext
	}
	log.Printf("Dumping RAM to %s", f)
	a2.LogRegisters()
	buf := make([]byte, 0xC000, 0xC000+20)
	copy(buf, a2.mem[:0xC000])
	// LDA $A
	// LDX $X
	// LDY $Y
	buf = append(buf, 0xA9, a2.cpu.A(), 0xA2, a2.cpu.X(), 0xA0, a2.cpu.Y())
	// PHP, PLA, CMP $P
	buf = append(buf, 0x08, 0x68, 0xC9, a2.cpu.P())
	// TSX, CPX $SP
	buf = append(buf, 0xBA, 0xE0, a2.cpu.SP())
	// JMP $PC
	buf = append(buf, 0x4C, byte(a2.cpu.PC()&0xFF), byte(a2.cpu.PC()>>8))
	return ioutil.WriteFile(f, buf, 0644)
}
