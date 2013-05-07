package main

import (
	"log"
	"os"

	"github.com/gonuts/commander"
	"github.com/gonuts/flag"
)

var a2cmd *commander.Commander

func init() {
	a2cmd = &commander.Commander{
		Name: os.Args[0],
		Commands: []*commander.Command{
			cmdDisasm,
			cmdDiskConvert,
		},
		Flag: flag.NewFlagSet("a2", flag.ExitOnError),
	}
}

func main() {
	if err := a2cmd.Flag.Parse(os.Args[1:]); err != nil {
		log.Fatal(err)
	}
	args := a2cmd.Flag.Args()
	if err := a2cmd.Run(args); err != nil {
		log.Fatal(err)
	}
}
