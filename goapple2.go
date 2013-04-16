package goapple2

import (
	"fmt"

	"github.com/zellyn/go6502/cpu"
	"github.com/zellyn/goapple2/cards"
	"github.com/zellyn/goapple2/videoscan"
)

// Memory for the tests. Satisfies the cpu.Memory interface.
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
}

func NewApple2(p videoscan.Plotter, rom []byte, charRom [2048]byte) *Apple2 {
	a2 := Apple2{
		// BUG(zellyn): this is not how the apple2 keyboard actually works
		keys: make(chan byte, 16),
	}
	copy(a2.mem[len(a2.mem)-len(rom):len(a2.mem)], rom)
	a2.scanner = videoscan.NewScanner(&a2, p, charRom)
	a2.cpu = cpu.NewCPU(&a2, &a2, cpu.VERSION_6502)
	a2.cpu.Reset()
	return &a2
}

func (a2 *Apple2) AddCard(card cards.Card) error {
	slot := card.Slot()
	slotbit := byte(1 << slot)
	if slotbit&a2.cardMask > 0 {
		return fmt.Errorf("Slot %d already has a card: %s", slot, a2.cards[slot])
	}
	a2.cardMask |= slotbit
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
			a2.scanner.SetGraphics(true)
		case 0xC051: // TEXT
			a2.scanner.SetGraphics(false)
		case 0xC052: // NOMIX
			a2.scanner.SetMix(false)
		case 0xC053: // MIX
			a2.scanner.SetMix(true)
		case 0xC054: // PAGE 1
			a2.scanner.SetPage(1)
		case 0xC055: // PAGE 2
			a2.scanner.SetPage(2)
		case 0xC056: // LORES
			a2.scanner.SetHires(false)
		case 0xC057: // HIRES
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

func (a2 *Apple2) Step() error {
	return a2.cpu.Step()
}

func (a2 *Apple2) Tick() {
	a2.scanner.Scan1()
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
