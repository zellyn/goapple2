package disk

import (
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
