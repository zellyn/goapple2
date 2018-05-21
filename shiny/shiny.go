// Simplest possible Apple II that will possibly boot, in exp/shiny. ~ (tilde) to quit.
package main

import (
	"flag"
	"fmt"
	"image"
	"image/color"
	"log"
	"os"
	"runtime/pprof"

	"golang.org/x/exp/shiny/driver"
	"golang.org/x/exp/shiny/screen"
	"golang.org/x/mobile/event/key"
	"golang.org/x/mobile/event/lifecycle"

	"github.com/zellyn/goapple2"
	"github.com/zellyn/goapple2/cards"
	"github.com/zellyn/goapple2/disk"
	"github.com/zellyn/goapple2/util"
	"github.com/zellyn/goapple2/videoscan"
)

var (
	cpuprofile = flag.String("cpuprofile", "", "write cpu profile to file")
	steplimit  = flag.Uint64("steplimit", 0, "limit on number of steps to take")
)

const (
	BORDER_H      = 20
	BORDER_W      = 20
	SCREEN_WIDTH  = 560 + 2*BORDER_W
	SCREEN_HEIGHT = 384 + 2*BORDER_H
	SCREEN_BPP    = 32
)

// Run the emulator
func RunEmulator(s screen.Screen) {
	rom := util.ReadRomOrDie("../data/roms/apple2+.rom", 12288)
	charRom := util.ReadSmallCharacterRomOrDie("../data/roms/apple2-chars.rom")
	// intBasicRom := util.ReadRomOrDie("../data/roms/apple2.rom", 12288)
	util.ReadRomOrDie("../data/roms/Apple Disk II 16 Sector Interface Card ROM P5 - 341-0027.bin", 256)

	eventChan := make(chan (interface{}))
	w, err := s.NewWindow(&screen.NewWindowOptions{Width: SCREEN_WIDTH * 2, Height: SCREEN_HEIGHT * 2})
	if err != nil {
		log.Fatal(err)
	}
	defer w.Release()

	winSize := image.Point{SCREEN_WIDTH * 2, SCREEN_HEIGHT * 2}
	b, err := s.NewBuffer(winSize)
	if err != nil {
		log.Fatal(err)
	}
	defer b.Release()

	var a2 *goapple2.Apple2
	oncePerFrame := func() {
		a2.Done = a2.Done || ProcessEvents(a2, w, eventChan)
	}
	plotter := ShinyPlotter{w, b, oncePerFrame}
	a2 = goapple2.NewApple2(plotter, rom, charRom)

	/*
		firmwareCard, err := cards.NewFirmwareCard(intBasicRom, "Intbasic Firmware Card", 0, a2)
		if err != nil {
			panic(err)
		}
		if err := a2.AddCard(firmwareCard); err != nil {
			log.Fatal(err)
		}
	*/

	languageCard, err := cards.NewLanguageCard(rom, "Language Card", 0, a2)
	if err != nil {
		panic(err)
	}
	if err := a2.AddCard(languageCard); err != nil {
		log.Fatal(err)
	}

	diskCardRom := util.ReadRomOrDie("../data/roms/Apple Disk II 16 Sector Interface Card ROM P5 - 341-0027.bin", 256)
	diskCard, err := cards.NewDiskCard(diskCardRom, 6, a2)
	if err != nil {
		panic(err)
	}
	if err := a2.AddCard(diskCard); err != nil {
		log.Fatal(err)
	}
	// disk1, err := disk.DiskFromFile("../data/disks/spedtest.dsk", 0)
	// disk1, err := disk.DiskFromFile("../data/disks/dung_beetles.dsk", 0)
	// disk1, err := disk.DiskFromFile("../data/disks/chivalry.dsk", 0)
	// disk1, err := disk.DiskFromFile("../data/disks/wavynavy.dsk", 0)
	disk1, err := disk.DiskFromFile("/Users/zellyn/Documents/a2-disks/disks/Rescue_Raiders_1.2.dsk", 0)
	// disk1, err := disk.DiskFromFile("/Users/zellyn/Development/go/src/github.com/zellyn/a2audit/floatbus/floatbus.dsk", 0)
	// disk1, err := disk.DiskFromFile("/Users/zellyn/Development/go/src/github.com/zellyn/a2audit/audit/audit.dsk", 0)
	// disk1, err := disk.DiskFromFile("/Users/zellyn/Development/go/src/github.com/zellyn/diskii/lib/supermon/testdata/chacha20.dsk", 0)
	if err != nil {
		log.Fatal(err)
	}
	diskCard.LoadDisk(disk1, 0)

	steps := *steplimit

	if *cpuprofile != "" {
		f, err := os.Create(*cpuprofile)
		if err != nil {
			log.Fatal(err)
		}
		pprof.StartCPUProfile(f)
		defer pprof.StopCPUProfile()
	}

	/*
			a2.AddPCAction(
				0xB940, goapple2.PCAction{Type: goapple2.ActionDumpMem, String: "0xB940-goa2.bin",
					Mask: cpu.FLAG_Z, Masked: cpu.FLAG_Z, Delay: 68})
		a2.AddPCAction(0xB7B5, goapple2.PCAction{Type: goapple2.ActionHere, String: "ENTER.RWTS"})
		a2.AddPCAction(0xB7BE, goapple2.PCAction{Type: goapple2.ActionHere, String: "ENTER.RWTS - Success"})
		a2.AddPCAction(0xB7C1, goapple2.PCAction{Type: goapple2.ActionHere, String: "ENTER.RWTS - Fail"})
		a2.AddPCAction(0xBD00, goapple2.PCAction{Type: goapple2.ActionHere, String: "RWTS"})
		a2.AddPCAction(0xBDAF, goapple2.PCAction{Type: goapple2.ActionHere, String: "RWTS Command"})
		// a2.AddPCAction(0xBE35, goapple2.PCAction{Type: goapple2.ActionHere, String: "RWTS READ.SECTOR call"})
		// a2.AddPCAction(0xBE38, goapple2.PCAction{Type: goapple2.ActionHere, String: "RWTS READ.SECTOR success"})

		a2.AddPCAction(0xBE46, goapple2.PCAction{Type: goapple2.ActionHere, String: "RWTS Success"})
		a2.AddPCAction(0xBE48, goapple2.PCAction{Type: goapple2.ActionHere, String: "RWTS Error"})

		a2.AddPCAction(0xBDAF, goapple2.PCAction{Type: goapple2.ActionDiskStatus})

		a2.AddPCAction(0x6000, goapple2.PCAction{Type: goapple2.ActionTrace, String: "on",
			Delay: 70})

		a2.AddPCAction(
			0xBE48, goapple2.PCAction{Type: goapple2.ActionSetLimit, String: "1"})

		a2.AddPCAction(
			0xBDAF, goapple2.PCAction{Type: goapple2.ActionDumpMem, String: "0xBDAF-goa2.bin", Delay: 68})
	*/

	// a2.AddPCAction(0x6000, goapple2.PCAction{Type: goapple2.ActionTrace, String: "on"})

	// go typeProgram(a2)

	go func() {
		for {
			eventChan <- w.NextEvent()
		}
	}()

	for !a2.Done {
		err := a2.Step()
		if err != nil {
			fmt.Println(err)
			break
		}
		if steps > 0 {
			steps--
			if steps == 0 {
				a2.Quit()
			}
		}
	}
	a2.Quit()
}

