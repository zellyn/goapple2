package videoscan

import (
	"testing"
)

// recReader records the last address RamRead was called with, so we can compare
// the address the per-cycle scanner fetches against the closed-form address.
type recReader struct {
	mem      [65536]byte
	lastAddr uint16
}

func (r *recReader) RamRead(a uint16) byte {
	r.lastAddr = a
	return r.mem[a]
}

type nullPlot struct{}

func (nullPlot) Plot(PlotData) {}
func (nullPlot) OncePerFrame() {}

// TestBeamAddressClosedForm walks the scanner per-cycle exactly as the emulator
// does (Scan1 each Tick) and checks that scanAddress(beamPosition(k)) equals the
// address the k-th Scan1 actually fetched, for every k over multiple frames and
// every soft-switch configuration. This is the guarantee that the lazy
// floating-bus byte is bit-identical to the per-cycle one.
func TestBeamAddressClosedForm(t *testing.T) {
	configs := []struct {
		graphics, mix, hires, page2 bool
	}{
		{false, false, false, false}, // text page 1
		{false, false, false, true},  // text page 2
		{true, false, false, false},  // lores
		{true, false, true, false},   // hires page 1
		{true, false, true, true},    // hires page 2
		{true, true, true, false},    // hires mixed
		{true, true, false, false},   // lores mixed
	}
	// A couple of full frames plus change is plenty to exercise every h,v and
	// the frame wrap.
	const N = 3 * 262 * 65 // 3 frames
	for _, c := range configs {
		r := &recReader{}
		s := NewScanner(r, nullPlot{}, [2048]byte{})
		s.SetGraphics(c.graphics)
		s.SetMix(c.mix)
		s.SetHires(c.hires)
		if c.page2 {
			s.SetPage(2)
		} else {
			s.SetPage(1)
		}
		for k := 1; k <= N; k++ {
			s.Scan1() // fetches at state_k, records r.lastAddr, then inc()
			h, v := beamPosition(uint64(k))
			want := r.lastAddr
			got := scanAddress(h, v, c.graphics, c.mix, c.hires, c.page2)
			if got != want {
				t.Fatalf("config %+v cycle %d: closed-form addr $%04X != per-cycle addr $%04X (beam h=$%02X v=$%03X)",
					c, k, got, want, h, v)
			}
		}
	}
}

// TestFloatingBusByte checks the FloatingBusByte helper end-to-end: fill RAM
// with a marker pattern, then confirm the byte it returns for cycle k equals the
// byte the per-cycle scanner latched at Tick k.
func TestFloatingBusByte(t *testing.T) {
	r := &recReader{}
	for i := range r.mem {
		r.mem[i] = byte(i*7 + 3)
	}
	s := NewScanner(r, nullPlot{}, [2048]byte{})
	s.SetGraphics(true)
	s.SetHires(true)
	const N = 262 * 65 * 2
	for k := 1; k <= N; k++ {
		s.Scan1()
		wantByte := r.mem[r.lastAddr]
		// FloatingBusByte reads through the same reader; snapshot lastAddr first.
		gotByte := s.FloatingBusByte(uint64(k))
		if gotByte != wantByte {
			t.Fatalf("cycle %d: FloatingBusByte=$%02X, per-cycle latched=$%02X", k, gotByte, wantByte)
		}
	}
}
