package main

import (
	"bufio"
	"bytes"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

const (
	defaultService      = "filter-chain.service"
	defaultEQSink       = "effect_input.sundara_silver_eq"
	defaultOutputSink   = "alsa_output.usb-R__DE_RODECaster_Pro_II_GV0067720-00.pro-output-1"
	defaultActiveConfig = "pipewire/filter-chain.conf.d/sundara-silver-eq.conf"
	defaultPresetsDir   = "audio-eq/presets"
)

type Config struct {
	ActiveConfig string
	PresetsDir   string
}

type Preset struct {
	ID         string
	Name       string
	Headphone  string
	Target     string
	EQSink     string
	OutputSink string
	Service    string
	Path       string
}

type Stream struct {
	ID       string
	App      string
	Media    string
	Node     string
	SinkID   string
	SinkName string
}

type Status struct {
	Service     string
	EQSink      string
	DefaultSink string
	Active      Preset
}

type commandError struct {
	Command string
	Output  string
	Err     error
}

func (e commandError) Error() string {
	output := strings.TrimSpace(e.Output)
	if output == "" {
		return fmt.Sprintf("%s: %v", e.Command, e.Err)
	}
	return fmt.Sprintf("%s: %v\n%s", e.Command, e.Err, output)
}

func main() {
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintf(os.Stderr, "audio-eq: %v\n", err)
		os.Exit(1)
	}
}

func run(args []string) error {
	cfg := defaultConfig()
	if len(args) == 0 {
		return runTUI(cfg)
	}

	switch args[0] {
	case "tui":
		return runTUI(cfg)
	case "list", "presets":
		return listPresets(cfg)
	case "apply", "use":
		if len(args) != 2 {
			return errors.New("usage: audio-eq apply <preset-id-or-name>")
		}
		return applyPresetByName(cfg, args[1])
	case "status":
		return printStatus(cfg)
	case "streams":
		return printStreams(cfg)
	case "move":
		if len(args) != 3 {
			return errors.New("usage: audio-eq move <sink-input-id> <eq|direct>")
		}
		return moveStreamByName(cfg, args[1], args[2])
	case "on", "start", "restart":
		active, err := activePreset(cfg)
		if err != nil {
			return err
		}
		if err := restartEQ(active); err != nil {
			return err
		}
		fmt.Printf("EQ available: %s\n", active.EQSink)
		return nil
	case "all":
		if err := routeAll(cfg); err != nil {
			return err
		}
		active, _ := activePreset(cfg)
		fmt.Printf("Default sink: %s\n", active.EQSink)
		return nil
	case "direct", "selective":
		if err := routeDirect(cfg); err != nil {
			return err
		}
		active, _ := activePreset(cfg)
		fmt.Printf("Default sink: %s\n", active.OutputSink)
		return nil
	case "off", "stop":
		if err := stopEQ(cfg); err != nil {
			return err
		}
		fmt.Println("EQ disabled")
		return nil
	case "-h", "--help", "help":
		printUsage(os.Stdout)
		return nil
	default:
		printUsage(os.Stderr)
		return fmt.Errorf("unknown command: %s", args[0])
	}
}

func printUsage(w io.Writer) {
	fmt.Fprintln(w, "Usage: audio-eq [tui|status|list|apply|streams|move|restart|all|direct|off]")
	fmt.Fprintln(w)
	fmt.Fprintln(w, "Commands:")
	fmt.Fprintln(w, "  audio-eq                 open the interactive TUI")
	fmt.Fprintln(w, "  audio-eq list            list versioned EQ presets")
	fmt.Fprintln(w, "  audio-eq apply <preset>  copy a preset to the active PipeWire filter-chain config and restart")
	fmt.Fprintln(w, "  audio-eq status          show service, sink, and active preset state")
	fmt.Fprintln(w, "  audio-eq streams         list current app audio streams")
	fmt.Fprintln(w, "  audio-eq move <id> eq    move an app stream through the EQ sink")
	fmt.Fprintln(w, "  audio-eq move <id> direct")
	fmt.Fprintln(w, "  audio-eq all             set the default sink to the EQ")
	fmt.Fprintln(w, "  audio-eq direct          set the default sink to the physical output")
	fmt.Fprintln(w, "  audio-eq restart         restart the PipeWire filter-chain service")
	fmt.Fprintln(w, "  audio-eq off             stop the EQ service")
}

func defaultConfig() Config {
	configHome := os.Getenv("XDG_CONFIG_HOME")
	if configHome == "" {
		configHome = filepath.Join(homeDir(), ".config")
	}

	active := os.Getenv("AUDIO_EQ_ACTIVE_CONFIG")
	if active == "" {
		active = filepath.Join(configHome, defaultActiveConfig)
	}

	presets := os.Getenv("AUDIO_EQ_PRESETS_DIR")
	if presets == "" {
		presets = filepath.Join(configHome, defaultPresetsDir)
	}

	return Config{ActiveConfig: active, PresetsDir: presets}
}

func homeDir() string {
	if home := os.Getenv("HOME"); home != "" {
		return home
	}
	return "."
}

func listPresets(cfg Config) error {
	presets, err := loadPresets(cfg)
	if err != nil {
		return err
	}
	if len(presets) == 0 {
		return fmt.Errorf("no presets found in %s", cfg.PresetsDir)
	}

	active, _ := activePreset(cfg)
	for _, preset := range presets {
		marker := " "
		if active.ID != "" && preset.ID == active.ID {
			marker = "*"
		}
		fmt.Printf("%s %-36s  %-28s  %s\n", marker, preset.ID, preset.Headphone, preset.Name)
	}
	return nil
}

func applyPresetByName(cfg Config, name string) error {
	preset, err := findPreset(cfg, name)
	if err != nil {
		return err
	}
	if err := applyPreset(cfg, preset); err != nil {
		return err
	}

	fmt.Printf("Active preset: %s\n", preset.DisplayName())
	fmt.Printf("EQ sink: %s\n", preset.EQSink)
	return nil
}