func plot(x, y int, c color.RGBA, b screen.Buffer) {
	rgba := b.RGBA()
	xx := (x + BORDER_W) * 2
	yy := (y + BORDER_H) * 2
	rgba.SetRGBA(xx, yy, c)
	rgba.SetRGBA(xx+1, yy, c)
	rgba.SetRGBA(xx, yy+1, c)
	rgba.SetRGBA(xx+1, yy+1, c)

	/*
		x = x + BORDER_W
		y = y + BORDER_H
		pixels := uintptr(screen.Pixels)
		offset := uintptr(y*uint(screen.Pitch) + x*(SCREEN_BPP/8))
		addr := pixels + offset
		*(*uint32)(unsafe.Pointer(addr)) = color
	*/
}

type Key struct {
	code key.Code
	mod  key.Modifiers
}

var KeyToApple = map[Key]byte{
	Key{key.CodeA, 0}: 'A',
	Key{key.CodeB, 0}: 'B',
	Key{key.CodeC, 0}: 'C',
	Key{key.CodeD, 0}: 'D',
	Key{key.CodeE, 0}: 'E',
	Key{key.CodeF, 0}: 'F',
	Key{key.CodeG, 0}: 'G',
	Key{key.CodeH, 0}: 'H',
	Key{key.CodeI, 0}: 'I',
	Key{key.CodeJ, 0}: 'J',
	Key{key.CodeK, 0}: 'K',
	Key{key.CodeL, 0}: 'L',
	Key{key.CodeM, 0}: 'M',
	Key{key.CodeN, 0}: 'N',
	Key{key.CodeO, 0}: 'O',
	Key{key.CodeP, 0}: 'P',
	Key{key.CodeQ, 0}: 'Q',
	Key{key.CodeR, 0}: 'R',
	Key{key.CodeS, 0}: 'S',
	Key{key.CodeT, 0}: 'T',
	Key{key.CodeU, 0}: 'U',
	Key{key.CodeV, 0}: 'V',
	Key{key.CodeW, 0}: 'W',
	Key{key.CodeX, 0}: 'X',
	Key{key.CodeY, 0}: 'Y',
	Key{key.CodeZ, 0}: 'Z',

	Key{key.CodeA, key.ModShift}: 'A',
	Key{key.CodeB, key.ModShift}: 'B',
	Key{key.CodeC, key.ModShift}: 'C',
	Key{key.CodeD, key.ModShift}: 'D',
	Key{key.CodeE, key.ModShift}: 'E',
	Key{key.CodeF, key.ModShift}: 'F',
	Key{key.CodeG, key.ModShift}: 'G',
	Key{key.CodeH, key.ModShift}: 'H',
	Key{key.CodeI, key.ModShift}: 'I',
	Key{key.CodeJ, key.ModShift}: 'J',
	Key{key.CodeK, key.ModShift}: 'K',
	Key{key.CodeL, key.ModShift}: 'L',
	Key{key.CodeM, key.ModShift}: 'M',
	Key{key.CodeN, key.ModShift}: 'N',
	Key{key.CodeO, key.ModShift}: 'O',
	Key{key.CodeP, key.ModShift}: 'P',
	Key{key.CodeQ, key.ModShift}: 'Q',
	Key{key.CodeR, key.ModShift}: 'R',
	Key{key.CodeS, key.ModShift}: 'S',
	Key{key.CodeT, key.ModShift}: 'T',
	Key{key.CodeU, key.ModShift}: 'U',
	Key{key.CodeV, key.ModShift}: 'V',
	Key{key.CodeW, key.ModShift}: 'W',
	Key{key.CodeX, key.ModShift}: 'X',
	Key{key.CodeY, key.ModShift}: 'Y',
	Key{key.CodeZ, key.ModShift}: 'Z',

	Key{key.CodeA, key.ModControl}: 1,
	Key{key.CodeB, key.ModControl}: 2,
	Key{key.CodeC, key.ModControl}: 3,
	Key{key.CodeD, key.ModControl}: 4,
	Key{key.CodeE, key.ModControl}: 5,
	Key{key.CodeF, key.ModControl}: 6,
	Key{key.CodeG, key.ModControl}: 7,
	Key{key.CodeH, key.ModControl}: 8,
	Key{key.CodeI, key.ModControl}: 9,
	Key{key.CodeJ, key.ModControl}: 10,
	Key{key.CodeK, key.ModControl}: 11,
	Key{key.CodeL, key.ModControl}: 12,
	Key{key.CodeM, key.ModControl}: 13,
	Key{key.CodeN, key.ModControl}: 14,
	Key{key.CodeO, key.ModControl}: 15,
	Key{key.CodeP, key.ModControl}: 16,
	Key{key.CodeQ, key.ModControl}: 17,
	Key{key.CodeR, key.ModControl}: 18,
	Key{key.CodeS, key.ModControl}: 19,
	Key{key.CodeT, key.ModControl}: 20,
	Key{key.CodeU, key.ModControl}: 21,
	Key{key.CodeV, key.ModControl}: 22,
	Key{key.CodeW, key.ModControl}: 23,
	Key{key.CodeX, key.ModControl}: 24,
	Key{key.CodeY, key.ModControl}: 25,
	Key{key.CodeZ, key.ModControl}: 26,

	Key{key.Code0, 0}: '0',
	Key{key.Code1, 0}: '1',
	Key{key.Code2, 0}: '2',
	Key{key.Code3, 0}: '3',
	Key{key.Code4, 0}: '4',
	Key{key.Code5, 0}: '5',
	Key{key.Code6, 0}: '6',
	Key{key.Code7, 0}: '7',
	Key{key.Code8, 0}: '8',
	Key{key.Code9, 0}: '9',

	Key{key.Code1, key.ModShift}: '!',
	Key{key.Code2, key.ModShift}: '@',
	Key{key.Code3, key.ModShift}: '#',
	Key{key.Code4, key.ModShift}: '$',
	Key{key.Code5, key.ModShift}: '%',
	Key{key.Code6, key.ModShift}: '^',
	Key{key.Code7, key.ModShift}: '&',
	Key{key.Code8, key.ModShift}: '*',
	Key{key.Code9, key.ModShift}: '(',
	Key{key.Code0, key.ModShift}: ')',

	Key{key.CodeHyphenMinus, 0}:            '-',
	Key{key.CodeHyphenMinus, key.ModShift}: '_',
	Key{key.CodeEqualSign, 0}:              '=',
	Key{key.CodeEqualSign, key.ModShift}:   '+',
	Key{key.CodeLeftSquareBracket, 0}:      '[',
	Key{key.CodeRightSquareBracket, 0}:     ']',
	Key{key.CodeSemicolon, 0}:              ';',
	Key{key.CodeSemicolon, key.ModShift}:   ':',
	Key{key.CodeApostrophe, 0}:             '\'',
	Key{key.CodeApostrophe, key.ModShift}:  '"',
	Key{key.CodeComma, 0}:                  ',',
	Key{key.CodeComma, key.ModShift}:       '<',
	Key{key.CodeFullStop, key.ModShift}:    '>',
	Key{key.CodeSlash, 0}:                  '/',
	Key{key.CodeSlash, key.ModShift}:       '?',
	Key{key.CodeBackslash, 0}:              '\\',

	Key{key.CodeSpacebar, 0}:    ' ',
	Key{key.CodeReturnEnter, 0}: 13,

	Key{key.CodeDeleteBackspace, 0}: 8,
	Key{key.CodeLeftArrow, 0}:       8,
	Key{key.CodeRightArrow, 0}:      21,
}

