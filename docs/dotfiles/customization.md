# Customization

## Hostname conditionals

Search `.tmpl` files for `.chezmoi.hostname` to find host-specific blocks. The main hosts are `aeolus` (Arch + Nvidia GPU setup) and `hephaestus`. Adjust or remove these for your machine.

## Monitor setup

`aeolus` manages its Hyprland layout in `dot_config/hypr/monitors.conf.tmpl`. For other hosts, either add a hostname branch there or keep a machine-specific `~/.config/hypr/monitors.conf`. See the [Hyprland wiki](https://wiki.hypr.land/Configuring/Monitors/) for syntax.

## Shell preference

Fish is the default (set in `.chezmoi.toml.tmpl` as the chezmoi `cd` command shell). Zsh keeps its real startup files under `dot_config/zsh/`, with `dot_zshenv` reduced to the required home-level bootstrap that sets `ZDOTDIR` and hands off to `dot_config/zsh/dot_zshenv`. Bash follows the same pattern: `~/.bash_profile`, `~/.bashrc`, and `~/.bash_logout` stay as tiny shims in `$HOME`, while the actual bash files live under `dot_config/bash/`. Nushell config lives under `dot_config/nushell/`.

## XDG session env

Base XDG variables are exported session-wide from `dot_config/environment.d/60-xdg.conf` and mirrored in shell startup for non-systemd launches. For Zsh, only the tiny home-level bootstrap remains in `~/.zshenv`; the actual environment logic lives in `dot_config/zsh/dot_zshenv` under `ZDOTDIR`. For Bash, `BASH_ENV` points at `dot_config/bash/bashenv`, and the home-level shims hand off interactive and login startup into `dot_config/bash/`. Doom uses `EMACSDIR=~/.config/emacs`, `DOOMDIR=~/.config/doom`, and the `default` Doom profile for XDG `share`/`cache`/`state` directories. Current Doom 3 pre-release builds still keep straight package repos and build artifacts under `~/.config/emacs/.local/straight`, so that tree should not be treated as removable yet.

The same early startup layer also relocates several dev-tool homes away from top-level dotdirs: `CARGO_HOME`, `RUSTUP_HOME`, `BUN_INSTALL`, `GRADLE_USER_HOME`, npm's config/cache/prefix trio, `PUB_CACHE`, `DOCKER_CONFIG`, and safe cache/tool state for Go, Python tooling, Node tooling, K9s/Helm, Mise, and Starship. GUI launchers and compositor binds are expected to resolve `ashell`, `whispers`, `snappers`, and `zoop` from `PATH`, not from `~/.cargo/bin`.

To migrate existing directories safely, run `xdg-dev-home-migrate --plan` first and then `xdg-dev-home-migrate --migrate` once the new environment has been applied. The helper copies supported directories into their XDG targets and renames the originals into dated backups under `~/.local/state/xdg-dev-home-migrate/backups/`.

## Local desktop entries

Custom desktop entries live in `dot_local/share/applications/` so the source of truth stays in chezmoi instead of drifting in `~/.local/share/applications/`.

Prefer simple `Exec=` and `TryExec=` commands that resolve through `PATH` rather than absolute Cargo paths or app-generated wrapper scripts. That keeps launchers aligned with the XDG session environment exported from `environment.d` and makes local app entries easier to read and fix.

`Taskers` is managed this way on purpose: the generated desktop entry wrapped the app in a Niri-specific focus script and launched the higher-level `taskers` shim, while the known-good local development entrypoint is `taskers-gtk`.

## Doom layout

The Doom config stays intentionally monolithic: `init.el` selects modules, `packages.el` declares extra packages when needed, and `config.el` is the main handwritten config file. Emacs Customize output should live in `custom.el` under `doom-state-dir`, not inside `config.el`. The default Doom theme is Catppuccin Mocha via the official `catppuccin-theme` package, without an extra layer of local theme overrides.

## Shared shell core

Common aliases and editor environment variables are defined once in `.chezmoidata/shell_core.yaml` and rendered to shell adapters in `dot_config/shared/`. Dynamic XDG and PATH logic stays in the shell-specific startup files and `environment.d`.

## Neovim profiles

The active Neovim config is selected via the chezmoi data key `nvim_profile`. `nvim-lazy` uses the source tree in `dot_config/nvim/`, while `nvim-server`, `nvim`, and `nvim-nightly` live under `.profiles/nvim/`. Use `nvim-profile <name>` to update the stored selection and sync the chosen profile into `~/.config/nvim`.