func applyPreset(cfg Config, preset Preset) error {
	wasDefault, _ := defaultSink()
	oldActive, _ := activePreset(cfg)
	eqStreams := currentStreamsOnSink(oldActive.EQSink)

	if err := copyFileAtomic(preset.Path, cfg.ActiveConfig); err != nil {
		return err
	}
	if err := restartEQ(preset); err != nil {
		return err
	}
	if wasDefault == oldActive.EQSink || wasDefault == preset.EQSink {
		_ = setDefaultSink(preset.EQSink)
	}
	return moveStreams(eqStreams, preset.EQSink)
}

func printStatus(cfg Config) error {
	status, err := collectStatus(cfg)
	if err != nil {
		return err
	}
	fmt.Printf("Service: %s\n", status.Service)
	if sinkExists(status.EQSink) {
		fmt.Printf("EQ sink: available (%s)\n", status.EQSink)
	} else {
		fmt.Printf("EQ sink: missing (%s)\n", status.EQSink)
	}
	fmt.Printf("Default sink: %s\n", status.DefaultSink)
	if status.Active.ID != "" {
		fmt.Printf("Active preset: %s\n", status.Active.DisplayName())
	}
	if status.Active.OutputSink != "" {
		fmt.Printf("Physical sink: %s\n", status.Active.OutputSink)
	}
	return nil
}

func printStreams(cfg Config) error {
	active, err := activePreset(cfg)
	if err != nil {
		return err
	}
	streams, err := listStreams()
	if err != nil {
		return err
	}
	if len(streams) == 0 {
		fmt.Println("No active sink inputs.")
		return nil
	}
	for _, stream := range streams {
		route := "other"
		if stream.SinkName == active.EQSink {
			route = "eq"
		} else if stream.SinkName == active.OutputSink {
			route = "direct"
		}
		fmt.Printf("%-5s %-8s %-32s %-44s %s\n", stream.ID, route, stream.App, stream.Media, stream.SinkName)
	}
	return nil
}

func moveStreamByName(cfg Config, id, route string) error {
	active, err := activePreset(cfg)
	if err != nil {
		return err
	}
	switch route {
	case "eq":
		if err := ensureEQSink(active); err != nil {
			return err
		}
		return moveStreamToSink(id, active.EQSink)
	case "direct", "target":
		return moveStreamToSink(id, active.OutputSink)
	default:
		return fmt.Errorf("unknown stream route %q; use eq or direct", route)
	}
}

func routeAll(cfg Config) error {
	active, err := activePreset(cfg)
	if err != nil {
		return err
	}
	if err := restartEQ(active); err != nil {
		return err
	}
	return setDefaultSink(active.EQSink)
}

func routeDirect(cfg Config) error {
	active, err := activePreset(cfg)
	if err != nil {
		return err
	}
	if active.OutputSink == "" {
		return errors.New("active preset does not declare a physical output sink")
	}
	if !sinkExists(active.OutputSink) {
		return fmt.Errorf("physical sink is missing: %s", active.OutputSink)
	}
	return setDefaultSink(active.OutputSink)
}

func stopEQ(cfg Config) error {
	active, err := activePreset(cfg)
	if err != nil {
		return err
	}
	current, _ := defaultSink()
	if current == active.EQSink && active.OutputSink != "" && sinkExists(active.OutputSink) {
		_ = setDefaultSink(active.OutputSink)
	}
	_, err = runCommand("systemctl", "--user", "stop", active.Service)
	return err
}

func collectStatus(cfg Config) (Status, error) {
	active, err := activePreset(cfg)
	if err != nil {
		return Status{}, err
	}
	service := "inactive"
	if commandOK("systemctl", "--user", "is-active", "--quiet", active.Service) {
		service = "active"
	}
	def, _ := defaultSink()
	return Status{Service: service, EQSink: active.EQSink, DefaultSink: def, Active: active}, nil
}

func activePreset(cfg Config) (Preset, error) {
	preset, err := parsePresetFile(cfg.ActiveConfig)
	if err != nil {
		if os.IsNotExist(err) {
			preset = Preset{
				ID:         "active",
				Name:       "Active EQ",
				EQSink:     defaultEQSink,
				OutputSink: defaultOutputSink,
				Service:    defaultService,
				Path:       cfg.ActiveConfig,
			}
			return preset, nil
		}
		return Preset{}, err
	}
	fillPresetDefaults(&preset)
	return preset, nil
}

func loadPresets(cfg Config) ([]Preset, error) {
	entries, err := os.ReadDir(cfg.PresetsDir)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil
		}
		return nil, err
	}

	var presets []Preset
	for _, entry := range entries {
		if entry.IsDir() || filepath.Ext(entry.Name()) != ".conf" {
			continue
		}
		preset, err := parsePresetFile(filepath.Join(cfg.PresetsDir, entry.Name()))
		if err != nil {
			return nil, err
		}
		fillPresetDefaults(&preset)
		presets = append(presets, preset)
	}

	sort.Slice(presets, func(i, j int) bool {
		a := strings.ToLower(presets[i].Headphone + presets[i].Name + presets[i].ID)
		b := strings.ToLower(presets[j].Headphone + presets[j].Name + presets[j].ID)
		return a < b
	})
	return presets, nil
}

func findPreset(cfg Config, name string) (Preset, error) {
	presets, err := loadPresets(cfg)
	if err != nil {
		return Preset{}, err
	}
	needle := strings.ToLower(name)
	for _, preset := range presets {
		candidates := []string{
			preset.ID,
			preset.Name,
			filepath.Base(preset.Path),
			strings.TrimSuffix(filepath.Base(preset.Path), filepath.Ext(preset.Path)),
		}
		for _, candidate := range candidates {
			if strings.ToLower(candidate) == needle {
				return preset, nil
			}
		}
	}
	return Preset{}, fmt.Errorf("preset not found: %s", name)
}