func shinyToAppleKeyboard(e key.Event) (byte, error) {
	if b, ok := KeyToApple[Key{e.Code, e.Modifiers}]; ok {
		return b, nil
	} else {
		fmt.Printf("Key for %v not found\n", e)
	}
	/*
		switch k.Mod {
		case sdl.KMOD_NONE:
			if b, ok := KeyToApple[Key{e.Code, 0}]; ok {
				return b, nil
			}
			if b, ok := KeyToApple[Key{e.Code, M_SHIFT_OR_NONE}]; ok {
				return b, nil
			}
		case sdl.KMOD_LSHIFT, sdl.KMOD_RSHIFT, sdl.KMOD_LSHIFT | sdl.KMOD_RSHIFT:
			if b, ok := KeyToApple[Key{e.Code, M_SHIFT}]; ok {
				return b, nil
			}
			if b, ok := KeyToApple[Key{e.Code, M_SHIFT_OR_NONE}]; ok {
				return b, nil
			}
		case sdl.KMOD_LCTRL, sdl.KMOD_RCTRL, sdl.KMOD_LCTRL | sdl.KMOD_RCTRL:
			if b, ok := KeyToApple[Key{e.Code, M_CTRL}]; ok {
				return b, nil
			}
		}
	*/
	return 0, fmt.Errorf("hi")
}

