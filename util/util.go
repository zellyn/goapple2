package util

import (
	"io/ioutil"
)

func ReadRomOrDie(filename string) []byte {
	bytes, err := ioutil.ReadFile(filename)
	if err != nil {
		panic("Cannot read ROM file: " + filename)
	}
	return bytes
}