func parsePresetFile(path string) (Preset, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return Preset{}, err
	}

	preset := Preset{
		ID:      strings.TrimSuffix(filepath.Base(path), filepath.Ext(path)),
		Name:    strings.TrimSuffix(filepath.Base(path), filepath.Ext(path)),
		Service: defaultService,
		Path:    path,
	}

	scanner := bufio.NewScanner(bytes.NewReader(data))
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if !strings.HasPrefix(line, "#") {
			continue
		}
		line = strings.TrimSpace(strings.TrimPrefix(line, "#"))
		if !strings.HasPrefix(line, "audio-eq-") {
			continue
		}
		key, value, ok := strings.Cut(line, "=")
		if !ok {
			continue
		}
		key = strings.TrimSpace(strings.TrimPrefix(key, "audio-eq-"))
		value = strings.TrimSpace(value)
		switch key {
		case "id":
			preset.ID = value
		case "name":
			preset.Name = value
		case "headphone":
			preset.Headphone = value
		case "target":
			preset.Target = value
		case "eq-sink":
			preset.EQSink = value
		case "output-sink":
			preset.OutputSink = value
		case "service":
			preset.Service = value
		}
	}
	if err := scanner.Err(); err != nil {
		return Preset{}, err
	}

	inferPipeWireFields(&preset, data)
	fillPresetDefaults(&preset)
	return preset, nil
}

func inferPipeWireFields(preset *Preset, data []byte) {
	if preset.EQSink == "" {
		nodeRE := regexp.MustCompile(`node\.name\s*=\s*"([^"]+)"`)
		matches := nodeRE.FindAllSubmatch(data, -1)
		for _, match := range matches {
			name := string(match[1])
			if strings.Contains(name, "effect_input") {
				preset.EQSink = name
				break
			}
		}
		if preset.EQSink == "" && len(matches) > 0 {
			preset.EQSink = string(matches[0][1])
		}
	}

	if preset.OutputSink == "" {
		targetRE := regexp.MustCompile(`target\.object\s*=\s*"([^"]+)"`)
		if match := targetRE.FindSubmatch(data); len(match) == 2 {
			preset.OutputSink = string(match[1])
		}
	}
}

func fillPresetDefaults(preset *Preset) {
	if preset.ID == "" {
		preset.ID = strings.TrimSuffix(filepath.Base(preset.Path), filepath.Ext(preset.Path))
	}
	if preset.Name == "" {
		preset.Name = preset.ID
	}
	if preset.Service == "" {
		preset.Service = defaultService
	}
	if preset.EQSink == "" {
		preset.EQSink = defaultEQSink
	}
	if preset.OutputSink == "" {
		preset.OutputSink = defaultOutputSink
	}
}

func (preset Preset) DisplayName() string {
	if preset.Headphone == "" {
		return preset.Name
	}
	if preset.Name == "" {
		return preset.Headphone
	}
	return preset.Headphone + " - " + preset.Name
}

func copyFileAtomic(src, dst string) error {
	data, err := os.ReadFile(src)
	if err != nil {
		return err
	}
	if err := os.MkdirAll(filepath.Dir(dst), 0755); err != nil {
		return err
	}
	tmp := dst + ".tmp"
	if err := os.WriteFile(tmp, data, 0644); err != nil {
		return err
	}
	return os.Rename(tmp, dst)
}

func restartEQ(preset Preset) error {
	if _, err := runCommand("systemctl", "--user", "daemon-reload"); err != nil {
		// A daemon reload is useful after changing managed units, but not required for
		// a normal preset switch.
		_ = err
	}
	if _, err := runCommand("systemctl", "--user", "restart", preset.Service); err != nil {
		return err
	}
	if !waitForSink(preset.EQSink, 5*time.Second) {
		logs, _ := runCommand("journalctl", "--user", "-u", preset.Service, "-n", "20", "--no-pager")
		return fmt.Errorf("EQ sink did not appear: %s\n%s", preset.EQSink, strings.TrimSpace(logs))
	}
	return nil
}

func waitForSink(name string, timeout time.Duration) bool {
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		if sinkExists(name) {
			return true
		}
		time.Sleep(100 * time.Millisecond)
	}
	return false
}

func sinkExists(name string) bool {
	sinks, err := sinkNames()
	if err != nil {
		return false
	}
	for _, sink := range sinks {
		if sink == name {
			return true
		}
	}
	return false
}

func sinkNames() ([]string, error) {
	out, err := runCommand("pactl", "list", "short", "sinks")
	if err != nil {
		return nil, err
	}
	var sinks []string
	scanner := bufio.NewScanner(strings.NewReader(out))
	for scanner.Scan() {
		fields := strings.Fields(scanner.Text())
		if len(fields) >= 2 {
			sinks = append(sinks, fields[1])
		}
	}
	return sinks, scanner.Err()
}

func sinkIDMap() (map[string]string, error) {
	out, err := runCommand("pactl", "list", "short", "sinks")
	if err != nil {
		return nil, err
	}
	sinks := make(map[string]string)
	scanner := bufio.NewScanner(strings.NewReader(out))
	for scanner.Scan() {
		fields := strings.Fields(scanner.Text())
		if len(fields) >= 2 {
			sinks[fields[0]] = fields[1]
		}
	}
	return sinks, scanner.Err()
}

func defaultSink() (string, error) {
	out, err := runCommand("pactl", "get-default-sink")
	return strings.TrimSpace(out), err
}

func setDefaultSink(name string) error {
	_, err := runCommand("pactl", "set-default-sink", name)
	return err
}

func moveStream(id, sink string) error {
	if sink == "" {
		return errors.New("missing destination sink")
	}
	_, err := runCommand("pactl", "move-sink-input", id, sink)
	return err
}

func ensureEQSink(preset Preset) error {
	if sinkExists(preset.EQSink) {
		return nil
	}
	return restartEQ(preset)
}

func moveStreamToSink(id, sink string) error {
	if sink == "" {
		return errors.New("missing destination sink")
	}

	var lastErr error
	deadline := time.Now().Add(2 * time.Second)
	for {
		lastErr = moveStream(id, sink)
		if lastErr == nil && waitForStreamOnSink(id, sink, 350*time.Millisecond) {
			return nil
		}
		if time.Now().After(deadline) {
			break
		}
		time.Sleep(100 * time.Millisecond)
	}

	if lastErr != nil {
		return lastErr
	}
	return fmt.Errorf("stream %s did not attach to %s", id, sink)
}

