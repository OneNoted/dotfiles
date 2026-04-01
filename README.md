# dotfiles

Arch/Hyprland/Niri dotfiles, managed with [chezmoi](https://www.chezmoi.io/) and templated for multi-host deployment.

<!-- TODO: Add a screenshot of the rice here -->
> Screenshot coming soon

## Stack

| Category | Tool(s) |
|---|---|
| WM / Desktop | Hyprland, Niri, ashell |
| Terminal | Kitty |
| Multiplexer | Zellij, Tmux |
| Shell | Fish (primary), Nushell, Zsh |
| Editor | Neovim, Doom Emacs |
| File Manager | Yazi |
| Shell Prompt | Starship |
| Fuzzy Finder | Television, fzf |
| Shell History | Atuin |
| System Info | Fastfetch, Btop, Onefetch |
| Misc | Eza, Zoxide, Topgrade, Equibop |

## Install

```sh
chezmoi init OneNoted/dotfiles
chezmoi apply
```

You'll be prompted for an Atuin sync server address during init — leave empty if not self-hosting.

## Neovim Profiles

Neovim profile selection is persisted in chezmoi data as `nvim_profile`. Use `nvim-profile <name>` to switch the active profile and sync it into `~/.config/nvim`. The current profiles are `nvim-lazy`, `nvim-server`, `nvim`, and `nvim-nightly`.

## Docs

- [Bootstrapping](docs/dotfiles/bootstrapping.md) — Arch package install, validation
- [Customization](docs/dotfiles/customization.md) — host conditionals, monitors, shell choice
- [Structure](docs/dotfiles/structure.md) — directory layout, feature notes

The user session exports XDG base directories through `.config/environment.d/60-xdg.conf`, Doom's user config is managed at `.config/doom/` with handwritten behavior centered in `config.el` and Catppuccin Mocha as the editor theme, and Zsh keeps its real startup files in `.config/zsh/` with only a tiny home-level `.zshenv` bootstrap left in `$HOME`.

For dev-tool homes that would otherwise spill into top-level dotdirs, the repo exports XDG-aware tool homes for Cargo, Rustup, Bun, Gradle, npm, Dart pub, and Docker. Use `xdg-dev-home-migrate --plan` to preview the supported moves and `xdg-dev-home-migrate --migrate` to relocate the existing directories into the configured XDG targets with dated backups under `~/.local/state/`.
