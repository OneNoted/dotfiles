# Structure

```text
.chezmoi.toml.tmpl          # Chezmoi config -- source dir, shell, data prompts
.chezmoiignore              # Per-host ignore rules
dot_zshrc                   # Zsh config (Zinit plugin manager)
dot_config/
  btop/                     # Btop system monitor
  eza/                      # Eza (ls replacement) theme
  fastfetch/                # System info fetch (templated)
  hypr/                     # Hyprland WM -- main config, keybinds, workspaces
  hyprpanel/                # HyprPanel bar config (templated)
  kitty/                    # Kitty terminal (templated)
  niri/                     # Niri scrolling WM
  nushell/                  # Nushell config + Catppuccin theme
  nvim/                     # Neovim -- lazy.nvim, domain-based plugin dirs
    lua/plugins/
      editor/               #   Completion, harpoon, which-key, flash, mini
      lang/                 #   Go, Rust, Zig, JSON, YAML language support
      tools/                #   LSP, treesitter, git, formatting, linting, chezmoi
      ui/                   #   Catppuccin, lualine, bufferline, snacks, cord
  private_atuin/            # Atuin shell history (templated)
  private_equibop/          # Equibop (Discord client) themes
  private_fish/             # Fish shell config (templated)
  starship.toml             # Starship prompt
  television/               # Television fuzzy finder
  tmux/                     # Tmux config (templated)
  topgrade/                 # Topgrade system updater
  yazi/                     # Yazi file manager + plugins
  zellij/                   # Zellij multiplexer (templated)
```

## Feature notes

- **Multi-host templating** — `.tmpl` files use hostname conditionals to adapt configs across machines.
- **Catppuccin + Ashen theming** — Catppuccin Mocha is the default everywhere; Yazi uses the Ashen flavor.
- **Organized Neovim config** — Plugins split into domain-based subdirectories under `lua/plugins/`.
- **Kitty + Neovim integration** — kitty-scrollback.nvim for terminal scrollback in Neovim.
- **Fish shell setup** — Vi keybindings, Television hotkeys (`Ctrl+T` file search, `Ctrl+G` dir jump), `zel` for fuzzy Zellij session attach, Yazi `cwd` tracking, eza aliases, zoxide, Atuin history, Carapace completions.
