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
	done    bool
	tw      TickWaiter
}

// Cycle counter. Satisfies the cpu.Ticker interface.
type TickWaiter struct {
	Wait chan byte
}

func (t TickWaiter) Tick() {
	<-t.Wait
}

func NewTickWaiter() TickWaiter {
	return TickWaiter{Wait: make(chan byte)}
}

func NewApple2(p videoscan.Plotter, rom []byte, charRom [2048]byte) *Apple2 {
	tw := NewTickWaiter()
	a2 := Apple2{
		keys: make(chan byte, 16),
		tw:   tw,
	}
	copy(a2.mem[len(a2.mem)-len(rom):len(a2.mem)], rom)
	a2.scanner = videoscan.NewScanner(&a2, p, charRom)
	a2.cpu = cpu.NewCPU(&a2, tw, cpu.VERSION_6502)
	a2.cpu.Reset()
	go func() {
		tw.Tick()
		for !a2.done {
			a2.cpu.Step()
		}
	}()
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
	a2.keys <- key | 0x80
}

func (a2 *Apple2) Step() error {
	a2.tw.Wait <- 0
	a2.scanner.Scan1()
	return nil
}

func (a2 *Apple2) Quit() {
	a2.done = true
}
