package disk

import (
	"math/rand"
	"testing"
)

func TestPreNybble(t *testing.T) {
	var source [256]byte
	for i := range source {
		source[i] = byte(i)
	}
	target := PreNybble(source[:])
	for i := range target {
		if target[i] > 0x3F {
			t.Errorf("target[%d] too large: 0x%02X", i, target[i])
		}
	}
}

func TestPrePostNybble(t *testing.T) {
	var source [256]byte
	for i := range source {
		source[i] = byte(i)
	}
	target := PreNybble(source[:])
	sourceCheck := PostNybble(target[:])
	for i := range source {
		if source[i] != sourceCheck[i] {
			t.Errorf("source, sourceCheck differ at %d: 0x%02X != 0x%02X", i, source[i], sourceCheck[i])
		}
	}
}

func TestNybbleAndBack(t *testing.T) {
	var randomDosDisk [DOS_DISK_BYTES]byte
	for i := range randomDosDisk {
		randomDosDisk[i] = byte(rand.Intn(256))
	}
	sectorOrder := Dos33PhysicalToLogicalSectorMap
	tracks, err := dos16ToNybbleTracks(randomDosDisk[:], 0, DEFAULT_PRESYNC, DEFAULT_INTRASYNC, sectorOrder)
	if err != nil {
		t.Fatal(err)
	}
	nyb := NewNybble(tracks)
	bytesOut, err := NybbleToDos16(nyb, sectorOrder)
	if err != nil {
		t.Fatal(err)
	}
	if len(bytesOut) != DOS_DISK_BYTES {
		t.Fatalf("Expected %d bytes out as dos disk, got %d", DOS_DISK_BYTES, len(bytesOut))
	}
	for i := range bytesOut {
		if bytesOut[i] != randomDosDisk[i] {
			t.Fatalf("Difference at %d: %d should be %d", i, bytesOut[i], randomDosDisk[i])
		}
	}
}
