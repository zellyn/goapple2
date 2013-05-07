package disk

type SavedPos struct {
	halfTrack byte
	position  int
}

type Nybble struct {
	Tracks    [][]byte
	halfTrack byte
	position  int
	writeable bool
}

func NewNybble(tracks [][]byte) *Nybble {
	nd := Nybble{
		Tracks: tracks,
	}
	return &nd
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

func (disk *Nybble) Writeable() bool {
	return disk.writeable
}

func (disk *Nybble) GetPos() SavedPos {
	return SavedPos{disk.halfTrack, disk.position}
}

func (disk *Nybble) SetPos(pos SavedPos) {
	disk.halfTrack = pos.halfTrack
	disk.position = pos.position
}
