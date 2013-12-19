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

func init() {
	cmdDisasm.Flag.UintVar(&disasmAddress, "a", 0, "The starting memory address.")
}

func runDisasm(cmd *commander.Command, args []string) error {
	if len(args) != 1 {
		cmd.Usage()
		return nil
	}

	bytes, err := ioutil.ReadFile(args[0])
	if err != nil {
		return nil
	}
	if len(bytes) > 0x10000 {
		return fmt.Errorf("File %s is %04X bytes long, which is more than $10000.", args[0], len(bytes))
	}
	if int(disasmAddress)+len(bytes) > 0x10000 {
		return fmt.Errorf("Starting address ($%04X) + file length ($%04X) = $%X, which is > $10000",
			disasmAddress, len(bytes), int(disasmAddress)+len(bytes))
	}

	asm.DisasmBlock(bytes, uint16(disasmAddress), os.Stdout)
	return nil
}
