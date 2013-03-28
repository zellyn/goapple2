package videoscan

import (
	"fmt"

	"github.com/zellyn/go6502/cpu"
)

const FLASH_CYCLES = 15 // 15/60 = four per second

// PlotData is the struct that holds plotting
// information. Essentially, it holds the (binary) waveform of the
// color pattern.
type PlotData struct {
	Row        byte   "The row (0-191)"
	Column     byte   "The column (0-39)"
	ColorBurst bool   "Whether the color signal is active"
	Data       uint16 "14 half color cycles of information"
	RawData    byte   "The underlying raw byte"
}

type Plotter interface {
	Plot(PlotData)
}

type Scanner struct {
	m       cpu.Memory
	h       uint16
	v       uint16
	plotter Plotter
	rom     [2048]byte

	graphics bool // TEXT/GRAPHICS
	mix      bool // NOMIX/MIX
	hires    bool // LORES/HIRES
	page2    bool // PAGE1/PAGE2

	hbl        bool   // Horizontal blanking
	vbl        bool   // Vertical blanking
	lastFour   bool   // Are we in the last 4 lines of the screen?
	lastBit    uint16 // Last bit of previous 14-cycle color data
	flasher    byte   // if high bit is set, invert flashing text
	flashCount int    // count up, and toggle flasher
}

func NewScanner(m cpu.Memory, p Plotter, rom [2048]byte) *Scanner {
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
			if s.flashCount++; s.flashCount >= FLASH_CYCLES {
				s.flashCount = 0
				s.flasher ^= 0x80
			}
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

func (s *Scanner) Scan1() {
	m := s.m.Read(s.address())
	row, column := s.row(), s.column()
	_, _, _ = m, row, column
	var data uint16
	color := s.graphics
	switch {
	case !s.graphics || (s.mix && s.lastFour):
		data = s.textData(m, row, column)
	case s.hires:
		data = s.hiresData(m, row, column)
	default: // lores
		data = s.loresData(m, row, column)
	}
	s.lastBit = (data >> 13) & 1
	if !s.hbl && !s.vbl {
		s.plotter.Plot(PlotData{
			Row:        byte(row),
			Column:     byte(column),
			ColorBurst: color,
			Data:       data,
			RawData:    m,
		})
	}
	s.inc()
}

func (s *Scanner) column() int {
	return int(s.h) - 0x58 // 0x1011000
}

func (s *Scanner) row() int {
	return int(s.v) - 0x100
}

func (s *Scanner) address() uint16 {
	// Low three bits are just H0-H2
	addr := s.h & 7

	// Next four bits are H5,H4,H3 + offset = SUM-A6,SUM-A5,SUM-A4,SUM-A3
	bias := uint16(0xD)    //  1  1  0  1
	hsum := (s.h >> 3) & 7 //  0 H5 H4 H3
	vsum := (s.v >> 6) & 3 // V4 V3 V4 V3
	vsum = vsum | (vsum << 2)
	suma36 := (bias + hsum + vsum) & 0xF
	addr |= (suma36 << 3)

	// Next three are V0,V1,V2
	addr |= ((s.v >> 3 & 7) << 7)

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

func (s *Scanner) textData(m byte, row int, column int) uint16 {
	line := s.rom[int(m)*8+((row+800)%8)]
	// Invert if flash
	if (m^0x80)&line&s.flasher > 0 {
		line ^= 0xff
	}
	line &= 0x7f // Mask out high bit
	// Now it's just like hires data
	return s.hiresData(line, row, column)
}

func (s *Scanner) hiresData(m byte, row int, column int) uint16 {
	// Double each bit
	var data uint16
	mm := uint16(m)
	// BUG(zellyn): Use bitmagic to do this without looping
	for i := byte(6); i != 0xff; i-- {
		data |= ((mm >> i) & 1) * 3
		data <<= 2
	}
	// High bit set delays the signal by 1/4 color cycle = 1 bit,
	// and extends the last bit to fill in the delay.
	if m > 127 {
		data <<= 1
		data |= s.lastBit
	}
	return data & 0x3fff
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
