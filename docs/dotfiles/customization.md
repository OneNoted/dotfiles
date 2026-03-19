# Customization

## Hostname conditionals

Search `.tmpl` files for `.chezmoi.hostname` to find host-specific blocks. The main hosts are `aeolus` (Arch + Nvidia GPU setup) and `hephaestus`. Adjust or remove these for your machine.

## Monitor setup

`aeolus` manages its Hyprland layout in `dot_config/hypr/monitors.conf.tmpl`. For other hosts, either add a hostname branch there or keep a machine-specific `~/.config/hypr/monitors.conf`. See the [Hyprland wiki](https://wiki.hypr.land/Configuring/Monitors/) for syntax.

## Shell preference

Fish is the default (set in `.chezmoi.toml.tmpl` as the chezmoi `cd` command shell). Zsh uses a minimal `dot_zshenv` bootstrap and keeps its main Zinit config at `dot_config/zsh/dot_zshrc`, and Nushell config lives under `dot_config/nushell/`.

## XDG session env

Base XDG variables are exported session-wide from `dot_config/environment.d/60-xdg.conf` and mirrored in shell startup for non-systemd launches. Doom uses `EMACSDIR=~/.config/emacs`, `DOOMDIR=~/.config/doom`, and the `default` Doom profile for XDG `share`/`cache`/`state` directories. Current Doom 3 pre-release builds still keep straight package repos and build artifacts under `~/.config/emacs/.local/straight`, so that tree should not be treated as removable yet.

## Shared shell core

Common aliases and editor environment variables are defined once in `.chezmoidata/shell_core.yaml` and rendered to shell adapters in `dot_config/shared/`. Dynamic XDG and PATH logic stays in the shell-specific startup files and `environment.d`.
