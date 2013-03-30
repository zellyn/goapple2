// Simplest possible Apple II that will possibly boot. ~ (tilde) to quit.
package main

import (
	"fmt"
	"time"

	"github.com/nsf/termbox-go"
	"github.com/zellyn/goapple2"
	"github.com/zellyn/goapple2/util"
	"github.com/zellyn/goapple2/videoscan"
)

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

func ProcessEvents(events chan termbox.Event, a2 *goapple2.Apple2) bool {
	select {
	case ev := <-events:
		if ev.Type == termbox.EventKey && ev.Ch == '~' {
			return true
		}
		if ev.Type == termbox.EventKey {
			if key, err := termboxToAppleKeyboard(ev); err == nil {
				a2.Keypress(key)
			}
		}
	default:
	}

	return false
}

type TextPlotter int

func (p TextPlotter) Plot(data videoscan.PlotData) {
	y := int(data.Row / 8)
	x := int(data.Column)
	value := data.RawData
	ch, fg, bg := translateToTermbox(value)
	termbox.SetCell(x+1, y+1, ch, fg, bg)
	if x == 39 && data.Row == 191 {
		termbox.Flush()
	}
}

// Run the emulator
func RunEmulator() {
	rom := util.ReadRomOrDie("../data/roms/apple2+.rom")
	plotter := TextPlotter(0)
	var charRom [2048]byte
	a2 := goapple2.NewApple2(plotter, rom, charRom)
	if err := termbox.Init(); err != nil {
		panic(err)
	}
	events := make(chan termbox.Event)
	go func() {
		for {
			events <- termbox.PollEvent()
		}
	}()
	for !ProcessEvents(events, a2) {
		err := a2.Step()
		if err != nil {
			fmt.Println(err)
			break
		}
		time.Sleep(1 * time.Nanosecond) // So the keyboard-reading goroutines can run
	}
	termbox.Close()
}

func main() {
	RunEmulator()
}
