package main

import (
	"log"
	"os"

	"github.com/gonuts/commander"
	"github.com/gonuts/flag"
)

var a2cmd *commander.Command

func init() {
	a2cmd = &commander.Command{
		UsageLine: "a2",
		Subcommands: []*commander.Command{
			cmdDisasm,
			cmdDiskConvert,
			cmdCharROM,
		},
		Flag: *flag.NewFlagSet("a2", flag.ExitOnError),
	}
}

func main() {
	if err := a2cmd.Dispatch(os.Args[1:]); err != nil {
		log.Fatal(err)
	}
}
