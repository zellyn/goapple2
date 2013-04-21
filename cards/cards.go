package cards

type Card interface {
	String() string                    // The name of the card, for debug/display purposes
	Read16(address byte) byte          // Read from the $C0(8+slot)X addresses
	Write16(address byte, value byte)  // Write to the $C0(8+slot)X addresses
	Slot() byte                        // Get the card's slot 0-7
	ROMDisabled()                      // Tell the card that its handling of $C(8-F)xx was disabled
	Read256(address byte) byte         // Read from the $C(slot)XX addresses
	Write256(address byte, value byte) // Write to the $C(slot)XX addresses
	Read(address uint16) byte          // Read from any address ($C800-$FFFF)
	Write(address uint16, value byte)  // Write to any address ($C800-$FFFF)
	WantTicker() bool
	Tick()
}

type CardManager interface {
	HandleROM(onOff bool, slot byte)
	Handle12k(onOff bool, slot byte)
	EmptyRead() byte
}