func waitForStreamOnSink(id, sink string, timeout time.Duration) bool {
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		if streamOnSink(id, sink) {
			return true
		}
		time.Sleep(50 * time.Millisecond)
	}
	return streamOnSink(id, sink)
}

func streamOnSink(id, sink string) bool {
	streams, err := listStreams()
	if err != nil {
		return false
	}
	for _, stream := range streams {
		if stream.ID == id {
			return stream.SinkName == sink
		}
	}
	return false
}

func currentStreamsOnSink(sink string) []Stream {
	if sink == "" {
		return nil
	}
	streams, err := listStreams()
	if err != nil {
		return nil
	}
	return streamsOnSink(streams, sink)
}

func streamsOnSink(streams []Stream, sink string) []Stream {
	if sink == "" {
		return nil
	}
	matches := make([]Stream, 0, len(streams))
	for _, stream := range streams {
		if stream.SinkName == sink {
			matches = append(matches, stream)
		}
	}
	return matches
}

func moveStreams(streams []Stream, sink string) error {
	if len(streams) == 0 {
		return nil
	}

	var errs []error
	for _, stream := range streams {
		if stream.ID == "" {
			continue
		}
		if err := moveStreamToSink(stream.ID, sink); err != nil {
			errs = append(errs, fmt.Errorf("%s: %w", stream.App, err))
		}
	}
	if len(errs) > 0 {
		return fmt.Errorf("preset applied, but failed to restore some EQ stream routes: %w", errors.Join(errs...))
	}
	return nil
}

func listStreams() ([]Stream, error) {
	sinks, err := sinkIDMap()
	if err != nil {
		return nil, err
	}
	out, err := runCommand("pactl", "list", "sink-inputs")
	if err != nil {
		return nil, err
	}

	var streams []Stream
	var current *Stream
	scanner := bufio.NewScanner(strings.NewReader(out))
	for scanner.Scan() {
		line := scanner.Text()
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(trimmed, "Sink Input #") {
			if current != nil {
				current.SinkName = sinks[current.SinkID]
				streams = append(streams, *current)
			}
			current = &Stream{ID: strings.TrimPrefix(trimmed, "Sink Input #")}
			continue
		}
		if current == nil {
			continue
		}
		if strings.HasPrefix(trimmed, "Sink:") {
			current.SinkID = strings.TrimSpace(strings.TrimPrefix(trimmed, "Sink:"))
			continue
		}
		if key, value, ok := parsePactlProperty(trimmed); ok {
			switch key {
			case "application.name":
				current.App = value
			case "media.name":
				current.Media = value
			case "node.name":
				current.Node = value
			}
		}
	}
	if current != nil {
		current.SinkName = sinks[current.SinkID]
		streams = append(streams, *current)
	}
	if err := scanner.Err(); err != nil {
		return nil, err
	}

	for i := range streams {
		if streams[i].App == "" {
			streams[i].App = streams[i].Node
		}
		if streams[i].App == "" {
			streams[i].App = "unknown"
		}
		if streams[i].Media == "" {
			streams[i].Media = "-"
		}
	}
	return streams, nil
}

func parsePactlProperty(line string) (string, string, bool) {
	key, value, ok := strings.Cut(line, "=")
	if !ok {
		return "", "", false
	}
	key = strings.TrimSpace(key)
	value = strings.TrimSpace(value)
	value = strings.Trim(value, `"`)
	return key, value, true
}

func runCommand(name string, args ...string) (string, error) {
	cmd := exec.Command(name, args...)
	out, err := cmd.CombinedOutput()
	if err != nil {
		return string(out), commandError{
			Command: name + " " + strings.Join(args, " "),
			Output:  string(out),
			Err:     err,
		}
	}
	return string(out), nil
}

func commandOK(name string, args ...string) bool {
	cmd := exec.Command(name, args...)
	return cmd.Run() == nil
}

type activeTab int

const (
	presetsTab activeTab = iota
	streamsTab
)

type tuiModel struct {
	cfg Config

	width  int
	height int
	ready  bool
	tab    activeTab

	presetIndex int
	presetTop   int
	streamIndex int
	streamTop   int

	presets []Preset
	streams []Stream
	status  Status

	busy         string
	message      string
	messageIsErr bool
}

type refreshMsg struct {
	presets []Preset
	streams []Stream
	status  Status
	err     error
}

type actionMsg struct {
	label string
	err   error
}

var (
	colorText    = lipgloss.Color("#cdd6f4")
	colorMuted   = lipgloss.Color("#a6adc8")
	colorSubtle  = lipgloss.Color("#6c7086")
	colorSurface = lipgloss.Color("#313244")
	colorPanel   = lipgloss.Color("#45475a")
	colorMauve   = lipgloss.Color("#cba6f7")
	colorBlue    = lipgloss.Color("#89b4fa")
	colorGreen   = lipgloss.Color("#a6e3a1")
	colorPeach   = lipgloss.Color("#fab387")
	colorRed     = lipgloss.Color("#f38ba8")

	appStyle      = lipgloss.NewStyle().Padding(1, 2)
	titleStyle    = lipgloss.NewStyle().Bold(true).Foreground(colorMauve)
	subtitleStyle = lipgloss.NewStyle().Foreground(colorMuted)
	mutedStyle    = lipgloss.NewStyle().Foreground(colorMuted)
	subtleStyle   = lipgloss.NewStyle().Foreground(colorSubtle)

	panelStyle = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(colorPanel).
			Padding(0, 1)
	activePanelStyle = panelStyle.BorderForeground(colorMauve)

	tabStyle = lipgloss.NewStyle().
			Padding(0, 2).
			Foreground(colorMuted).
			Border(lipgloss.NormalBorder(), false, false, true, false).
			BorderForeground(colorPanel)
	activeTabStyle = tabStyle.
			Foreground(colorText).
			Bold(true).
			BorderForeground(colorMauve)

	selectedRowStyle = lipgloss.NewStyle().
				Foreground(colorText).
				Background(colorSurface).
				Bold(true)
	rowStyle = lipgloss.NewStyle().Foreground(colorText)

	keyStyle   = lipgloss.NewStyle().Foreground(colorMauve).Bold(true)
	errorStyle = lipgloss.NewStyle().Foreground(colorRed)
	okStyle    = lipgloss.NewStyle().Foreground(colorGreen)
)

