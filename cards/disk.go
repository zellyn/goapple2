package cards

import (
	"fmt"

	"github.com/zellyn/goapple2/disk"
)

type Disk interface {
	Read() byte
	Write(byte)
	SetHalfTrack(byte)
	HalfTrack() byte
	SetVolume(byte)
	Volume() byte
	Writeable() bool
}

type DiskCard struct {
	rom     [256]byte
	cm      CardManager
	slot    byte
	slotbit byte
	disks   [2]Disk
	active  int
	phases  byte
}

func NewDiskCard(rom []byte, slot byte, cm CardManager) (*DiskCard, error) {
	if len(rom) != 256 {
		return nil, fmt.Errorf("Wrong size ROM: expected 256, got %d", len(rom))
	}
	dc := &DiskCard{
		cm:      cm,
		slot:    slot,
		slotbit: 1 << slot,
		disks:   [2]Disk{disk.NewDummy(disk.DEFAULT_VOLUME), disk.NewDummy(disk.DEFAULT_VOLUME)},
	}
	copy(dc.rom[:], rom)
	return dc, nil
}

func (dc *DiskCard) String() string {
	return fmt.Sprintf("Disk Card (slot %d)", dc.slot)
}

func (dc *DiskCard) Slot() byte {
	return dc.slot
}

func (dc *DiskCard) ROMDisabled() {
	// Disk card doesn't have a $C(8-F)xx ROM
}

func (dc *DiskCard) handlePhase(phase byte, onOff bool) {
	phaseBit := byte(1 << phase)
	if onOff {
		dc.phases |= phaseBit
	} else {
		dc.phases &^= phaseBit
	}

	disk := dc.disks[dc.active]
	newTrack := int(disk.HalfTrack())
	switch dc.phases {
	case 1:
		newTrack = (newTrack + 1) / 4 * 4
	case 2:
		newTrack = (newTrack/4)*4 + 1
	case 4:
		if newTrack != 0 {
			newTrack = (newTrack-1)/4*4 + 2
		}
	case 8:
		if newTrack < 2 {
			newTrack = 0
		} else {
			newTrack = (newTrack-2)/4*4 + 3
		}
	default:
		return
	}
	if newTrack < 0 {
		newTrack = 0
	}
	if newTrack > 68 {
		newTrack = 68
	}
	if disk.HalfTrack() != byte(newTrack) {
		disk.SetHalfTrack(byte(newTrack))
	}
}

func (dc *DiskCard) handleAccess(address byte) {
	if address < 8 {
		phase := address / 2
		onOff := (address & 1) == 1
		dc.handlePhase(phase, onOff)
		return
	}
}

func (dc *DiskCard) Read16(address byte) byte {
	dc.handleAccess(address)
	return dc.cm.EmptyRead()
}

func (dc *DiskCard) Write16(address byte, value byte) {
	dc.handleAccess(address)
}

func (dc *DiskCard) Read(address uint16) byte {
	panic(fmt.Sprintf("%s got read to $%04X", dc.String(), address))
}

func (dc *DiskCard) Write(address uint16, value byte) {
	panic(fmt.Sprintf("%s got write to $%04X", dc.String(), address))
}

func (dc *DiskCard) Read256(address byte) byte {
	return dc.rom[address]
}

func (dc *DiskCard) Write256(address byte, value byte) {
	// Firmware is ROM: do nothing
}

func (dc *DiskCard) LoadDisk(d Disk, which int) {
	dc.disks[which] = d
}
