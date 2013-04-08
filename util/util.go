package util

import (
	"fmt"
	"io/ioutil"
)

func ReadRomOrDie(filename string) []byte {
	bytes, err := ioutil.ReadFile(filename)
	if err != nil {
		panic("Cannot read ROM file: " + filename)
	}
	return bytes
}

func ReadSmallCharacterRomOrDie(filename string) [2048]byte {
	bytes := ReadRomOrDie(filename)
	if len(bytes) != 512 {
		panic(fmt.Sprintf("Got %d bytes (not 512) from file '%s'", len(bytes), filename))
	}
	var value [2048]byte
	for i, b := range bytes {
		value[i] = (b ^ 0xff) & 0x7f
		value[i+512] = b | 0x80
		value[i+1024] = b & 0x7f
		value[i+1536] = b & 0x7f
	}
	return value
}

func ReadFullCharacterRomOrDie(filename string) [2048]byte {
	bytes := ReadRomOrDie(filename)
	if len(bytes) != 2048 {
		panic(fmt.Sprintf("Got %d bytes (not 2048) from file '%s'", len(bytes), filename))
	}
	var value [2048]byte
	copy(value[:], bytes)
	return value
}
