package main

import (
	"os"
	"path/filepath"
	"testing"
)

func TestParsePresetFileUsesMetadataAndPipeWireFallbacks(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "preset.conf")
	data := `# audio-eq-id = test-preset
# audio-eq-name = Test Preset
# audio-eq-headphone = Test Headphone
# audio-eq-target = Test Target

context.modules = [
    { name = libpipewire-module-filter-chain
        args = {
            capture.props = {
                node.name = "effect_input.test_eq"
            }
            playback.props = {
                target.object = "alsa_output.test"
            }
        }
    }
]
`

	if err := os.WriteFile(path, []byte(data), 0644); err != nil {
		t.Fatal(err)
	}

	preset, err := parsePresetFile(path)
	if err != nil {
		t.Fatal(err)
	}

	if preset.ID != "test-preset" {
		t.Fatalf("ID = %q, want test-preset", preset.ID)
	}
	if preset.Name != "Test Preset" {
		t.Fatalf("Name = %q, want Test Preset", preset.Name)
	}
	if preset.Headphone != "Test Headphone" {
		t.Fatalf("Headphone = %q, want Test Headphone", preset.Headphone)
	}
	if preset.Target != "Test Target" {
		t.Fatalf("Target = %q, want Test Target", preset.Target)
	}
	if preset.EQSink != "effect_input.test_eq" {
		t.Fatalf("EQSink = %q, want effect_input.test_eq", preset.EQSink)
	}
	if preset.OutputSink != "alsa_output.test" {
		t.Fatalf("OutputSink = %q, want alsa_output.test", preset.OutputSink)
	}
	if preset.Service != defaultService {
		t.Fatalf("Service = %q, want %q", preset.Service, defaultService)
	}
}

func TestPadTruncatePadsShortValues(t *testing.T) {
	got := padTruncate("eq", 5)
	want := "eq   "
	if got != want {
		t.Fatalf("padTruncate() = %q, want %q", got, want)
	}
}

func TestDisplaySinkUsesFriendlyRodecasterName(t *testing.T) {
	got := displaySink("alsa_output.usb-R__DE_RODECaster_Pro_II_GV0067720-00.pro-output-1")
	want := "RODECaster Pro II Pro 1"
	if got != want {
		t.Fatalf("displaySink() = %q, want %q", got, want)
	}
}
