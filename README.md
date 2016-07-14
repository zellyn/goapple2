# goapple2

Apple ][+ emulator written in Go.

## Install

`go get -u github.com/zellyn/goapple2/{texty,shiny}`

## Status

Basic functionality (keyboard input, text, low and hires graphics)
works.

Very basic (and fake) *read-only* disk access works, for `.dsk` images
where no trickery is involved.

This was one of my early Go-learning projects: the code organization
is pretty horrible.

## Shiny

This is the main "supported" interface, hacked together during hack
day at GopherCon2016. It's almost certainly doing things wrong
Shiny-wise: pull requests welcome. Press backquote/tilde to exit.

## Texty

`texty/` contains a hackish version of the emulator that runs in a
terminal. It interprets all videoscan outputs as text, regardless of
any other settings. Press `~` to exit.

## Where to find ROMs

cd data/roms
./getroms.sh

## Contributing

Pull requests welcome. If you have any questions, feel free to get in
touch with me: username "zellyn" on gmail, twitter, facebook, github,
golang slack.

### Contributors

- [zellyn](https://github.com/zellyn)
- [frumious](https://github.com/frumious)
