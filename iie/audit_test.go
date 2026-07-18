package iie

import (
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"testing"

	"github.com/zellyn/go6502/cpu"
)

// Zero-page result flags, fixed by a2audit's source.
const (
	auditLCResult  = 0x10
	auditAuxResult = 0x12
)

// auditMemory assembles a2audit's audit.o (with the ACME binary pinned in
// that repo), and returns a Memory with the audit code at $6000, the ][+ ROM
// in place, and the MEMORY global set to 128K — plus the audit symbol table,
// parsed from ACME's symbol list so addresses never go stale. Skips the test
// if a sibling ../../a2audit checkout or the ROM is unavailable. Note the
// pinned acme is a hermit shim: first-ever use needs network access.
func auditMemory(t *testing.T) (*Memory, map[string]uint16) {
	t.Helper()
	auditDir, err := filepath.Abs("../../a2audit/audit")
	if err != nil || !exists(auditDir) {
		t.Skipf("a2audit checkout not found at %s", auditDir)
	}
	acme, err := filepath.Abs("../../a2audit/bin/acme")
	if err != nil || !exists(acme) {
		t.Skip("pinned acme binary not found in a2audit")
	}
	symfile := filepath.Join(t.TempDir(), "audit.sym")
	cmd := exec.Command(acme, "--symbollist", symfile, "audit.asm")
	cmd.Dir = auditDir
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("acme failed: %v\n%s", err, out)
	}
	symbols := parseSymbols(t, symfile)
	binary, err := os.ReadFile(filepath.Join(auditDir, "audit.o"))
	if err != nil {
		t.Fatal(err)
	}
	rom, err := os.ReadFile("../data/roms/apple2+.rom")
	if err != nil {
		t.Skipf("][+ ROM not available: %v", err)
	}

	m := New()
	copy(m.ROM[:], rom)
	copy(m.Main[0x6000:], binary)
	memoryGlobal, ok := symbols["MEMORY"]
	if !ok {
		t.Fatal("MEMORY symbol not found in acme symbol list")
	}
	m.Main[memoryGlobal] = 128 // KB; normally set by the IDENTIFY routine
	m.Main[memoryGlobal+1] = 0
	return m, symbols
}

// parseSymbols reads an ACME --symbollist file (lines like
// "\tLANGCARDTESTS\t= $6130\t; ?").
func parseSymbols(t *testing.T, path string) map[string]uint16 {
	t.Helper()
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	symbols := map[string]uint16{}
	for _, line := range strings.Split(string(data), "\n") {
		name, rest, ok := strings.Cut(strings.TrimSpace(line), "=")
		if !ok {
			continue
		}
		rest = strings.TrimSpace(rest)
		if i := strings.IndexAny(rest, " \t;"); i >= 0 {
			rest = rest[:i]
		}
		if !strings.HasPrefix(rest, "$") {
			continue
		}
		val, err := strconv.ParseUint(rest[1:], 16, 32)
		if err != nil || val > 0xFFFF {
			continue
		}
		symbols[strings.TrimSpace(name)] = uint16(val)
	}
	return symbols
}

// runAudit initializes the machine the way a real boot would (SETKBD,
// SETVID, INIT, HOME from the monitor ROM), then calls each of the given
// audit-test entry points in turn, and parks. It fails the test if the run
// doesn't complete.
func runAudit(t *testing.T, m *Memory, entryPoints ...uint16) {
	t.Helper()
	const stub = 0x9000
	code := []byte{
		0x20, 0x89, 0xFE, // JSR SETKBD
		0x20, 0x93, 0xFE, // JSR SETVID
		0x20, 0x2F, 0xFB, // JSR INIT
		0x20, 0x58, 0xFC, // JSR HOME
	}
	for _, entry := range entryPoints {
		if entry == 0 {
			t.Fatal("audit entry-point symbol missing from acme symbol list")
		}
		code = append(code, 0x20, byte(entry), byte(entry>>8))
	}
	park := stub + uint16(len(code))
	code = append(code, 0x4C, byte(park), byte(park>>8)) // JMP * (park)
	copy(m.Main[stub:], code)

	var cycles uint64
	c := cpu.NewCPU(m, func() { cycles++ }, cpu.VERSION_6502)
	c.SetPC(stub)
	for c.PC() != park && cycles < 100_000_000 {
		if err := c.Step(); err != nil {
			t.Fatalf("CPU error after %d cycles: %v (screen:\n%s)", cycles, err, screen(m))
		}
	}
	if c.PC() != park {
		t.Fatalf("audit code never returned (cycle limit); screen:\n%s", screen(m))
	}
}

// TestA2AuditLangcard validates the Language Card implementation against the
// data-driven language-card tests from github.com/zellyn/a2audit, which are
// themselves verified against real hardware.
func TestA2AuditLangcard(t *testing.T) {
	m, symbols := auditMemory(t)
	runAudit(t, m, symbols["LANGCARDTESTS"])
	if m.Main[auditLCResult] != 1 {
		t.Errorf("LCRESULT = %d, want 1; screen:\n%s", m.Main[auditLCResult], screen(m))
	}
}

// TestA2AuditAuxmem validates RAMRD/RAMWRT/ALTZP behavior against a2audit's
// aux-memory tests. These also exercise 80STORE/PAGE2 display-page banking
// and Cxxx ROM switching, which this model does not yet implement.
func TestA2AuditAuxmem(t *testing.T) {
	t.Skip("needs 80STORE/PAGE2/HIRES and INTCXROM/SLOTC3ROM support (stage 2); " +
		"without them the run hangs in the 80STORE and Cxxx portions")
	m, symbols := auditMemory(t)
	runAudit(t, m, symbols["LANGCARDTESTS"], symbols["AUXMEMTESTS"])
	if m.Main[auditAuxResult] != 1 {
		t.Errorf("AUXRESULT = %d, want 1; screen:\n%s", m.Main[auditAuxResult], screen(m))
	}
}

func exists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

// screen renders the 40x24 text page for test diagnostics.
func screen(m *Memory) string {
	var out []byte
	for row := 0; row < 24; row++ {
		base := 0x400 + (row&7)*0x80 + (row>>3)*0x28
		line := make([]byte, 40)
		for col := 0; col < 40; col++ {
			ch := m.Main[base+col] & 0x7F
			if ch < 0x20 {
				ch += 0x40
			}
			line[col] = ch
		}
		out = append(out, line...)
		out = append(out, '\n')
	}
	return string(out)
}
