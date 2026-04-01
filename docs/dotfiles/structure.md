# Structure

```text
.chezmoi.toml.tmpl          # Chezmoi config -- source dir, shell, data prompts
.chezmoiignore              # Per-host ignore rules
dot_zshenv                  # Zsh bootstrap -- XDG defaults + ZDOTDIR
.profiles/
  nvim/                     # Extra Neovim profile sources (server/default/nightly)
dot_config/
  doom/                     # Doom user config + profiles
  environment.d/            # User session environment exports
  btop/                     # Btop system monitor
  eza/                      # Eza (ls replacement) theme
  fastfetch/                # System info fetch (templated)
  hypr/                     # Hyprland WM -- main config, keybinds, workspaces
  hyprpanel/                # HyprPanel bar config (templated)
  kitty/                    # Kitty terminal (templated)
  niri/                     # Niri scrolling WM
  nushell/                  # Nushell config + Catppuccin theme
  nvim/                     # Neovim lazy profile source; synced into ~/.config/nvim by nvim-profile
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
  zsh/                      # Zsh interactive config (Zinit plugin manager)
```

## Feature notes

- **Multi-host templating** — `.tmpl` files use hostname conditionals to adapt configs across machines.
- **Catppuccin + Ashen theming** — Catppuccin Mocha is the default everywhere; Yazi uses the Ashen flavor.
- **XDG-first shell environment** — Session-wide XDG vars live in `environment.d`, with matching shell fallbacks and a `ZDOTDIR` bootstrap for Zsh.
- **Managed Doom user config** — Doom user files live in `dot_config/doom/`, with handwritten behavior centered in `config.el` while the upstream framework stays external.
- **Organized Neovim config** — Plugins split into domain-based subdirectories under `lua/plugins/`.
- **Selectable Neovim profiles** — `nvim-profile` persists the active profile in chezmoi config and syncs either `dot_config/nvim/` or one of the `.profiles/nvim/*` trees into `~/.config/nvim`.
- **Kitty + Neovim integration** — kitty-scrollback.nvim for terminal scrollback in Neovim.
- **Fish shell setup** — Vi keybindings, Television hotkeys (`Ctrl+T` file search, `Ctrl+G` dir jump), `zel` for fuzzy Zellij session attach, Yazi `cwd` tracking, eza aliases, zoxide, Atuin history, Carapace completions.
