package util

import (
	"fmt"
	"io/ioutil"
)

func ReadRomOrDie(filename string, size int) []byte {
	bytes, err := ioutil.ReadFile(filename)
	if err != nil {
		panic("Cannot read ROM file: " + filename)
	}
	if len(bytes) != size {
		panic(fmt.Sprintf("Want length of %d for ROM %q; want %d", size, filename, len(bytes)))
	}
	return bytes
}

func ReadSmallCharacterRomOrDie(filename string) [2048]byte {
	bytes := ReadRomOrDie(filename, 512)
	if len(bytes) != 512 {
		panic(fmt.Sprintf("Got %d bytes (not 512) from file '%s'", len(bytes), filename))
	}
	var value [2048]byte
	for i, b := range bytes {
		value[i] = (b ^ 0xff) & 0x7f
		value[i+512] = b | 0x80
		value[i+1024] = b
		value[i+1536] = b | 0x80
	}
	return value
}

func ReadFullCharacterRomOrDie(filename string) [2048]byte {
	bytes := ReadRomOrDie(filename, 2048)
	if len(bytes) != 2048 {
		panic(fmt.Sprintf("Got %d bytes (not 2048) from file '%s'", len(bytes), filename))
	}
	var value [2048]byte
	copy(value[:], bytes)
	return value
}
