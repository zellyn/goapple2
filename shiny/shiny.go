// Simplest possible Apple II that will possibly boot, in exp/shiny. ~ (tilde) to quit.
package main

import (
	"flag"
	"fmt"
	"image"
	"image/color"
	"log"
	"os"
	"runtime"
	"runtime/pprof"

	"golang.org/x/exp/shiny/driver"
	"golang.org/x/exp/shiny/screen"

	"github.com/zellyn/go6502/cpu"
	"github.com/zellyn/goapple2"
	"github.com/zellyn/goapple2/cards"
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
	w, err := s.NewWindow(&screen.NewWindowOptions{Width: SCREEN_WIDTH, Height: SCREEN_HEIGHT})
	if err != nil {
		log.Fatal(err)
	}
	defer w.Release()

	winSize := image.Point{SCREEN_WIDTH, SCREEN_HEIGHT}
	b, err := s.NewBuffer(winSize)
	if err != nil {
		log.Fatal(err)
	}
	defer b.Release()

	rom := util.ReadRomOrDie("../data/roms/apple2+.rom")
	// charRom = util.ReadFullCharacterRomOrDie("../data/roms/apple2char.rom")
	charRom := util.ReadSmallCharacterRomOrDie("../data/roms/apple2-chars.rom")
	var a2 *goapple2.Apple2
	oncePerFrame := func() {
		a2.Done = a2.Done || ProcessEvents(a2)
		runtime.Gosched()
	}
	plotter := ShinyPlotter{w, b, oncePerFrame}
	a2 = goapple2.NewApple2(plotter, rom, charRom)

	intBasicRom := util.ReadRomOrDie("../data/roms/apple2.rom")
	firmwareCard, err := cards.NewFirmwareCard(intBasicRom, "Intbasic Firmware Card", 0, a2)
	if err != nil {
		panic(err)
	}
	if err := a2.AddCard(firmwareCard); err != nil {
		log.Fatal(err)
	}

	diskCardRom := util.ReadRomOrDie("../data/roms/Apple Disk II 16 Sector Interface Card ROM P5 - 341-0027.bin")
	diskCard, err := cards.NewDiskCard(diskCardRom, 6, a2)
	if err != nil {
		panic(err)
	}
	if err := a2.AddCard(diskCard); err != nil {
		log.Fatal(err)
	}
	// disk1, err := disk.DiskFromFile("../data/disks/spedtest.dsk", 0)
	// disk1, err := disk.DiskFromFile("../data/disks/dung_beetles.dsk", 0)
	/*
		disk1, err := disk.DiskFromFile("../data/disks/chivalry.dsk", 0)
		if err != nil {
			log.Fatal(err)
		}
		diskCard.LoadDisk(disk1, 0)
	*/

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

		a2.AddPCAction(0xBDAF, goapple2.PCAction{Type: goapple2.ActionTrace, String: "on",
			Delay: 70})

		a2.AddPCAction(
			0xBE48, goapple2.PCAction{Type: goapple2.ActionSetLimit, String: "1"})

		a2.AddPCAction(
			0xBDAF, goapple2.PCAction{Type: goapple2.ActionDumpMem, String: "0xBDAF-goa2.bin", Delay: 68})
	*/
	_ = cpu.FLAG_Z

	// go typeProgram(a2)

	for !a2.Done {
		err := a2.Step()
		if err != nil {
			fmt.Println(err)
			break
		}
		// runtime.Gosched() // So the keyboard-reading goroutines can run
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
	rgba.SetRGBA(x+BORDER_W, y+BORDER_H, c)

	/*
		x = x + BORDER_W
		y = y + BORDER_H
		pixels := uintptr(screen.Pixels)
		offset := uintptr(y*uint(screen.Pitch) + x*(SCREEN_BPP/8))
		addr := pixels + offset
		*(*uint32)(unsafe.Pointer(addr)) = color
	*/
}

/*
const (
	M_NONE = iota
	M_SHIFT_OR_NONE
	M_SHIFT
	M_CTRL
	M_ANY
)

type Key struct {
	sym uint32
	mod uint32
}

var KeyToApple = map[Key]byte{
	Key{sdl.K_a, M_SHIFT_OR_NONE}: 'A',
	Key{sdl.K_b, M_SHIFT_OR_NONE}: 'B',
	Key{sdl.K_c, M_SHIFT_OR_NONE}: 'C',
	Key{sdl.K_d, M_SHIFT_OR_NONE}: 'D',
	Key{sdl.K_e, M_SHIFT_OR_NONE}: 'E',
	Key{sdl.K_f, M_SHIFT_OR_NONE}: 'F',
	Key{sdl.K_g, M_SHIFT_OR_NONE}: 'G',
	Key{sdl.K_h, M_SHIFT_OR_NONE}: 'H',
	Key{sdl.K_i, M_SHIFT_OR_NONE}: 'I',
	Key{sdl.K_j, M_SHIFT_OR_NONE}: 'J',
	Key{sdl.K_k, M_SHIFT_OR_NONE}: 'K',
	Key{sdl.K_l, M_SHIFT_OR_NONE}: 'L',
	Key{sdl.K_m, M_SHIFT_OR_NONE}: 'M',
	Key{sdl.K_n, M_SHIFT_OR_NONE}: 'N',
	Key{sdl.K_o, M_SHIFT_OR_NONE}: 'O',
	Key{sdl.K_p, M_SHIFT_OR_NONE}: 'P',
	Key{sdl.K_q, M_SHIFT_OR_NONE}: 'Q',
	Key{sdl.K_r, M_SHIFT_OR_NONE}: 'R',
	Key{sdl.K_s, M_SHIFT_OR_NONE}: 'S',
	Key{sdl.K_t, M_SHIFT_OR_NONE}: 'T',
	Key{sdl.K_u, M_SHIFT_OR_NONE}: 'U',
	Key{sdl.K_v, M_SHIFT_OR_NONE}: 'V',
	Key{sdl.K_w, M_SHIFT_OR_NONE}: 'W',
	Key{sdl.K_x, M_SHIFT_OR_NONE}: 'X',
	Key{sdl.K_y, M_SHIFT_OR_NONE}: 'Y',
	Key{sdl.K_z, M_SHIFT_OR_NONE}: 'Z',

	Key{sdl.K_a, M_CTRL}: 1,
	Key{sdl.K_b, M_CTRL}: 2,
	Key{sdl.K_c, M_CTRL}: 3,
	Key{sdl.K_d, M_CTRL}: 4,
	Key{sdl.K_e, M_CTRL}: 5,
	Key{sdl.K_f, M_CTRL}: 6,
	Key{sdl.K_g, M_CTRL}: 7,
	Key{sdl.K_h, M_CTRL}: 8,
	Key{sdl.K_i, M_CTRL}: 9,
	Key{sdl.K_j, M_CTRL}: 10,
	Key{sdl.K_k, M_CTRL}: 11,
	Key{sdl.K_l, M_CTRL}: 12,
	Key{sdl.K_m, M_CTRL}: 13,
	Key{sdl.K_n, M_CTRL}: 14,
	Key{sdl.K_o, M_CTRL}: 15,
	Key{sdl.K_p, M_CTRL}: 16,
	Key{sdl.K_q, M_CTRL}: 17,
	Key{sdl.K_r, M_CTRL}: 18,
	Key{sdl.K_s, M_CTRL}: 19,
	Key{sdl.K_t, M_CTRL}: 20,
	Key{sdl.K_u, M_CTRL}: 21,
	Key{sdl.K_v, M_CTRL}: 22,
	Key{sdl.K_w, M_CTRL}: 23,
	Key{sdl.K_x, M_CTRL}: 24,
	Key{sdl.K_y, M_CTRL}: 25,
	Key{sdl.K_z, M_CTRL}: 26,

	Key{sdl.K_0, M_NONE}: '0',
	Key{sdl.K_1, M_NONE}: '1',
	Key{sdl.K_2, M_NONE}: '2',
	Key{sdl.K_3, M_NONE}: '3',
	Key{sdl.K_4, M_NONE}: '4',
	Key{sdl.K_5, M_NONE}: '5',
	Key{sdl.K_6, M_NONE}: '6',
	Key{sdl.K_7, M_NONE}: '7',
	Key{sdl.K_8, M_NONE}: '8',
	Key{sdl.K_9, M_NONE}: '9',

	Key{sdl.K_1, M_SHIFT}: '!',
	Key{sdl.K_2, M_SHIFT}: '@',
	Key{sdl.K_3, M_SHIFT}: '#',
	Key{sdl.K_4, M_SHIFT}: '$',
	Key{sdl.K_5, M_SHIFT}: '%',
	Key{sdl.K_6, M_SHIFT}: '^',
	Key{sdl.K_7, M_SHIFT}: '&',
	Key{sdl.K_8, M_SHIFT}: '*',
	Key{sdl.K_9, M_SHIFT}: '(',
	Key{sdl.K_0, M_SHIFT}: ')',

	Key{sdl.K_MINUS, M_NONE}:        '-',
	Key{sdl.K_MINUS, M_SHIFT}:       '_',
	Key{sdl.K_EQUALS, M_NONE}:       '=',
	Key{sdl.K_EQUALS, M_SHIFT}:      '+',
	Key{sdl.K_LEFTBRACKET, M_NONE}:  '[',
	Key{sdl.K_RIGHTBRACKET, M_NONE}: ']',
	Key{sdl.K_SEMICOLON, M_NONE}:    ';',
	Key{sdl.K_SEMICOLON, M_SHIFT}:   ':',
	Key{sdl.K_QUOTE, M_NONE}:        '\'',
	Key{sdl.K_QUOTE, M_SHIFT}:       '"',
	Key{sdl.K_COMMA, M_NONE}:        ',',
	Key{sdl.K_COMMA, M_SHIFT}:       '<',
	Key{sdl.K_PERIOD, M_NONE}:       '.',
	Key{sdl.K_PERIOD, M_SHIFT}:      '>',
	Key{sdl.K_SLASH, M_NONE}:        '/',
	Key{sdl.K_SLASH, M_SHIFT}:       '?',
	Key{sdl.K_BACKSLASH, M_NONE}:    '\\',

	Key{sdl.K_SPACE, M_SHIFT_OR_NONE}: ' ',
	Key{sdl.K_RETURN, M_ANY}:          13,

	Key{sdl.K_BACKSPACE, M_ANY}: 8,
	Key{sdl.K_LEFT, M_ANY}:      8,
	Key{sdl.K_RIGHT, M_ANY}:     21,
}

func sdlToAppleKeyboard(k sdl.Keysym) (key byte, err error) {
	if b, ok := KeyToApple[Key{k.Sym, M_ANY}]; ok {
		return b, nil
	}
	switch k.Mod {
	case sdl.KMOD_NONE:
		if b, ok := KeyToApple[Key{k.Sym, M_NONE}]; ok {
			return b, nil
		}
		if b, ok := KeyToApple[Key{k.Sym, M_SHIFT_OR_NONE}]; ok {
			return b, nil
		}
	case sdl.KMOD_LSHIFT, sdl.KMOD_RSHIFT, sdl.KMOD_LSHIFT | sdl.KMOD_RSHIFT:
		if b, ok := KeyToApple[Key{k.Sym, M_SHIFT}]; ok {
			return b, nil
		}
		if b, ok := KeyToApple[Key{k.Sym, M_SHIFT_OR_NONE}]; ok {
			return b, nil
		}
	case sdl.KMOD_LCTRL, sdl.KMOD_RCTRL, sdl.KMOD_LCTRL | sdl.KMOD_RCTRL:
		if b, ok := KeyToApple[Key{k.Sym, M_CTRL}]; ok {
			return b, nil
		}
	}
	return 0, fmt.Errorf("hi")
}
*/

func ProcessEvents(a2 *goapple2.Apple2) (done bool) {
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
	return
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
