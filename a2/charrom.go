package main

import (
	"io/ioutil"

	"github.com/gonuts/commander"
	"github.com/zellyn/goapple2/videoscan"
)

var cmdCharROM = &commander.Command{
	Run:       runCharROM,
	UsageLine: "charrom infile outfile",
	Short:     "convert apple II character ROMs to text and back",
	Long: `
CharROM is a simple character ROM conversion utility.
`,
}

var decompile bool
var reverse bool

func init() {
	cmdCharROM.Flag.BoolVar(&decompile, "d", false, "decompile: convert from ROM to text.")
	cmdCharROM.Flag.BoolVar(&reverse, "r", false, "reverse: put bits in opposite order.")
}

func runCharROM(cmd *commander.Command, args []string) error {
	if len(args) != 2 {
		cmd.Usage()
		return nil
	}

	in, err := ioutil.ReadFile(args[0])
	if err != nil {
		panic("Cannot read file: " + args[0])
	}

	if decompile {
		out := videoscan.BytesToText(in, reverse)
		err := ioutil.WriteFile(args[1], out, 0644)
		return err
	}

	out, err := videoscan.TextToBytes(in, reverse)
	if err != nil {
		return err
	}
	err = ioutil.WriteFile(args[1], out, 0644)
	return err
}
