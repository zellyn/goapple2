package videoscan

import (
	"fmt"
)

const FLASH_INCREMENT = 8 // 128/8=16 / 60 // 15/60 = 3.75 per second

// PlotData is the struct that holds plotting
// information. Essentially, it holds the (binary) waveform of the
// color pattern.
type PlotData struct {
	Row        byte   "The row (0-191)"
	Column     byte   "The column (0-39)"
	ColorBurst bool   "Whether the color signal is active"
	Data       uint16 "14 half color cycles of information"
	LastData   uint16 "The previous 14 half color cycles of information"
	RawData    byte   "The underlying raw byte"
}

type Plotter interface {
	Plot(PlotData)
	OncePerFrame()
}

// RAM memory interface
type RamReader interface {
	RamRead(uint16) byte
}

type Scanner struct {
	m       RamReader
	h       uint16
	v       uint16
	plotter Plotter
	rom     [2048]byte

	graphics bool // TEXT/GRAPHICS
	mix      bool // NOMIX/MIX
	hires    bool // LORES/HIRES
	page2    bool // PAGE1/PAGE2

	hbl         bool   // Horizontal blanking
	vbl         bool   // Vertical blanking
	lastFour    bool   // Are we in the last 4 lines of the screen?
	lastData    uint16 // The previous 14 half color cycles of information
	lastBit     uint16 // Last bit of previous 14-cycle color data
	lastChange  bool   // Was there a change plotted last byte?
	flasher     byte   // if high bit is set, invert flashing text
	graphicsBit uint16 // Bit 14 high if we're in graphics mode
}

func NewScanner(m RamReader, p Plotter, rom [2048]byte) *Scanner {
	s := &Scanner{
		m:       m,
		plotter: p,
		rom:     rom,
		h:       0x7f,
		v:       0x1ff,
	}
	s.inc()
	return s
}

func (s *Scanner) inc() {
	// Increment H0..H5,HPE'
	switch s.h {
	case 0:
		s.h = 0x40
	case 0x7f:
		s.h = 0
		// Increment VA-VC,V0-V5
		switch s.v {
		case 0x1ff:
			s.v = 250
			s.flasher += FLASH_INCREMENT
		default:
			s.v++
		}

		// VBL = V4 & V3
		s.vbl = (s.v>>6)&3 == 3

		// Last four lines of the screen?
		s.lastFour = ((s.v>>5)&5 == 5)
	default:
		s.h++
	}

	// HBL = H5' & (H3' + H4')
	s.hbl = ((s.h >> 3) & 7) <= 2
}

// The last-plotted color cycle information.
// Bits 0-13 are the color cycle waveform. Bit 14 is true if colorburst was on.
var last [192][40]uint16

func (s *Scanner) Scan1() {
	address := s.address()
	if address >= 0xC000 {
		fmt.Printf("\n\n\nWOAH! $%04X\n\n\n", address)
	}
	m := s.m.RamRead(address)
	row, column := s.row(), s.column()
	_, _, _ = m, row, column
	var data uint16
	switch {
	case !s.graphics || (s.mix && s.lastFour):
		data = s.textData(m, row)
	case s.hires:
		data = s.hiresData(m)
	default: // lores
		data = s.loresData(m, row, column)
	}
	s.lastBit = (data >> 13) & 1
	if !s.hbl && !s.vbl {
		change := last[row][column] != (data | s.graphicsBit)
		if change || s.lastChange {
			// if row <= 8 && column == 0 {
			// 	fmt.Printf("%d,%d: RawData=%02X, Data=%04X\n", row, column, m, data)
			// }
			s.plotter.Plot(PlotData{
				Row:        byte(row),
				Column:     byte(column),
				ColorBurst: s.graphics,
				Data:       data,
				LastData:   s.lastData,
				RawData:    m,
			})
			last[row][column] = data | s.graphicsBit
		}
		s.lastChange = change
		if column == 39 && row == 191 {
			s.plotter.OncePerFrame()
		}
	}
	s.lastData = data
	s.inc()
}

func (s *Scanner) column() int {
	return int(s.h) - 0x58 // 0x1011000
}

func (s *Scanner) row() int {
	return int(s.v) - 0x100
}

var SUMS = [32]uint16{
	104, 112, 120, 0, 8, 16, 24, 32,
	16, 24, 32, 40, 48, 56, 64, 72,
	56, 64, 72, 80, 88, 96, 104, 112,
	96, 104, 112, 120, 0, 8, 16, 24,
}

