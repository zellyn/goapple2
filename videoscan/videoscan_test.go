package videoscan

import (
	"testing"

	"github.com/zellyn/go6502/tests"
	apple2 "github.com/zellyn/goapple2"
)

type fakePlotter struct {
}

func (f *fakePlotter) Plot(apple2.PlotData) {
}

func TestHorizontal(t *testing.T) {
	var m tests.Memorizer
	var f fakePlotter
	s := NewScanner(&m, &f, [2048]byte{})

	// 1000 Increments
	for i := 0; i < 1000; i++ {
		for j := 0; j < 25; j++ {
			if s.column() >= 0 {
				t.Errorf("Expected s.column() < 0, got %v", s.column())
			}
			s.Scan1()
		}
		for j := 0; j < 40; j++ {
			if s.column() != j {
				t.Errorf("Expected s.column()==%d, got %v", j, s.column())
			}
			s.Scan1()
		}
	}
}

func TestVertical(t *testing.T) {
	var m tests.Memorizer
	var f fakePlotter
	s := NewScanner(&m, &f, [2048]byte{})
	scan65 := func() {
		for i := 0; i < 65; i++ {
			s.Scan1()
		}
	}

	// 1000 * 65 (per row) Increments
	for i := 0; i < 1000; i++ {
		for j := 0; j < 6; j++ {
			if s.row() > 0 {
				t.Errorf("Expected s.row() <= 0, got %v", s.row())
			}
			scan65()
		}
		for j := 0; j < 256; j++ {
			if s.row() != j {
				t.Errorf("Expected s.row() == %d, got %v", j, s.row())
			}
			scan65()
		}
	}
}

func TestBlanking(t *testing.T) {
	var m tests.Memorizer
	var f fakePlotter
	s := NewScanner(&m, &f, [2048]byte{})

	for i := 0; i < 1000000; i++ {
		if s.column() < 0 || s.column() >= 40 {
			if !s.hbl {
				t.Errorf("s.column()==%d, but s.hbl=%v", s.column(), s.hbl)
			}
		} else {
			if s.hbl {
				t.Errorf("s.column()==%d, but s.hbl=%v", s.column(), s.hbl)
			}
		}

		if s.row() < 0 || s.row() >= 192 {
			if !s.vbl {
				t.Errorf("s.row()==%d, but s.vbl=%v", s.row(), s.vbl)
			}
		} else {
			if s.vbl {
				t.Errorf("s.row()==%d, but s.vbl=%v", s.row(), s.vbl)
			}
		}
		s.Scan1()
	}
}

func TestSpecificLocationAddresses(t *testing.T) {
	var m tests.Memorizer
	var f fakePlotter
	s := NewScanner(&m, &f, [2048]byte{})

	// TEXT/LORES Page 1
	text_lores_page1 := map[int]uint16{
		0:  0x400,
		5:  0x680,
		8:  0x428,
		16: 0x450,
		14: 0x728,
		19: 0x5D0,
		20: 0x650,
		21: 0x6D0,
		22: 0x750,
		23: 0x7D0,
	}

	// HIRES Page 1
	hires := map[int]uint16{
		0:   0x2000,
		8:   0x2080,
		64:  0x2028,
		99:  0x2E28,
		127: 0x3FA8,
		128: 0x2050,
		100: 0x3228,
		159: 0x3DD0,
		160: 0x2250,
		170: 0x2AD0,
		183: 0x3F50,
		191: 0x3FD0,
	}

	s.SetMix(false)
	s.SetGraphics(false)
	s.SetHires(false)
	for i := 0; i < 1000000; i++ {
		s.Scan1()
		row := s.row()
		if addr, ok := text_lores_page1[row/8]; ok {
			col := s.column()
			if row >= 0 && col >= 0 && col < 40 {
				addrplus := addr + uint16(col)
				s.SetPage(1)
				s.SetGraphics(false)
				if addrplus != s.address() {
					t.Fatalf("Row %d (%d), col %d, expected $%04X+$%02X=$%04X, got $%04X",
						row, row/8, col, addr, col, addrplus, s.address())
				}
				s.SetGraphics(true)
				if addrplus != s.address() {
					t.Fatalf("Row %d (%d), col %d, expected $%04X+$%02X=$%04X, got $%04X",
						row, row/8, col, addr, col, addrplus, s.address())
				}
				s.SetMix(true)
				if addrplus != s.address() {
					t.Fatalf("Row %d (%d), col %d, expected $%04X+$%02X=$%04X, got $%04X",
						row, row/8, col, addr, col, addrplus, s.address())
				}
				addr += 0x400
				addrplus += 0x400
				s.SetPage(2)
				if addrplus != s.address() {
					t.Fatalf("Row %d (%d), col %d, expected $%04X+$%02X=$%04X, got $%04X",
						row, row/8, col, addr, col, addrplus, s.address())
				}
			}
		}
	}

	s.SetMix(false)
	s.SetGraphics(true)
	s.SetHires(true)
	for i := 0; i < 1000000; i++ {
		s.Scan1()
		row := s.row()
		if addr, ok := hires[row]; ok {
			col := s.column()
			if col >= 0 && col < 40 {
				addrplus := addr + uint16(col)
				s.SetPage(1)
				if addrplus != s.address() {
					t.Fatalf("Row %d, col %d, expected $%04X+$%02X=$%04X, got $%04X",
						row, col, addr, col, addrplus, s.address())
				}
				s.SetPage(2)
				addr += 0x2000
				addrplus += 0x2000
				if addrplus != s.address() {
					t.Fatalf("Row %d, col %d, expected $%04X+$%02X=$%04X, got $%04X",
						row, col, addr, col, addrplus, s.address())
				}
			}
		}
	}

	// Mixed hires/text
	s.SetPage(1)
	s.SetMix(true)
	s.SetGraphics(true)
	s.SetHires(true)
	for i := 0; i < 1000000; i++ {
		s.Scan1()
		row := s.row()
		if row >= 160 {
			if addr, ok := text_lores_page1[row/8]; ok {
				col := s.column()
				if row >= 0 && col >= 0 && col < 40 {
					addrplus := addr + uint16(col)
					if addrplus != s.address() {
						t.Fatalf("Row %d (%d), col %d, expected $%04X+$%02X=$%04X, got $%04X",
							row, row/8, col, addr, col, addrplus, s.address())
					}
				}
			}
		} else {
			if addr, ok := hires[row]; ok {
				col := s.column()
				if col >= 0 && col < 40 {
					addrplus := addr + uint16(col)
					if addrplus != s.address() {
						t.Fatalf("Row %d, col %d, expected $%04X+$%02X=$%04X, got $%04X",
							row, col, addr, col, addrplus, s.address())
					}
				}
			}
		}
	}
}
