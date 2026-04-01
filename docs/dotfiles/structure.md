# Structure

```text
.chezmoi.toml.tmpl          # Chezmoi config -- source dir, shell, data prompts
.chezmoiignore              # Per-host ignore rules
dot_bash_profile            # Home-level bash login bootstrap -- sources .config/bash/profile
dot_bashrc                  # Home-level bash interactive bootstrap -- sources .config/bash/bashrc
dot_bash_logout             # Home-level bash logout bootstrap -- sources .config/bash/logout
dot_zshenv                  # Home-level Zsh bootstrap -- sets ZDOTDIR, then sources .config/zsh/.zshenv
dot_local/bin/
  xdg-dev-home-migrate      # Preview/apply supported dev-tool home moves into XDG targets
.profiles/
  nvim/                     # Extra Neovim profile sources (server/default/nightly)
dot_config/
  bash/                     # Bash startup files under XDG config (bashenv, profile, bashrc, logout)
  doom/                     # Doom user config + profiles
  btop/                     # Btop system monitor
  environment.d/            # User session environment exports
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
  npm/                      # npm user config pinned to XDG cache/prefix
  starship.toml             # Starship prompt
  television/               # Television fuzzy finder
  tmux/                     # Tmux config (templated)
  topgrade/                 # Topgrade system updater
  yazi/                     # Yazi file manager + plugins
  zellij/                   # Zellij multiplexer (templated)
  zsh/                      # Zsh startup files under ZDOTDIR (.zshenv, .zshrc, etc.)
```

## Feature notes

- **Multi-host templating** — `.tmpl` files use hostname conditionals to adapt configs across machines.
- **Catppuccin + Ashen theming** — Catppuccin Mocha is the default everywhere; Yazi uses the Ashen flavor.
- **XDG-first shell environment** — Session-wide XDG vars live in `environment.d`, with matching shell fallbacks and a `ZDOTDIR` bootstrap for Zsh.
- **Home shims for classic shells** — Bash and Zsh keep only the startup files that their executables must discover in `$HOME`; the real shell logic lives under `~/.config/`.
- **Relocated dev-tool homes** — Cargo, Rustup, Bun, Gradle, npm, Dart pub, and Docker are redirected away from top-level dotdirs, with `xdg-dev-home-migrate` available to move existing data safely.
- **Managed Doom user config** — Doom user files live in `dot_config/doom/`, with handwritten behavior centered in `config.el` while the upstream framework stays external.
- **Organized Neovim config** — Plugins split into domain-based subdirectories under `lua/plugins/`.
- **Selectable Neovim profiles** — `nvim-profile` persists the active profile in chezmoi config and syncs either `dot_config/nvim/` or one of the `.profiles/nvim/*` trees into `~/.config/nvim`.
- **Kitty + Neovim integration** — kitty-scrollback.nvim for terminal scrollback in Neovim.
- **Fish shell setup** — Vi keybindings, Television hotkeys (`Ctrl+T` file search, `Ctrl+G` dir jump), `zel` for fuzzy Zellij session attach, Yazi `cwd` tracking, eza aliases, zoxide, Atuin history, Carapace completions.