func ProcessEvents(a2 *goapple2.Apple2, w screen.Window, eventChan chan interface{}) (done bool) {
	select {
	case ev := <-eventChan:
		switch e := ev.(type) {
		case lifecycle.Event:
			if e.To == lifecycle.StageDead {
				return true
			}
		case key.Event:
			if e.Code == key.CodeGraveAccent {
				return true
			}
			if e.Direction == key.DirPress || e.Direction == key.DirNone {
				if b, err := shinyToAppleKeyboard(e); err == nil {
					a2.Keypress(b)
				} else {
					fmt.Printf("Unable to convert event %v (%d, %d): %v\n", e, int(e.Code), int(e.Modifiers), err)
				}
			}
		}
	default:
	}

	/*
		select {
		case _event := <-events:
			switch e := _event.(type) {
			case sdl.QuitEvent:
				return true
			case sdl.KeyboardEvent:
				if e.Type == sdl.KEYDOWN {
					if e.Keysym.Sym == sdl.K_F1 {
						return true
					}
					if e.Keysym.Mod == sdl.KMOD_LCTRL && e.Keysym.Sym == sdl.K_LEFTBRACKET {
						return true
					}
					if key, err := sdlToAppleKeyboard(e.Keysym); err == nil {
						a2.Keypress(key)
					}
				}
			}
		default:
			// Nothing to do here
		}
	*/
	return false
}