func runTUI(cfg Config) error {
	_, err := tea.NewProgram(newTUIModel(cfg), tea.WithAltScreen()).Run()
	return err
}

func newTUIModel(cfg Config) tuiModel {
	return tuiModel{
		cfg:    cfg,
		width:  100,
		height: 32,
	}
}

func (m tuiModel) Init() tea.Cmd {
	return loadTUIDataCmd(m.cfg)
}

func (m tuiModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		m.ready = true
		m.clampSelections()
		return m, nil
	case refreshMsg:
		m.presets = msg.presets
		m.streams = msg.streams
		m.status = msg.status
		m.ready = true
		m.clampSelections()
		if msg.err != nil {
			m.message = msg.err.Error()
			m.messageIsErr = true
		}
		return m, nil
	case actionMsg:
		m.busy = ""
		if msg.err != nil {
			m.message = msg.err.Error()
			m.messageIsErr = true
		} else {
			m.message = msg.label
			m.messageIsErr = false
		}
		return m, loadTUIDataCmd(m.cfg)
	case tea.KeyMsg:
		if msg.String() == "ctrl+c" || msg.String() == "q" {
			return m, tea.Quit
		}
		if m.busy != "" {
			return m, nil
		}

		switch msg.String() {
		case "tab", "right", "l":
			m.nextTab()
		case "left", "h":
			m.previousTab()
		case "up", "k":
			m.moveSelection(-1)
		case "down", "j":
			m.moveSelection(1)
		case "pgup", "b":
			m.moveSelection(-m.pageSize())
		case "pgdown", "f":
			m.moveSelection(m.pageSize())
		case "home", "g":
			m.moveToStart()
		case "end", "G":
			m.moveToEnd()
		case "enter":
			return m.startPresetApply()
		case "r", "R":
			return m.startRestart()
		case "a":
			return m.startRouteAll()
		case "d":
			return m.startDirectAction()
		case "e":
			return m.startMoveStreamToEQ()
		case "o", "x":
			return m.startStop()
		}
	}
	return m, nil
}

func (m tuiModel) View() string {
	if !m.ready {
		return appStyle.Render(titleStyle.Render("Audio EQ Manager") + "\n\n" + mutedStyle.Render("Loading audio graph..."))
	}

	width := maxInt(48, m.width-4)
	height := maxInt(18, m.height-2)

	header := m.renderHeader(width)
	summary := m.renderSummary(width)
	tabs := m.renderTabs(width)
	footer := m.renderFooter(width)
	bodyHeight := height - lipgloss.Height(header) - lipgloss.Height(summary) - lipgloss.Height(tabs) - lipgloss.Height(footer) - 2
	body := m.renderBody(width, maxInt(8, bodyHeight))

	content := lipgloss.JoinVertical(
		lipgloss.Left,
		header,
		summary,
		tabs,
		body,
		footer,
	)
	return appStyle.Width(m.width).Height(m.height).Render(content)
}

func loadTUIDataCmd(cfg Config) tea.Cmd {
	return func() tea.Msg {
		var issues []string

		presets, err := loadPresets(cfg)
		if err != nil {
			issues = append(issues, "presets: "+err.Error())
		}

		streams, err := listStreams()
		if err != nil {
			issues = append(issues, "streams: "+err.Error())
		}

		status, err := collectStatus(cfg)
		if err != nil {
			issues = append(issues, "status: "+err.Error())
		}

		var joinedErr error
		if len(issues) > 0 {
			joinedErr = errors.New(strings.Join(issues, "; "))
		}
		return refreshMsg{presets: presets, streams: streams, status: status, err: joinedErr}
	}
}

func actionCmd(label string, fn func() error) tea.Cmd {
	return func() tea.Msg {
		return actionMsg{label: label, err: fn()}
	}
}

func (m tuiModel) renderHeader(width int) string {
	title := titleStyle.Render("Audio EQ Manager")
	status := lipgloss.JoinHorizontal(
		lipgloss.Center,
		serviceBadge(m.status.Service),
		" ",
		routeBadge(m.defaultRoute()),
	)
	line := joinSides(title, status, width)
	subtitle := subtitleStyle.Width(width).Render("PipeWire headphone EQ profiles and per-app routing")
	return lipgloss.JoinVertical(lipgloss.Left, line, subtitle)
}

func (m tuiModel) renderSummary(width int) string {
	active := m.status.Active
	left := summaryCard("Active preset", active.DisplayName(), active.Target, (width-1)*58/100)
	right := summaryCard(
		"Routing",
		"Default: "+displaySink(emptyAs(m.status.DefaultSink, "-")),
		"Output: "+displaySink(active.OutputSink),
		width-lipgloss.Width(left)-1,
	)
	if width < 90 {
		return lipgloss.JoinVertical(
			lipgloss.Left,
			summaryCard("Active preset", active.DisplayName(), active.Target, width),
			summaryCard("Routing", "Default: "+displaySink(emptyAs(m.status.DefaultSink, "-")), "Output: "+displaySink(active.OutputSink), width),
		)
	}
	return lipgloss.JoinHorizontal(lipgloss.Top, left, " ", right)
}

func (m tuiModel) renderTabs(width int) string {
	presetLabel := fmt.Sprintf("Presets %d", len(m.presets))
	streamLabel := fmt.Sprintf("Streams %d", len(m.streams))

	presetStyle := tabStyle
	streamStyle := tabStyle
	if m.tab == presetsTab {
		presetStyle = activeTabStyle
	} else {
		streamStyle = activeTabStyle
	}

	tabs := lipgloss.JoinHorizontal(
		lipgloss.Bottom,
		presetStyle.Render(presetLabel),
		streamStyle.Render(streamLabel),
	)
	return lipgloss.NewStyle().Width(width).Render(tabs)
}

