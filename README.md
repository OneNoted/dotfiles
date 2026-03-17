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

- **Catppuccin + Ashen theming** -- Catppuccin Mocha stays the default across Hyprland, Kitty, Neovim, Btop, Nushell, and HyprPanel, while Yazi uses the Ashen flavor.

- **Organized Neovim config** -- Plugins are split into domain-based subdirectories under `lua/plugins/`: `editor/` (completion, harpoon, which-key), `lang/` (Go, Rust, Zig, YAML, JSON), `tools/` (LSP, treesitter, git, formatting, diagnostics, chezmoi integration), and `ui/` (catppuccin, lualine, bufferline, snacks).

- **Kitty + Neovim integration** -- kitty-scrollback.nvim lets you browse terminal scrollback and last command output inside Neovim.

- **Fish shell setup** -- Vi keybindings with custom Television hotkeys: `Ctrl+T` for fuzzy file search, `Ctrl+G` for fuzzy directory jump. `zel` fuzzy-attaches to Zellij sessions via Television. Yazi wrapper (`y`) tracks `cwd` on exit. Also includes eza-based `ls` aliases, zoxide for `cd`, Atuin for history search, and Carapace for completions.

## Installation

```sh
chezmoi init OneNoted/dotfiles
chezmoi apply
```

During `chezmoi init`, you will be prompted for an Atuin sync server address. Leave it empty if you do not use a self-hosted Atuin server.

Yazi installs its external plugins on first launch from `init.lua`, so there is no separate plugin bootstrap step.

**Note:** `aeolus` tracks its Hyprland monitor layout in `dot_config/hypr/monitors.conf.tmpl`. Other hosts can keep a machine-specific `~/.config/hypr/monitors.conf`.

## Bootstrapping (Arch)

A package manifest and bootstrap helper are included for Arch hosts:

```sh
# print install plan (default mode)
bash bootstrap/bootstrap.sh --plan

# install only the Neovim component
bash bootstrap/nvim.sh --plan

# include optional groups
bash bootstrap/bootstrap.sh --group wm --group nvim --plan

# install on Arch
bash bootstrap/bootstrap.sh --group wm --group nvim --install

# install only Neovim and its config dependencies
bash bootstrap/nvim.sh --install
```

Package data lives in `bootstrap/packages.toml`.

## Validation

Run strict local checks before committing:

```sh
just check
```

To run all configured hooks:

```sh
pre-commit run --all-files
```

## Customization

- **Hostname conditionals** -- Search `.tmpl` files for `.chezmoi.hostname` to find host-specific blocks. The main hosts are `aeolus` (Arch + Nvidia GPU setup) and `hephaestus`. Adjust or remove these for your machine. *sorry!*

- **Monitor setup** -- `aeolus` manages its Hyprland layout in `dot_config/hypr/monitors.conf.tmpl`. For other hosts, either add a hostname branch there or keep a machine-specific `~/.config/hypr/monitors.conf`. See the [Hyprland wiki](https://wiki.hypr.land/Configuring/Monitors/) for syntax.

- **Shell preference** -- Fish is the default (set in `.chezmoi.toml.tmpl` as the chezmoi `cd` command shell). Zsh config with Zinit is also included at `dot_zshrc`, and Nushell config lives under `dot_config/nushell/`.

- **Shared shell core** -- Common aliases and editor environment variables are defined once in `.chezmoidata/shell_core.yaml` and rendered to shell adapters in `dot_config/shared/`.

## Structure

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
