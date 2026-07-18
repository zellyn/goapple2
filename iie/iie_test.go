package iie

import "testing"

func TestRamRdRamWrt(t *testing.T) {
	m := New()
	m.Write(0x2000, 0x11) // main
	m.Write(0xC005, 0)    // RAMWRT on
	m.Write(0x2000, 0x22) // aux
	m.Write(0xC004, 0)    // RAMWRT off

	if got := m.Read(0x2000); got != 0x11 {
		t.Errorf("main read = %#02x, want 0x11", got)
	}
	m.Write(0xC003, 0) // RAMRD on
	if got := m.Read(0x2000); got != 0x22 {
		t.Errorf("aux read = %#02x, want 0x22", got)
	}
	if got := m.Read(0xC013); got != 0x80 {
		t.Errorf("RDRAMRD = %#02x, want 0x80", got)
	}
	if got := m.Read(0xC014); got != 0 {
		t.Errorf("RDRAMWRT = %#02x, want 0", got)
	}
	m.Write(0xC002, 0) // RAMRD off
	if got := m.Read(0x2000); got != 0x11 {
		t.Errorf("main read after RAMRD off = %#02x, want 0x11", got)
	}
}

func TestZeroPageStackUnaffectedByRamRdWrt(t *testing.T) {
	m := New()
	m.Write(0xC005, 0) // RAMWRT on
	m.Write(0xC003, 0) // RAMRD on
	m.Write(0x0080, 0x33)
	m.Write(0x01FF, 0x44)
	if m.Main[0x0080] != 0x33 || m.Main[0x01FF] != 0x44 {
		t.Errorf("ZP/stack writes should hit main RAM with ALTZP off")
	}
	if m.Aux[0x0080] != 0 {
		t.Errorf("ZP write leaked to aux")
	}
}

func TestAltZP(t *testing.T) {
	m := New()
	m.Write(0x0080, 0x55)
	m.Write(0xC009, 0) // ALTZP on
	if got := m.Read(0x0080); got != 0 {
		t.Errorf("aux ZP read = %#02x, want 0", got)
	}
	m.Write(0x0080, 0x66)
	if got := m.Read(0xC016); got != 0x80 {
		t.Errorf("RDALTZP = %#02x, want 0x80", got)
	}
	m.Write(0xC008, 0) // ALTZP off
	if got := m.Read(0x0080); got != 0x55 {
		t.Errorf("main ZP read = %#02x, want 0x55", got)
	}
	if m.Aux[0x0080] != 0x66 {
		t.Errorf("aux ZP = %#02x, want 0x66", m.Aux[0x0080])
	}
}

func TestLanguageCardDance(t *testing.T) {
	m := New()
	for i := range m.ROM {
		m.ROM[i] = 0xEA
	}

	// Reset state: ROM read, write disabled, bank 2.
	if got := m.Read(0xD123); got != 0xEA {
		t.Errorf("reset-state read = %#02x, want ROM 0xEA", got)
	}
	m.Write(0xD123, 0x01)
	if got := m.Read(0xD123); got != 0xEA {
		t.Errorf("write should be dropped while write-disabled")
	}

	// Double read of $C08B: read RAM bank 1, write enable.
	m.Read(0xC08B)
	m.Read(0xC08B)
	if !m.LCReadRAM || !m.LCWriteEnabled || m.LCBank2 {
		t.Fatalf("after 2x $C08B: ReadRAM=%v WriteEnabled=%v Bank2=%v, want true,true,false",
			m.LCReadRAM, m.LCWriteEnabled, m.LCBank2)
	}
	m.Write(0xD123, 0x77)
	if got := m.Read(0xD123); got != 0x77 {
		t.Errorf("bank1 RAM read = %#02x, want 0x77", got)
	}

	// Single read of $C08B must NOT re-enable writes after an even access.
	m.Read(0xC08A) // read RAM? no: low2=2 -> ROM read, write disable
	if m.LCWriteEnabled {
		t.Fatalf("even access should disable writes")
	}
	m.Read(0xC08B)
	if m.LCWriteEnabled {
		t.Errorf("single odd read should not write-enable")
	}
	m.Read(0xC08B)
	if !m.LCWriteEnabled {
		t.Errorf("second consecutive odd read should write-enable")
	}

	// Write access to odd switch resets the prewrite counter.
	m.Read(0xC08A) // disable writes
	m.Write(0xC08B, 0)
	m.Read(0xC08B)
	if m.LCWriteEnabled {
		t.Errorf("write access must reset prewrite counting")
	}

	// Bank 2 vs bank 1 are distinct for $D000-$DFFF, shared for $E000+.
	m.Read(0xC08B)
	m.Read(0xC08B) // bank1, RAM read+write
	m.Write(0xD000, 0x0B)
	m.Write(0xE000, 0x0E)
	m.Read(0xC083)
	m.Read(0xC083) // bank2, RAM read+write
	if got := m.Read(0xD000); got == 0x0B {
		t.Errorf("bank2 $D000 should differ from bank1")
	}
	m.Write(0xD000, 0x2B)
	if got := m.Read(0xE000); got != 0x0E {
		t.Errorf("$E000 should be shared between banks; got %#02x", got)
	}
	m.Read(0xC08B)
	m.Read(0xC08B) // back to bank1
	if got := m.Read(0xD000); got != 0x0B {
		t.Errorf("bank1 $D000 = %#02x, want 0x0B", got)
	}
	if got := m.Read(0xC011); got != 0 {
		t.Errorf("RDLCBNK2 = %#02x, want 0 (bank1)", got)
	}
}

func TestAltZPSelectsAuxLCRAM(t *testing.T) {
	m := New()
	m.Read(0xC08B)
	m.Read(0xC08B) // bank1 RAM read+write
	m.Write(0xD100, 0xAA)
	m.Write(0xC009, 0) // ALTZP on: LC RAM now aux
	if got := m.Read(0xD100); got == 0xAA {
		t.Errorf("aux LC RAM should be distinct from main LC RAM")
	}
	m.Write(0xD100, 0xBB)
	m.Write(0xC008, 0) // ALTZP off
	if got := m.Read(0xD100); got != 0xAA {
		t.Errorf("main LC RAM = %#02x, want 0xAA", got)
	}
	if m.AuxD000Bank2[0x100] != 0 && m.Aux[0xD100] != 0xBB {
		t.Errorf("aux LC write landed in the wrong place")
	}
}

func TestUnhandledTracking(t *testing.T) {
	m := New()
	m.Write(0xC001, 0) // 80STORE on: unsupported
	m.Read(0xC000)     // keyboard: unsupported
	if len(m.Unhandled) != 2 {
		t.Errorf("Unhandled = %v, want 2 entries", m.Unhandled)
	}
}
