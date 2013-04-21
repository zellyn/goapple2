package cards

import (
	"fmt"
)

type FirmwareCard struct {
	name    string
	rom     [12288]byte
	cm      CardManager
	slot    byte
	slotbit byte
}

func NewFirmwareCard(rom []byte, name string, slot byte, cm CardManager) (*FirmwareCard, error) {
	if len(rom) != 12288 {
		return nil, fmt.Errorf("Wrong size ROM: expected 12288, got %d", len(rom))
	}
	fc := &FirmwareCard{name: name, cm: cm, slot: slot, slotbit: 1 << slot}
	copy(fc.rom[:], rom)
	return fc, nil
}

func (fc *FirmwareCard) String() string {
	return fmt.Sprintf("%s (slot %d)", fc.name, fc.slot)
}

func (fc *FirmwareCard) Slot() byte {
	return fc.slot
}

func (fc *FirmwareCard) ROMDisabled() {
	// Firmware card doesn't have a $C(8-F)xx ROM
}

func (fc *FirmwareCard) handleAccess(address byte) {
	if address%2 == 1 {
		// Card off
		fc.cm.HandleROM(false, fc.slotbit)
	} else {
		// Card on
		fc.cm.HandleROM(true, fc.slotbit)
	}
}

func (fc *FirmwareCard) Read16(address byte) byte {
	fc.handleAccess(address)
	return fc.cm.EmptyRead()
}

func (fc *FirmwareCard) Write16(address byte, value byte) {
	fc.handleAccess(address)
}

func (fc *FirmwareCard) Read(address uint16) byte {
	if address < 0xD000 {
		panic(fmt.Sprintf("%s got read to $%04X (<$D000)", fc.String(), address))
	}
	return fc.rom[address-0xD000]
}

func (fc *FirmwareCard) Write(address uint16, value byte) {
	// Firmware is ROM: do nothing
}

func (fc *FirmwareCard) Read256(address byte) byte {
	return fc.cm.EmptyRead()
}

func (fc *FirmwareCard) Write256(address byte, value byte) {
	// Firmware is ROM: do nothing
}

func (fc *FirmwareCard) WantTicker() bool {
	return false
}

func (fc *FirmwareCard) Tick() {
	// do nothing
}
