package disk

type Dummy byte

func (v Dummy) Read() byte {
	return 0x00
}

func (v Dummy) Skip(int) {
	// pass
}

func (v Dummy) Write(b byte) {
	// pass
}

func (v Dummy) SetHalfTrack(t byte) {
	// pass
}

func (v Dummy) HalfTrack() byte {
	return 0
}

func (v Dummy) Writeable() bool {
	return false
}

func NewDummy(v byte) Dummy {
	return Dummy(v)
}
