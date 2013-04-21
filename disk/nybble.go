package disk

import (
	"fmt"
	"io/ioutil"
	"strings"
)

type Nybble struct {
	Tracks    [][]byte
	volume    byte
	halfTrack byte
	position  int
	writeable bool
}

func NewNybble() *Nybble {
	nd := Nybble{
		volume: DEFAULT_VOLUME,
	}
	return &nd
}

func (disk *Nybble) LoadDosDisk(filename string) error {
	var sectorOrder []byte
	switch {
	case strings.HasSuffix(filename, ".dsk"):
		sectorOrder = Dos33PhysicalToLogicalSectorMap
	case strings.HasSuffix(filename, ".do"):
		sectorOrder = Dos33PhysicalToLogicalSectorMap
	case strings.HasSuffix(filename, ".po"):
		sectorOrder = ProDosPhysicalToLogicalSectorMap
	default:
		return fmt.Errorf("Unknown suffix (not .dsk, .do, or .po): %s", filename)
	}

	bytes, err := ioutil.ReadFile(filename)
	if err != nil {
		return err
	}
	if len(bytes) != DOS_DISK_BYTES {
		return fmt.Errorf("Disk images should be %d bytes, got %d: %s", DOS_DISK_BYTES, len(bytes), filename)
	}
	tracks, err := dos16ToNybbleTracks(bytes, disk.Volume(), DEFAULT_PRESYNC, DEFAULT_INTRASYNC, sectorOrder)
	if err != nil {
		return err
	}
	disk.Tracks = tracks
	return nil
}

func (disk *Nybble) Read() byte {
	track := disk.Tracks[disk.halfTrack/2]
	disk.position = (disk.position + 1) % len(track)
	return track[disk.position]
}

func (disk *Nybble) Skip(amount int) {
	track := disk.Tracks[disk.halfTrack/2]
	disk.position = (disk.position + amount) % len(track)
}

func (disk *Nybble) Write(b byte) {
	track := disk.Tracks[disk.halfTrack/2]
	disk.position = (disk.position + 1) % len(track)
	if disk.writeable {
		track[disk.position] = b
	}
}

func (disk *Nybble) SetHalfTrack(halfTrack byte) {
	disk.halfTrack = halfTrack
}

func (disk *Nybble) HalfTrack() byte {
	return disk.halfTrack
}

func (disk *Nybble) SetVolume(volume byte) {
	disk.volume = volume
}

func (disk *Nybble) Volume() byte {
	return disk.volume
}

func (disk *Nybble) Writeable() bool {
	return disk.writeable
}
