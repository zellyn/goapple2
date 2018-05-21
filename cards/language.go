package cards

import (
	"fmt"
)

type LanguageCard struct {
	name      string
	rom       [12288]byte
	ram       [16384]byte
	cm        CardManager
	slot      byte
	slotbit   byte
	bank      int // 1 = bank 1, 0 = bank 2
	ramread   bool
	ramwrite  bool
	readcount int
}

func NewLanguageCard(rom []byte, name string, slot byte, cm CardManager) (*LanguageCard, error) {
	if len(rom) != 12288 {
		return nil, fmt.Errorf("Wrong size ROM: expected 12288, got %d", len(rom))
	}
	lc := &LanguageCard{
		name:      name,
		cm:        cm,
		slot:      slot,
		slotbit:   1 << slot,
		bank:      0,
		ramread:   false,
		ramwrite:  true,
		readcount: 0,
	}
	copy(lc.rom[:], rom)
	return lc, nil
}

func (lc *LanguageCard) String() string {
	return fmt.Sprintf("%s (slot %d)", lc.name, lc.slot)
}

// Init: language card should always handle D000-FFFF accessess, since
// it contains either RAM or ROM.
func (lc *LanguageCard) Init() {
	lc.cm.Handle12k(true, lc.slot)
}

func (lc *LanguageCard) Slot() byte {
	return lc.slot
}

func (lc *LanguageCard) ROMDisabled() {
	// Language card doesn't have a $C(8-F)xx ROM
}

func (lc *LanguageCard) handleAccess(address byte, write bool) {
	if write {
		lc.readcount = 0
	}

	address &^= 4
	switch address &^ 8 {
	case 0:
		lc.ramread = true
		lc.ramwrite = false
		lc.readcount = 0
	case 1:
		lc.ramread = false
		if lc.readcount > 0 {
			lc.ramwrite = true
		}
		if !write {
			lc.readcount++
		}
	case 2:
		lc.ramread = false
		lc.ramwrite = false
		lc.readcount = 0
	case 3:
		lc.ramread = true
		if lc.readcount > 0 {
			lc.ramwrite = true
		}
		if !write {
			lc.readcount++
		}
	}
	lc.bank = int((address & 8) >> 3)
	// fmt.Printf("ramread: %v, ramwrite: %v, bank: %d, readcount: %d\n", lc.ramread, lc.ramwrite, lc.bank, lc.readcount)
}

func (lc *LanguageCard) Read16(address byte) byte {
	// fmt.Printf("Read to %02xd: ", address)
	lc.handleAccess(address, false)
	return lc.cm.EmptyRead()
}

func (lc *LanguageCard) Write16(address byte, value byte) {
	// fmt.Printf("Write to %02xd: ", address)
	lc.handleAccess(address, true)
}

func (lc *LanguageCard) ramOffset(address uint16) uint16 {
	if address < 0xE000 {
		return address - 0xD000 + 0x1000*uint16(lc.bank)
	}
	return address - 0xE000 + 0x2000
}

func (lc *LanguageCard) Read(address uint16) byte {
	// fmt.Printf("Read from %04x\n", address)
	if address < 0xD000 {
		panic(fmt.Sprintf("%s got read to $%04X (<$D000)", lc.String(), address))
	}
	if lc.ramread {
		return lc.ram[lc.ramOffset(address)]
	}
	return lc.rom[address-0xD000]
}

func (lc *LanguageCard) Write(address uint16, value byte) {
	// fmt.Printf("Write to %04x\n", address)
	if lc.ramwrite {
		lc.ram[lc.ramOffset(address)] = value
	}
}

func (lc *LanguageCard) Read256(address byte) byte {
	return lc.cm.EmptyRead()
}

func (lc *LanguageCard) Write256(address byte, value byte) {
	// Language is ROM: do nothing
}

func (lc *LanguageCard) WantTicker() bool {
	return false
}

func (lc *LanguageCard) Tick() {
	// do nothing
}
