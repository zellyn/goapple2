package main

import (
	"fmt"
	"io/ioutil"
	"os"

	"github.com/gonuts/commander"
	"github.com/zellyn/go6502/asm"
)

var cmdDisasm = &commander.Command{
	Run:       runDisasm,
	UsageLine: "disasm [-a address] filename",
	Short:     "disassemble binary files",
	Long: `
Disasm is a very simple disassembler for 6502 binary files.
`,
}

var disasmAddress uint // disasm -a flag
var symbolFile string  // disasm -s flag
var printLabels bool   // disasm -p flag

func init() {
	cmdDisasm.Flag.UintVar(&disasmAddress, "a", 0, "The starting memory address.")
	cmdDisasm.Flag.StringVar(&symbolFile, "s", "", "File of symbol definitions.")
	cmdDisasm.Flag.BoolVar(&printLabels, "p", false, "Print labels for symbols.")
}

func runDisasm(cmd *commander.Command, args []string) error {
	if len(args) != 1 {
		cmd.Usage()
		return nil
	}

	bytes, err := ioutil.ReadFile(args[0])
	if err != nil {
		return err
	}
	if len(bytes) > 0x10000 {
		return fmt.Errorf("File %s is %04X bytes long, which is more than $10000.", args[0], len(bytes))
	}
	if int(disasmAddress)+len(bytes) > 0x10000 {
		return fmt.Errorf("Starting address ($%04X) + file length ($%04X) = $%X, which is > $10000",
			disasmAddress, len(bytes), int(disasmAddress)+len(bytes))
	}

	var s asm.Symbols
	if symbolFile != "" {
		s, err = asm.ReadSymbols(symbolFile)
		if err != nil {
			return err
		}
	} else {
		if printLabels {
			return fmt.Errorf("-p (print labels) specified without -s (symbol table file")
		}
	}

	asm.DisasmBlock(bytes, uint16(disasmAddress), os.Stdout, s, 2, printLabels)
	return nil
}
