// Simplest possible Apple II that will possibly boot. ~ (tilde) to quit.
package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"os"
	"strings"

	"github.com/nsf/termbox-go"
	"github.com/zellyn/goapple2"
	"github.com/zellyn/goapple2/util"
	"github.com/zellyn/goapple2/videoscan"
)

// Mapping of screen bytes to character values
var AppleChars = "@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_ !\"#$%&'()*+,-./0123456789:;<=>?"

var ColorFG = termbox.ColorGreen
var ColorBG = termbox.ColorBlack

// Translate to termbox
func translateToTermbox(value byte) (char rune, fg, bg termbox.Attribute) {
	// BUG(zellyn): change this to return char, MODE_ENUM.
	ch := rune(AppleChars[value&0x3F])
	if value&0x80 > 0 {
		return ch, ColorFG, ColorBG
	}
	return ch, ColorBG, ColorFG
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
}
func (p TextPlotter) OncePerFrame() {
	termbox.Flush()
}

// Run the emulator. If file is not empty, load it at address 0x6000,
// add a PCAction to quit if address 0 is called, clear the screen,
// call 0x6000, call 0, and dump the screen contents (minus trailing
// whitespace).
func RunEmulator(file string, quit bool) error {
	var options []goapple2.Option
	if file != "" {
		ColorFG = termbox.ColorDefault
		ColorBG = termbox.ColorDefault
		bytes, err := ioutil.ReadFile(file)
		if err != nil {
			return err
		}
		options = append(options, goapple2.WithRAM(0x6000, bytes))
	}
	rom := util.ReadRomOrDie("../data/roms/apple2+.rom", 12288)
	charRom := util.ReadSmallCharacterRomOrDie("../data/roms/apple2-chars.rom")
	plotter := TextPlotter(0)
	a2 := goapple2.NewApple2(plotter, rom, charRom, options...)
	if err := termbox.Init(); err != nil {
		return err
	}
	events := make(chan termbox.Event)
	done := false

	if file != "" {
		a2.AddPCAction(0, goapple2.PCAction{
			Type:     goapple2.ActionCallback,
			Callback: func() { done = true },
		})
	}
	go func() {
		if file != "" {
			for _, ch := range "HOME:CALL 24576" {
				a2.Keypress(byte(ch))
			}
			if quit {
				for _, ch := range ":CALL 0" {
					a2.Keypress(byte(ch))
				}
			}
			a2.Keypress(13)
		}
		for {
			events <- termbox.PollEvent()
		}
	}()
	for !ProcessEvents(events, a2) && !done {
		err := a2.Step()
		if err != nil {
			fmt.Println(err)
			break
		}
	}
	termbox.Close()
	if file != "" {
		dumpscreen(a2)
	}
	return nil
}

func dumpscreen(a2 *goapple2.Apple2) {
	chars := []byte{}
	for third := 0x400; third <= 0x450; third += 0x28 {
		for base := third; base <= third+0x380; base += 0x80 {
			for x := 0; x < 40; x++ {
				ch := a2.RamRead(uint16(base + x))
				chars = append(chars, ch&0x7f)
			}
			chars = append(chars, '\n')
		}
	}
	screen := string(chars)
	screen = strings.TrimRight(screen, "\r\n\t ")
	fmt.Println(screen)
}

var binfile = flag.String("binfile", "", "binary file to load at $6000 and CALL")
var quit = flag.Bool("quit", false, "quit after running binary")

func main() {
	flag.Parse()
	if err := RunEmulator(*binfile, *quit); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