func (s *Scanner) address() uint16 {
	// Low three bits are just H0-H2
	addr := s.h & 7

	// Next four bits are H5,H4,H3 + offset = SUM-A6,SUM-A5,SUM-A4,SUM-A3
	// bias := uint16(0xD)    //  1  1  0  1
	// hsum := (s.h >> 3) & 7 //  0 H5 H4 H3
	// vsum := (s.v >> 6) & 3 // V4 V3 V4 V3
	// vsum = vsum | (vsum << 2)
	// suma36 := (bias + hsum + vsum) & 0xF

	addr |= SUMS[(s.h>>3)&7+(s.v>>3)&24]

	// Next three are V0,V1,V2
	addr |= (s.v << 4) & 0x380 // ((s.v >> 3 & 7) << 7)

	page := uint16(1)
	if s.page2 {
		page = 2
	}

	// HIRES TIME when HIRES,GRAPHICS,NOMIX or HIRES,GRAPHICS,MIX,!(V4&V2)
	hiresTime := s.hires && s.graphics
	if hiresTime && s.mix && s.lastFour {
		hiresTime = false
	}

	if hiresTime {
		// A10-A12 = VA-VC
		addr |= ((s.v & 7) << 10)
		// A13=PAGE1, A14=PAGE2
		addr |= page << 13
	} else {
		// A10=PAGE1, A11=PAGE2
		addr |= page << 10
		// A12 = HBL
		if s.hbl {
			addr |= (1 << 12)
		}
	}

	return addr
}

func (s *Scanner) SetGraphics(graphics bool) {
	s.graphics = graphics
	if graphics {
		s.graphicsBit = 1 << 14
	} else {
		s.graphicsBit = 0
	}
}

func (s *Scanner) SetMix(mix bool) {
	s.mix = mix
}

func (s *Scanner) SetHires(hires bool) {
	s.hires = hires
}

func (s *Scanner) SetPage(page int) {
	switch page {
	case 1:
		s.page2 = false
	case 2:
		s.page2 = true
	default:
		panic(fmt.Sprint("Page must be 1 or 2, got", page))
	}
}

func (s *Scanner) textData(m byte, row int) uint16 {
	line := s.rom[int(m)*8+((row+800)%8)]
	// Invert if flash
	if (m^0x80)&line&s.flasher > 127 {
		line ^= 0xff
	}
	line &= 0x7f // Mask out high bit
	// Now it's just like hires data
	return s.hiresData(line)
}

// Double each bit to go from pixel info to color info
var HIRES_DOUBLES = [128]uint16{
	0x0, 0x3, 0xC, 0xF, 0x30, 0x33, 0x3C, 0x3F,
	0xC0, 0xC3, 0xCC, 0xCF, 0xF0, 0xF3, 0xFC, 0xFF,
	0x300, 0x303, 0x30C, 0x30F, 0x330, 0x333, 0x33C, 0x33F,
	0x3C0, 0x3C3, 0x3CC, 0x3CF, 0x3F0, 0x3F3, 0x3FC, 0x3FF,
	0xC00, 0xC03, 0xC0C, 0xC0F, 0xC30, 0xC33, 0xC3C, 0xC3F,
	0xCC0, 0xCC3, 0xCCC, 0xCCF, 0xCF0, 0xCF3, 0xCFC, 0xCFF,
	0xF00, 0xF03, 0xF0C, 0xF0F, 0xF30, 0xF33, 0xF3C, 0xF3F,
	0xFC0, 0xFC3, 0xFCC, 0xFCF, 0xFF0, 0xFF3, 0xFFC, 0xFFF,
	0x3000, 0x3003, 0x300C, 0x300F, 0x3030, 0x3033, 0x303C, 0x303F,
	0x30C0, 0x30C3, 0x30CC, 0x30CF, 0x30F0, 0x30F3, 0x30FC, 0x30FF,
	0x3300, 0x3303, 0x330C, 0x330F, 0x3330, 0x3333, 0x333C, 0x333F,
	0x33C0, 0x33C3, 0x33CC, 0x33CF, 0x33F0, 0x33F3, 0x33FC, 0x33FF,
	0x3C00, 0x3C03, 0x3C0C, 0x3C0F, 0x3C30, 0x3C33, 0x3C3C, 0x3C3F,
	0x3CC0, 0x3CC3, 0x3CCC, 0x3CCF, 0x3CF0, 0x3CF3, 0x3CFC, 0x3CFF,
	0x3F00, 0x3F03, 0x3F0C, 0x3F0F, 0x3F30, 0x3F33, 0x3F3C, 0x3F3F,
	0x3FC0, 0x3FC3, 0x3FCC, 0x3FCF, 0x3FF0, 0x3FF3, 0x3FFC, 0x3FFF,
}

func (s *Scanner) hiresData(m byte) uint16 {
	if m < 128 {
		return HIRES_DOUBLES[m]
	}
	return ((HIRES_DOUBLES[m&0x7f] << 1) & 0x3fff) | s.lastBit
}

func (s *Scanner) loresData(m byte, row int, column int) uint16 {
	var data uint16
	// First four rows get low nybble, second four high
	if row%8 < 4 {
		data = uint16(m & 0x0f)
	} else {
		data = uint16(m >> 4)
	}
	data = data * 0x1111 // Repeat lower nybble four times
	if column%2 == 1 {
		data >>= 2
	}
	return data & 0x3fff
}