type ShinyPlotter struct {
	window       screen.Window
	buffer       screen.Buffer
	oncePerFrame func()
}

func (s ShinyPlotter) Plot(pd videoscan.PlotData) {
	y := int(pd.Row)
	x := int(pd.Column) * 14
	data := pd.Data
	for i := 0; i < 14; i++ {
		color1 := color.RGBA{0, 0, 0, 0xff}
		color2 := color.RGBA{0, 0, 0, 0xff}
		if data&1 > 0 {
			color1 = color.RGBA{0x00, 0xff, 0x00, 0xff}
			color2 = color.RGBA{0x00, 0x88, 0x00, 0xff}
		}
		plot(x+i, y*2+0, color1, s.buffer)
		plot(x+i, y*2+1, color2, s.buffer)
		data >>= 1
	}
}

func (s ShinyPlotter) OncePerFrame() {
	s.window.Upload(image.Point{0, 0}, s.buffer, s.buffer.Bounds())
	s.window.Publish()
	s.oncePerFrame()
}

func typeProgram(a2 *goapple2.Apple2) {
	lines := []string{
		"10 GR",
		"20 POKE -16302,0",
		"30 FOR Y=0 TO 47",
		"40 FOR X=0 TO 39",
		"50 COLOR=INT(RND(1)*16)",
		"60 PLOT X,Y",
		"70 NEXT",
		"80 NEXT",
		"RUN",
	}
	lines = []string{
		"10 HGR2",
		"20 FOR I = 0 to 7",
		"30 HCOLOR=7-I",
		"40 HPLOT I*10, 0 TO 191 + I*10, 191",
		"50 NEXT",
		"RUN",
	}
	for _, line := range lines {
		for _, ch := range line {
			a2.Keypress(byte(ch))
		}
		a2.Keypress(13)
	}
}

func main() {
	flag.Parse()
	driver.Main(RunEmulator)
}