func (m tuiModel) renderBody(width, height int) string {
	if width < 88 {
		return lipgloss.JoinVertical(
			lipgloss.Left,
			m.renderListPanel(width, maxInt(8, height*58/100)),
			m.renderDetailPanel(width, maxInt(8, height-height*58/100)),
		)
	}

	listWidth := clampInt(width*58/100, 46, width-34)
	detailWidth := width - listWidth - 1
	return lipgloss.JoinHorizontal(
		lipgloss.Top,
		m.renderListPanel(listWidth, height),
		" ",
		m.renderDetailPanel(detailWidth, height),
	)
}

func (m tuiModel) renderListPanel(width, height int) string {
	title := "Presets"
	body := m.renderPresetList(panelContentWidth(width), panelBodyHeight(height))
	if m.tab == streamsTab {
		title = "Streams"
		body = m.renderStreamList(panelContentWidth(width), panelBodyHeight(height))
	}
	return renderPanel(title, body, width, height, true)
}

func (m tuiModel) renderDetailPanel(width, height int) string {
	title := "Preset details"
	body := m.renderPresetDetails(panelContentWidth(width), panelBodyHeight(height))
	if m.tab == streamsTab {
		title = "Stream details"
		body = m.renderStreamDetails(panelContentWidth(width), panelBodyHeight(height))
	}
	return renderPanel(title, body, width, height, false)
}

func (m tuiModel) renderPresetList(width, height int) string {
	if len(m.presets) == 0 {
		return emptyState(width, "No presets found", "Add filter-chain profiles under ~/.config/audio-eq/presets.")
	}

	m.ensurePresetVisible(height)
	end := minInt(len(m.presets), m.presetTop+height)
	var rows []string
	for i := m.presetTop; i < end; i++ {
		preset := m.presets[i]
		activeMark := " "
		if preset.ID == m.status.Active.ID {
			activeMark = "*"
		}
		line := fmt.Sprintf(
			"%s %-22s %s",
			activeMark,
			truncate(preset.Name, 22),
			subtleStyle.Render(truncate(preset.Headphone, maxInt(8, width-26))),
		)
		rows = append(rows, styledRow(line, width, i == m.presetIndex))
	}
	if hint := scrollHint(m.presetTop, end, len(m.presets), width); hint != "" {
		rows = append(rows, hint)
	}
	return lipgloss.JoinVertical(lipgloss.Left, rows...)
}

func (m tuiModel) renderStreamList(width, height int) string {
	if len(m.streams) == 0 {
		return emptyState(width, "No active audio streams", "Start playback, then press r to refresh after routing changes.")
	}

	m.ensureStreamVisible(height)
	end := minInt(len(m.streams), m.streamTop+height)
	var rows []string
	for i := m.streamTop; i < end; i++ {
		stream := m.streams[i]
		route := m.streamRoute(stream)
		routeText := routeLabel(route)
		appWidth := maxInt(10, width-lipgloss.Width(routeText)-12)
		line := lipgloss.JoinHorizontal(
			lipgloss.Center,
			subtleStyle.Render(padTruncate(stream.ID, 5)),
			" ",
			routeText,
			" ",
			truncate(stream.App, appWidth),
		)
		rows = append(rows, styledRow(line, width, i == m.streamIndex))
		if height > 6 {
			rows = append(rows, rowStyle.Width(width).Render("      "+subtleStyle.Render(truncate(stream.Media, maxInt(4, width-12)))))
		}
	}
	if hint := scrollHint(m.streamTop, end, len(m.streams), width); hint != "" {
		rows = append(rows, hint)
	}
	return lipgloss.JoinVertical(lipgloss.Left, rows...)
}

func (m tuiModel) renderPresetDetails(width, height int) string {
	preset, ok := m.selectedPreset()
	if !ok {
		return emptyState(width, "No preset selected", "Add a preset to make it available here.")
	}

	status := mutedStyle.Render("available")
	if preset.ID == m.status.Active.ID {
		status = okStyle.Render("active")
	}

	lines := []string{
		titleStyle.Render(truncate(preset.DisplayName(), width)),
		"",
		keyValueStyled("State", status, width),
		keyValue("Target", preset.Target, width),
		keyValue("EQ sink", displaySink(preset.EQSink), width),
		keyValue("Output", displaySink(preset.OutputSink), width),
		keyValue("Service", preset.Service, width),
		"",
		subtitleStyle.Render("Actions"),
		helpLine("Enter", "apply preset"),
		helpLine("a", "route all apps through EQ"),
		helpLine("d", "default output to physical sink"),
		helpLine("r", "restart filter-chain"),
	}
	return fitLines(lines, width, height)
}

func (m tuiModel) renderStreamDetails(width, height int) string {
	stream, ok := m.selectedStream()
	if !ok {
		return emptyState(width, "No stream selected", "Open the Streams tab while audio is playing.")
	}

	lines := []string{
		titleStyle.Render(truncate(stream.App, width)),
		"",
		keyValueStyled("Route", routeLabel(m.streamRoute(stream)), width),
		keyValue("Media", stream.Media, width),
		keyValue("Sink", displaySink(stream.SinkName), width),
		keyValue("Sink input", "#"+stream.ID, width),
		"",
		subtitleStyle.Render("Actions"),
		helpLine("e", "move selected stream to EQ"),
		helpLine("d", "move selected stream direct"),
		helpLine("a", "make EQ the default output"),
		helpLine("r", "refresh and restart EQ"),
	}
	return fitLines(lines, width, height)
}

func (m tuiModel) renderFooter(width int) string {
	message := "Ready"
	style := mutedStyle
	if m.busy != "" {
		message = "Working: " + m.busy
		style = lipgloss.NewStyle().Foreground(colorPeach)
	} else if m.message != "" {
		message = m.message
		if m.messageIsErr {
			style = errorStyle
		} else {
			style = okStyle
		}
	}

	keys := lipgloss.JoinHorizontal(
		lipgloss.Center,
		helpLine("Tab", "switch"),
		"  ",
		helpLine("j/k", "move"),
		"  ",
		helpLine("Enter", "apply"),
		"  ",
		helpLine("q", "quit"),
	)
	return lipgloss.JoinVertical(
		lipgloss.Left,
		style.Width(width).Render(truncate(message, width)),
		subtleStyle.Width(width).Render(keys),
	)
}

