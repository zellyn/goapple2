package disk

import (
	"fmt"
)

// Dos33writeTable is the list of valid DOS 3.3 bytes.
// See [UtA2 9-27 Disk Data Formats].
var Dos33writeTable = [64]byte{
	0x96, 0x97, 0x9A, 0x9B, 0x9D, 0x9E, 0x9F, 0xA6,
	0xA7, 0xAB, 0xAC, 0xAD, 0xAE, 0xAF, 0xB2, 0xB3,
	0xB4, 0xB5, 0xB6, 0xB7, 0xB9, 0xBA, 0xBB, 0xBC,
	0xBD, 0xBE, 0xBF, 0xCB, 0xCD, 0xCE, 0xCF, 0xD3,
	0xD6, 0xD7, 0xD9, 0xDA, 0xDB, 0xDC, 0xDD, 0xDE,
	0xDF, 0xE5, 0xE6, 0xE7, 0xE9, 0xEA, 0xEB, 0xEC,
	0xED, 0xEE, 0xEF, 0xF2, 0xF3, 0xF4, 0xF5, 0xF6,
	0xF7, 0xF9, 0xFA, 0xFB, 0xFC, 0xFD, 0xFE, 0xFF,
}

// Dos33LogicalToPhysicalSectorMap maps logical sector numbers to physical ones.
// See [UtA2 9-42 - Read Routines].
var Dos33LogicalToPhysicalSectorMap = []byte{
	0x00, 0x0D, 0x0B, 0x09, 0x07, 0x05, 0x03, 0x01,
	0x0E, 0x0C, 0x0A, 0x08, 0x06, 0x04, 0x02, 0x0F,
}

// Dos33PhysicalToLogicalSectorMap maps physical sector numbers to logical ones.
// See [UtA2 9-42 - Read Routines].
var Dos33PhysicalToLogicalSectorMap = []byte{
	0x00, 0x07, 0x0E, 0x06, 0x0D, 0x05, 0x0C, 0x04,
	0x0B, 0x03, 0x0A, 0x02, 0x09, 0x01, 0x08, 0x0F,
}

// ProDosLogicalToPhysicalSectorMap maps logical sector numbers to pysical ones.
// See [UtA2e 9-43 - Sectors vs. Blocks].
var ProDosLogicalToPhysicalSectorMap = []byte{
	0x00, 0x02, 0x04, 0x06, 0x08, 0x0A, 0x0C, 0x0E,
	0x01, 0x03, 0x05, 0x07, 0x09, 0x0B, 0x0D, 0x0F,
}

// ProDosPhysicalToLogicalSectorMap maps physical sector numbers to logical ones.
// See [UtA2e 9-43 - Sectors vs. Blocks].
var ProDosPhysicalToLogicalSectorMap = []byte{
	0x00, 0x08, 0x01, 0x09, 0x02, 0x0A, 0x03, 0x0B,
	0x04, 0x0C, 0x05, 0x0D, 0x06, 0x0E, 0x07, 0x0F,
}

// PreNybble converts from 256 8-bit bytes to 342 6-bit "nybbles".
// The equivalent DOS routine, PRE.NYBBLE, would put the 256 MSB-6's into one buffer,
// and the 86 LSB-2's into a separate one, but we place the 86 after the 256.
// See http://www.txbobsc.com/aal/1981/aal8106.html#a5
func PreNybble(source []byte) (target [342]byte) {
	if len(source) != 256 {
		panic(fmt.Sprintf("PreNybble expects 256 bytes as input, got %d", len(source)))
	}
	y := 2
	for i := 0; i < 3; i++ {
		for x := 0; x < 86; x++ {
			// DEY
			y = (y + 0xff) & 0xff
			a := source[y]
			target[y] = a >> 2
			target[x+256] = (target[x+256]<<2 + a&2>>1 + a&1<<1) & 0x3F
		}
	}
	return target
}

