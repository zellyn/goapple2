// Simplest possible Apple II that will possibly boot. ~ (tilde) to quit.
package main

import (
	"fmt"
	"io/ioutil"
	"time"

	"github.com/nsf/termbox-go"
	"github.com/zellyn/go6502/asm"
	"github.com/zellyn/go6502/cpu"
)

// Memory for the tests. Satisfies the cpu.Memory interface.
type Apple2 struct {
	mem    [65536]byte
	events chan termbox.Event
	done   bool
	key    byte // BUG(zellyn): make reads/writes atomic
	keys   chan byte
	debug  bool // Set true and close termbox to start tracing out instructions
}

// Mapping of screen bytes to character values
var AppleChars = "@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_ !\"#$%&'()*+,-./0123456789:;<=>?"

// Translate to termbox
func translateToTermbox(value byte) (char rune, fg, bg termbox.Attribute) {
	// BUG(zellyn): change this to return char, MODE_ENUM.
	ch := rune(AppleChars[value&0x3F])
	if value&0x80 > 0 {
		return ch, termbox.ColorGreen, termbox.ColorBlack
	}
	return ch, termbox.ColorGreen, termbox.ColorBlack + termbox.AttrReverse
}

func termboxToAppleKeyboard(ev termbox.Event) (key byte, err error) {
	if ev.Key > 0 && ev.Key <= 32 {
		return byte(ev.Key), nil
	}
	if ev.Ch >= '!' && ev.Ch <= 'Z' || ev.Ch == '^' {
		return byte(ev.Ch), nil
	}
	if ev.Ch >= 'a' && ev.Ch <= 'z' {
		return byte(ev.Ch - 'a' + 'A'), nil
	}
	switch ev.Key {
	case termbox.KeyBackspace2:
		return 8, nil // backspace
	case termbox.KeyArrowLeft:
		return 8, nil // left arrow
	case termbox.KeyArrowRight:
		return 21, nil // right arrow
	}
	return 0, fmt.Errorf("hi")
}

func (a2 *Apple2) Read(address uint16) byte {
	// Keyboard read
	if address == 0xC000 {
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
		termbox.Close()
		panic(fmt.Sprintln("Write to ROM at address $%04X", address))
	}
	if address == 0xC010 {
		// Clear keyboard strobe
		a2.key &= 0x7F
	}
	a2.mem[address] = value
	if !a2.debug && address >= 0x0400 && address < 0x0800 {
		offset := int(address - 0x0400)
		count := offset & 0x7f
		if count <= 119 {
			x := count % 40
			segment := offset / 128
			which40 := count / 40
			y := which40*8 + segment
			ch, fg, bg := translateToTermbox(value)
			termbox.SetCell(x+1, y+1, ch, fg, bg)
			termbox.Flush()
		}
	}
}

func (a2 *Apple2) Init() error {
	if err := termbox.Init(); err != nil {
		return err
	}
	a2.events = make(chan termbox.Event)
	a2.keys = make(chan byte, 16)
	go func() {
		for {
			a2.events <- termbox.PollEvent()
		}
	}()
	return nil
}
func (a2 *Apple2) Close() {
	termbox.Close()
}

func (a2 *Apple2) ProcessEvents() {
	select {
	case ev := <-a2.events:
		if ev.Type == termbox.EventKey && ev.Ch == '~' {
			a2.done = true
		}
		if ev.Type == termbox.EventKey {
			if key, err := termboxToAppleKeyboard(ev); err == nil {
				a2.keys <- key | 0x80
			}
		}
	default:
	}

	if a2.key&0x80 == 0 {
		select {
		case key := <-a2.keys:
			a2.key = key
		default:
		}
	}
}

// Cycle counter for the tests. Satisfies the cpu.Ticker interface.
type CycleCount uint64

func (c *CycleCount) Tick() {
	*c += 1
}

// printStatus prints out the current CPU instruction and register status.
func printStatus(c cpu.Cpu, m *[65536]byte) {
	bytes, text, _ := asm.Disasm(c.PC(), m[c.PC()], m[c.PC()+1], m[c.PC()+2])
	fmt.Printf("$%04X: %s  %s  A=$%02X X=$%02X Y=$%02X SP=$%02X P=$%08b\n",
		c.PC(), bytes, text, c.A(), c.X(), c.Y(), c.SP(), c.P())
}

// Run the emulator
func RunEmulator() {
	bytes, err := ioutil.ReadFile("../data/roms/apple2+.rom")
	if err != nil {
		panic("Cannot read ROM file")
	}
	var a2 Apple2
	ROM_OFFSET := 0xD000
	copy(a2.mem[ROM_OFFSET:ROM_OFFSET+len(bytes)], bytes)
	a2.Init()
	var cc CycleCount
	c := cpu.NewCPU(&a2, &cc, cpu.VERSION_6502)
	c.Reset()
	for !a2.done {
		// // LIST
		// if c.PC() == 0xD6A5 {
		// 	termbox.Close()
		// 	a2.debug = true
		// }
		// // End of LIST
		// if c.PC() == 0xD729 {
		// 	break
		// }
		if !a2.debug {
			a2.ProcessEvents()
		}
		if a2.debug {
			printStatus(c, &a2.mem)
		}
		err := c.Step()
		if err != nil {
			fmt.Println(err)
			break
		}
		time.Sleep(1 * time.Nanosecond) // So the keyboard-reading goroutines can run
	}
	if !a2.debug {
		a2.Close()
	}
}

func main() {
	RunEmulator()
}