func (m *tuiModel) nextTab() {
	if m.tab == presetsTab {
		m.tab = streamsTab
	} else {
		m.tab = presetsTab
	}
}

func (m *tuiModel) previousTab() {
	m.nextTab()
}

func (m *tuiModel) moveSelection(delta int) {
	switch m.tab {
	case presetsTab:
		if len(m.presets) == 0 {
			return
		}
		m.presetIndex = clampInt(m.presetIndex+delta, 0, len(m.presets)-1)
		m.ensurePresetVisible(m.pageSize())
	case streamsTab:
		if len(m.streams) == 0 {
			return
		}
		m.streamIndex = clampInt(m.streamIndex+delta, 0, len(m.streams)-1)
		m.ensureStreamVisible(m.pageSize())
	}
}

func (m *tuiModel) moveToStart() {
	if m.tab == presetsTab {
		m.presetIndex = 0
		m.presetTop = 0
		return
	}
	m.streamIndex = 0
	m.streamTop = 0
}

func (m *tuiModel) moveToEnd() {
	if m.tab == presetsTab && len(m.presets) > 0 {
		m.presetIndex = len(m.presets) - 1
		m.ensurePresetVisible(m.pageSize())
		return
	}
	if m.tab == streamsTab && len(m.streams) > 0 {
		m.streamIndex = len(m.streams) - 1
		m.ensureStreamVisible(m.pageSize())
	}
}

func (m *tuiModel) clampSelections() {
	if len(m.presets) == 0 {
		m.presetIndex = 0
		m.presetTop = 0
	} else {
		m.presetIndex = clampInt(m.presetIndex, 0, len(m.presets)-1)
		m.ensurePresetVisible(m.pageSize())
	}

	if len(m.streams) == 0 {
		m.streamIndex = 0
		m.streamTop = 0
	} else {
		m.streamIndex = clampInt(m.streamIndex, 0, len(m.streams)-1)
		m.ensureStreamVisible(m.pageSize())
	}
}

func (m *tuiModel) ensurePresetVisible(rows int) {
	rows = maxInt(1, rows)
	if m.presetIndex < m.presetTop {
		m.presetTop = m.presetIndex
	}
	if m.presetIndex >= m.presetTop+rows {
		m.presetTop = m.presetIndex - rows + 1
	}
	m.presetTop = clampInt(m.presetTop, 0, maxInt(0, len(m.presets)-rows))
}

func (m *tuiModel) ensureStreamVisible(rows int) {
	rows = maxInt(1, rows)
	if m.streamIndex < m.streamTop {
		m.streamTop = m.streamIndex
	}
	if m.streamIndex >= m.streamTop+rows {
		m.streamTop = m.streamIndex - rows + 1
	}
	m.streamTop = clampInt(m.streamTop, 0, maxInt(0, len(m.streams)-rows))
}

func (m tuiModel) pageSize() int {
	bodyHeight := maxInt(8, m.height-16)
	return maxInt(3, panelBodyHeight(bodyHeight)-1)
}

func (m tuiModel) startPresetApply() (tea.Model, tea.Cmd) {
	if m.tab != presetsTab {
		return m, nil
	}
	preset, ok := m.selectedPreset()
	if !ok {
		return m.withMessage("No preset selected", true), nil
	}
	m.busy = "Applying " + preset.Name
	m.message = ""
	return m, actionCmd("Applied "+preset.DisplayName(), func() error {
		return applyPreset(m.cfg, preset)
	})
}

func (m tuiModel) startRestart() (tea.Model, tea.Cmd) {
	active := m.status.Active
	m.busy = "Restarting EQ"
	m.message = ""
	return m, actionCmd("Restarted EQ", func() error {
		return restartEQ(active)
	})
}

func (m tuiModel) startRouteAll() (tea.Model, tea.Cmd) {
	m.busy = "Routing all apps through EQ"
	m.message = ""
	return m, actionCmd("Default output is now the EQ sink", func() error {
		return routeAll(m.cfg)
	})
}

func (m tuiModel) startDirectAction() (tea.Model, tea.Cmd) {
	if m.tab == streamsTab {
		stream, ok := m.selectedStream()
		if !ok {
			return m.withMessage("No stream selected", true), nil
		}
		outputSink := m.status.Active.OutputSink
		m.busy = "Moving " + stream.App + " direct"
		m.message = ""
		return m, actionCmd("Moved "+stream.App+" direct", func() error {
			return moveStreamToSink(stream.ID, outputSink)
		})
	}

	m.busy = "Setting direct default"
	m.message = ""
	return m, actionCmd("Default output is now the physical sink", func() error {
		return routeDirect(m.cfg)
	})
}

func (m tuiModel) startMoveStreamToEQ() (tea.Model, tea.Cmd) {
	if m.tab != streamsTab {
		return m.withMessage("Switch to Streams, then press e to move a selected stream", true), nil
	}
	stream, ok := m.selectedStream()
	if !ok {
		return m.withMessage("No stream selected", true), nil
	}
	active := m.status.Active
	m.busy = "Moving " + stream.App + " to EQ"
	m.message = ""
	return m, actionCmd("Moved "+stream.App+" to EQ", func() error {
		if err := ensureEQSink(active); err != nil {
			return err
		}
		return moveStreamToSink(stream.ID, active.EQSink)
	})
}

func (m tuiModel) startStop() (tea.Model, tea.Cmd) {
	m.busy = "Stopping EQ"
	m.message = ""
	return m, actionCmd("Stopped EQ", func() error {
		return stopEQ(m.cfg)
	})
}

func (m tuiModel) selectedPreset() (Preset, bool) {
	if len(m.presets) == 0 || m.presetIndex < 0 || m.presetIndex >= len(m.presets) {
		return Preset{}, false
	}
	return m.presets[m.presetIndex], true
}

func (m tuiModel) selectedStream() (Stream, bool) {
	if len(m.streams) == 0 || m.streamIndex < 0 || m.streamIndex >= len(m.streams) {
		return Stream{}, false
	}
	return m.streams[m.streamIndex], true
}