// PostNybble converts from 342 6-bit "nybbles to 255 8-bit bytes.
// The equivalent DOS routine, POST.NYBBLE, would read the 256 MSB-6's from one buffer,
// and the 86 LSB-2's from a separate one, but we place the 86 after the 256.
// See http://www.txbobsc.com/aal/1981/aal8106.html#a5
func PostNybble(source []byte) (target [256]byte) {
	if len(source) != 342 {
		panic(fmt.Sprintf("PostNybble expects 342 bytes as input, got %d", len(source)))
	}

	x := 0
	for y := 0; y < 256; y++ {
		// DEX
		x = (x + 85) % 86
		a := source[256+x]
		source[256+x] = a >> 2
		target[y] = source[y]<<2 + a&2>>1 + a&1<<1
	}
	return target
}

// appendSyncs appends the given number of sync bytes to the slice, and returns the resulting slice.
func appendSyncs(target []byte, count int) []byte {
	for i := 0; i < count; i++ {
		target = append(target, 0xFF)
	}
	return target
}

// append44 appends bytes using the 4-4 encoded format used for volume, track, sector, checksum.
func append44(target []byte, b byte) []byte {
	return append(target, 0xAA|(b>>1), 0xAA|b)
}

// appendAddress appends the encoded sector address to the slice, and returns the resulting slice.
func appendAddress(target []byte, t, s, v byte) []byte {
	target = append(target, 0xD5, 0xAA, 0x96)
	fmt.Println("s=", s)
	target = append44(target, v)
	target = append44(target, t)
	target = append44(target, s)
	target = append44(target, v^t^s)
	target = append(target, 0xDE, 0xAA, 0xEB)
	return target
}

// appendData appends the encoded sector data to the slice, and returns the resulting slice.
func appendData(target, source []byte) []byte {
	target = append(target, 0xD5, 0xAA, 0xAD)
	nybbles := PreNybble(source)
	checksum := byte(0)
	for i := 341; i >= 256; i-- {
		target = append(target, Dos33writeTable[nybbles[i]^checksum])
		checksum = nybbles[i]
	}
	for i := 0; i < 256; i++ {
		target = append(target, Dos33writeTable[nybbles[i]^checksum])
		checksum = nybbles[i]
	}
	target = append(target, Dos33writeTable[checksum])
	target = append(target, 0xDE, 0xAA, 0xEB)
	return target
}

// dosToNybbleSector appends a single 256-byte DOS sector in .nyb format, and returns the slice.
func dosToNybbleSector(target, source []byte, t, s, v byte, preSync, intraSync int) []byte {
	if len(source) != 256 {
		panic(fmt.Sprintf("dosToNybbleSector expects 256 bytes, got %d", len(source)))
	}
	target = appendSyncs(target, preSync)
	target = appendAddress(target, t, s, v)
	target = appendSyncs(target, intraSync)
	target = appendData(target, source)
	return target
}

// dos16ToNybbleTrack converts a 16-sector dos image of a track to a nybblized track.
func dos16ToNybbleTrack(source []byte, t, v byte, preSync, intraSync int, sectorOrder []byte) []byte {
	trackSync := NYBBLE_TRACK_BYTES - 16*(preSync+NYBBLE_ADDRESS_BYTES+intraSync+NYBBLE_DATA_BYTES)
	target := make([]byte, 0, NYBBLE_TRACK_BYTES)
	target = appendSyncs(target, trackSync)
	for s := byte(0); s < 16; s++ {
		start := 256 * int(sectorOrder[s])
		target = dosToNybbleSector(target, source[start:start+256], t, s, v, preSync, intraSync)
	}
	if len(target) != NYBBLE_TRACK_BYTES {
		panic(fmt.Sprintf("Tracks should be %d bytes, go %d", NYBBLE_TRACK_BYTES, len(target)))
	}
	return target
}

func dos16ToNybbleTracks(source []byte, v byte, preSync, intraSync int, sectorOrder []byte) (tracks [][]byte, err error) {
	if preSync+intraSync > MAX_PRE_INTRA_SYNC {
		return nil, fmt.Errorf("preSync(%d) + intraSync(%d) cannot be more than %d bytes",
			preSync, intraSync, MAX_PRE_INTRA_SYNC)
	}

	for t := byte(0); t < 35; t++ {
		start := DOS_TRACK_BYTES * int(t)
		trackBytes := source[start : start+DOS_TRACK_BYTES]
		track := dos16ToNybbleTrack(trackBytes, t, v, preSync, intraSync, sectorOrder)
		tracks = append(tracks, track)
	}
	return tracks, nil
}
