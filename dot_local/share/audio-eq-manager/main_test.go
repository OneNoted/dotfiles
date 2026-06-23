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

func TestPresetListWidthsExpandForLongValues(t *testing.T) {
	presets := []Preset{
		{ID: "short", Headphone: "Short Headphone"},
		{ID: "very-long-preset-identifier-that-needs-room", Headphone: "A longer headphone name than the default column"},
	}

	idWidth, headphoneWidth := presetListWidths(presets)
	if idWidth != len(presets[1].ID) {
		t.Fatalf("idWidth = %d, want %d", idWidth, len(presets[1].ID))
	}
	if headphoneWidth != len(presets[1].Headphone) {
		t.Fatalf("headphoneWidth = %d, want %d", headphoneWidth, len(presets[1].Headphone))
	}
}

func TestStreamsOnSinkFiltersBySinkName(t *testing.T) {
	streams := []Stream{
		{ID: "1", SinkName: "effect_input.test"},
		{ID: "2", SinkName: "alsa_output.test"},
		{ID: "3", SinkName: "effect_input.test"},
	}

	got := streamsOnSink(streams, "effect_input.test")
	if len(got) != 2 {
		t.Fatalf("len(streamsOnSink()) = %d, want 2", len(got))
	}
	if got[0].ID != "1" || got[1].ID != "3" {
		t.Fatalf("streamsOnSink IDs = %q, %q; want 1, 3", got[0].ID, got[1].ID)
	}
}

func TestDisplaySinkUsesFriendlyRodecasterName(t *testing.T) {
	got := displaySink("alsa_output.usb-R__DE_RODECaster_Pro_II_GV0067720-00.pro-output-1")
	want := "RODECaster Pro II Pro 1"
	if got != want {
		t.Fatalf("displaySink() = %q, want %q", got, want)
	}
}
