// convert.go contains routines to convert from character ROMs to text and back.
package videoscan

import (
	"fmt"
	"strings"
)

var chars = []rune{'.', '#'}

func reverseByte(in byte) byte {
	hi := in & 0x80
	var out byte
	for i := 0; i < 7; i++ {
		out = out << 1
		out = out | in&1
		in = in >> 1
	}
	out |= hi
	return out
}

func BytesToText(rom []byte, reverse bool) []byte {
	result := []byte{}
	for i, b := range rom {
		if reverse {
			b = reverseByte(b)
		}
		if i > 0 && i%8 == 0 {
			result = append(result, '\n')
		}
		if b >= 0x80 {
			result = append(result, 'i')
		} else {
			result = append(result, 'n')
		}
		result = append(result, ' ')
		for i := 0; i < 7; i++ {
			result = append(result, byte(chars[b&1]))
			b = b >> 1
		}
		result = append(result, '\n')
	}
	return result
}

func TextToBytes(text []byte, reverse bool) ([]byte, error) {
	result := []byte{}
	lines := strings.Split(string(text), "\n")
	for i, l := range lines {
		l = strings.TrimSpace(l)
		lines[i] = l
		if i != 0 && i%9 == 8 {
			if l != "" {
				return nil, fmt.Errorf("line %d: expected empty line, got '%s'", i+1, l)
			}
			continue
		}
		if len(l) != 9 {
			return nil, fmt.Errorf("line %d: expected 9 characters, got %d: '%s'", i+1, len(l), l)
		}

		var hi byte
		switch l[0] {
		case 'i':
			hi = 0x80
		case 'n':
		default:
			return nil, fmt.Errorf("line %d: should start with 'n' or 'i'; got '%s'", i+1, l[0])
		}

		if l[1] != ' ' {
			return nil, fmt.Errorf("line %d: second char should be space; got '%s'", i+1, l[1])
		}
		var b byte
		var bit byte = 1
		for _, c := range l[2:] {
			switch c {
			case chars[0]: // do nothing
			case chars[1]:
				b |= bit
			default:
				return nil, fmt.Errorf("line %d: expected character: '%s'", i+1, c)
			}
			bit <<= 1
		}
		b |= hi
		if reverse {
			b = reverseByte(b)
		}
		result = append(result, b)
	}
	return result, nil
}
