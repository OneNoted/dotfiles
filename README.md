# dotfiles

Arch/Hyprland/Niri dotfiles, managed with [chezmoi](https://www.chezmoi.io/) and templated for multi-host deployment.

<!-- TODO: Add a screenshot of the rice here -->
> Screenshot coming soon

## Overview

| Category | Tool(s) |
|---|---|
| WM / Desktop | Hyprland, Niri, ashell |
| Terminal | Kitty |
| Multiplexer | Zellij, Tmux |
| Shell | Fish (primary), Nushell, Zsh |
| Editor | Neovim |
| File Manager | Yazi |
| Shell Prompt | Starship |
| Fuzzy Finder | Television, fzf |
| Shell History | Atuin |
| System Info | Fastfetch, Btop, Onefetch |
| Misc | Eza, Zoxide, Topgrade, Equibop |

## Features

- **Multi-host templating** -- Chezmoi `.tmpl` files use hostname conditionals to adapt configs across machines (currently `aeolus` on Arch with Nvidia and `hephaestus`).

- **Catppuccin Mocha everywhere** -- Consistent theming across Hyprland borders, Kitty, Neovim, Yazi, Btop, Nushell, and HyprPanel.

- **Organized Neovim config** -- Plugins are split into domain-based subdirectories under `lua/plugins/`: `editor/` (completion, harpoon, which-key), `lang/` (Go, Rust, Zig, YAML, JSON), `tools/` (LSP, treesitter, git, formatting, diagnostics, chezmoi integration), and `ui/` (catppuccin, lualine, bufferline, snacks).

- **Kitty + Neovim integration** -- kitty-scrollback.nvim lets you browse terminal scrollback and last command output inside Neovim.

- **Fish shell setup** -- Vi keybindings with custom Television hotkeys: `Ctrl+T` for fuzzy file search, `Ctrl+G` for fuzzy directory jump. `zel` fuzzy-attaches to Zellij sessions via Television. Yazi wrapper (`y`) tracks `cwd` on exit. Also includes eza-based `ls` aliases, zoxide for `cd`, Atuin for history search, and Carapace for completions.

## Installation

```sh
chezmoi init OneNoted/dotfiles
chezmoi apply
```

During `chezmoi init`, you will be prompted for an Atuin sync server address. Leave it empty if you do not use a self-hosted Atuin server.

**Note:** `monitors.conf` is sourced by the Hyprland config but is not tracked in this repo -- it is machine-specific. Create your own at `~/.config/hypr/monitors.conf` after applying.

## Customization

- **Hostname conditionals** -- Search `.tmpl` files for `.chezmoi.hostname` to find host-specific blocks. The main hosts are `aeolus` (Arch + Nvidia GPU setup) and `hephaestus`. Adjust or remove these for your machine. *sorry!*

- **Monitor setup** -- Create `~/.config/hypr/monitors.conf` with your display layout. See the [Hyprland wiki](https://wiki.hypr.land/Configuring/Monitors/) for syntax.

- **Shell preference** -- Fish is the default (set in `.chezmoi.toml.tmpl` as the chezmoi `cd` command shell). Zsh config with Zinit is also included at `dot_zshrc`, and Nushell config lives under `dot_config/nushell/`.

## Structure

```
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
