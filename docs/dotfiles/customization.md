# Customization

## Hostname conditionals

Search `.tmpl` files for `.chezmoi.hostname` to find host-specific blocks. The main hosts are `aeolus` (Arch + Nvidia GPU setup) and `hephaestus`. Adjust or remove these for your machine.

## Monitor setup

`aeolus` manages its Hyprland layout in `dot_config/hypr/monitors.conf.tmpl`. For other hosts, either add a hostname branch there or keep a machine-specific `~/.config/hypr/monitors.conf`. See the [Hyprland wiki](https://wiki.hypr.land/Configuring/Monitors/) for syntax.

## Shell preference

Fish is the default (set in `.chezmoi.toml.tmpl` as the chezmoi `cd` command shell). Zsh config with Zinit is also included at `dot_zshrc`, and Nushell config lives under `dot_config/nushell/`.

## Shared shell core

Common aliases and editor environment variables are defined once in `.chezmoidata/shell_core.yaml` and rendered to shell adapters in `dot_config/shared/`.