func (m tuiModel) withMessage(message string, isErr bool) tuiModel {
	m.message = message
	m.messageIsErr = isErr
	return m
}

func (m tuiModel) streamRoute(stream Stream) string {
	switch stream.SinkName {
	case m.status.Active.EQSink:
		return "eq"
	case m.status.Active.OutputSink:
		return "direct"
	default:
		return "other"
	}
}

func (m tuiModel) defaultRoute() string {
	switch m.status.DefaultSink {
	case m.status.Active.EQSink:
		return "all through EQ"
	case m.status.Active.OutputSink:
		return "selective"
	default:
		return "other default"
	}
}

func summaryCard(title, value, detail string, width int) string {
	textWidth := maxInt(8, width-10)
	body := subtitleStyle.Render(title) + "\n" + titleStyle.Render(truncate(value, textWidth))
	if detail != "" {
		body += "\n" + mutedStyle.Render(truncate(detail, textWidth))
	}
	return panelStyle.Width(maxInt(8, width-4)).Render(body)
}

func renderPanel(title, body string, width, height int, active bool) string {
	style := panelStyle
	if active {
		style = activePanelStyle
	}
	return style.
		Width(panelContentWidth(width)).
		Height(maxInt(1, height-2)).
		Render(subtitleStyle.Render(title) + "\n" + body)
}

func panelContentWidth(width int) int {
	return maxInt(12, width-4)
}

func panelBodyHeight(height int) int {
	return maxInt(3, height-5)
}

func styledRow(line string, width int, selected bool) string {
	if selected {
		return selectedRowStyle.Width(width).Render(line)
	}
	return rowStyle.Width(width).Render(line)
}

func scrollHint(top, end, total, width int) string {
	if total <= 0 {
		return ""
	}
	if top == 0 && end >= total {
		return ""
	}
	value := fmt.Sprintf("%d-%d of %d", minInt(top+1, total), end, total)
	return subtleStyle.Render(strings.Repeat(" ", maxInt(0, width-len(value))) + value)
}

func emptyState(width int, title, detail string) string {
	return lipgloss.JoinVertical(
		lipgloss.Left,
		titleStyle.Render(truncate(title, width)),
		mutedStyle.Render(truncate(detail, width)),
	)
}

func keyValue(key, value string, width int) string {
	if value == "" {
		value = "-"
	}
	label := subtleStyle.Render(padTruncate(key, 10))
	available := maxInt(4, width-lipgloss.Width(label)-4)
	return lipgloss.JoinHorizontal(lipgloss.Top, label, " ", truncate(value, available))
}

func keyValueStyled(key, value string, width int) string {
	if value == "" {
		value = "-"
	}
	label := subtleStyle.Render(padTruncate(key, 10))
	available := maxInt(4, width-lipgloss.Width(label)-4)
	return lipgloss.JoinHorizontal(lipgloss.Top, label, " ", lipgloss.NewStyle().MaxWidth(available).Render(value))
}

func helpLine(key, description string) string {
	return keyStyle.Render(key) + " " + mutedStyle.Render(description)
}

func fitLines(lines []string, width, height int) string {
	if height <= 0 {
		return ""
	}
	if len(lines) > height {
		lines = lines[:height]
	}
	return lipgloss.JoinVertical(lipgloss.Left, lines...)
}

func joinSides(left, right string, width int) string {
	space := width - lipgloss.Width(left) - lipgloss.Width(right)
	if space < 1 {
		return truncate(left, width)
	}
	return left + strings.Repeat(" ", space) + right
}

func serviceBadge(state string) string {
	style := lipgloss.NewStyle().Padding(0, 1).Bold(true)
	if state == "active" {
		return style.Foreground(lipgloss.Color("#11111b")).Background(colorGreen).Render("active")
	}
	return style.Foreground(lipgloss.Color("#11111b")).Background(colorRed).Render("inactive")
}

func routeBadge(route string) string {
	style := lipgloss.NewStyle().Padding(0, 1).Foreground(lipgloss.Color("#11111b")).Bold(true)
	switch route {
	case "all through EQ", "eq":
		return style.Background(colorMauve).Render(route)
	case "selective", "direct":
		return style.Background(colorBlue).Render(route)
	default:
		return style.Background(colorPeach).Render(route)
	}
}

func routeLabel(route string) string {
	switch route {
	case "eq":
		return routeBadge("eq")
	case "direct":
		return routeBadge("direct")
	default:
		return routeBadge("other")
	}
}

func displaySink(name string) string {
	switch {
	case name == "":
		return "-"
	case strings.Contains(name, "RODECaster_Pro_II") && strings.Contains(name, ".pro-output-1"):
		return "RODECaster Pro II Pro 1"
	case strings.Contains(name, "RODECaster_Pro_II") && strings.Contains(name, ".pro-output-0"):
		return "RODECaster Pro II Pro 0"
	case strings.HasPrefix(name, "effect_input."):
		return strings.TrimPrefix(name, "effect_input.") + " (EQ)"
	case strings.HasPrefix(name, "effect_output."):
		return strings.TrimPrefix(name, "effect_output.") + " (EQ output)"
	default:
		return name
	}
}

func emptyAs(value, fallback string) string {
	if strings.TrimSpace(value) == "" {
		return fallback
	}
	return value
}

func padTruncate(value string, width int) string {
	if width <= 0 {
		return ""
	}
	value = truncate(value, width)
	padding := width - len([]rune(value))
	if padding <= 0 {
		return value
	}
	return value + strings.Repeat(" ", padding)
}

func truncate(value string, max int) string {
	runes := []rune(value)
	if len(runes) <= max {
		return value
	}
	if max <= 1 {
		return string(runes[:max])
	}
	return string(runes[:max-1]) + "~"
}

func clampInt(value, minValue, maxValue int) int {
	if value < minValue {
		return minValue
	}
	if value > maxValue {
		return maxValue
	}
	return value
}

func minInt(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func maxInt(a, b int) int {
	if a > b {
		return a
	}
	return b
}
