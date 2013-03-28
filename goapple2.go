package goapple2

import (
	"github.com/zellyn/go6502/cpu"
	"github.com/zellyn/goapple2/videoscan"
)

// Memory for the tests. Satisfies the cpu.Memory interface.
type Apple2 struct {
	mem     [65536]byte
	cpu     cpu.Cpu
	key     byte // BUG(zellyn): make reads/writes atomic
	keys    chan byte
	plotter videoscan.Plotter
	scanner *videoscan.Scanner
}

// Cycle counter. Satisfies the cpu.Ticker interface.
type CycleCount uint64

func (c *CycleCount) Tick() {
	*c += 1
}

func NewApple2(p videoscan.Plotter, rom []byte) *Apple2 {
	var cc CycleCount
	a2 := Apple2{
		keys: make(chan byte, 16),
	}
	copy(a2.mem[len(a2.mem)-len(rom):len(a2.mem)], rom)
	a2.scanner = videoscan.NewScanner(&a2, p, [2048]byte{})
	a2.cpu = cpu.NewCPU(&a2, &cc, cpu.VERSION_6502)
	a2.cpu.Reset()
	return &a2
}

func (a2 *Apple2) Read(address uint16) byte {
	// Keyboard read
	if address == 0xC000 {
		if a2.key&0x80 == 0 {
			select {
			case key := <-a2.keys:
				a2.key = key
			default:
			}
		}
		return a2.key
	}
	if address == 0xC010 {
		a2.key &= 0x7F
		return 0 // BUG(zellyn): return proper value (keydown on IIe, not sure on II+)
	}
	return a2.mem[address]
}

func (a2 *Apple2) Write(address uint16, value byte) {
	if address >= 0xD000 {
		return
	}
	if address == 0xC010 {
		// Clear keyboard strobe
		a2.key &= 0x7F
	}
	a2.mem[address] = value
}

func (a2 *Apple2) Keypress(key byte) {
	a2.keys <- key
}

func (a2 *Apple2) Step() error {
	if err := a2.cpu.Step(); err != nil {
		return err
	}
	a2.scanner.Scan1()
	return nil
}
