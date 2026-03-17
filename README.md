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
| Editor | Neovim |
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

## Docs

- [Bootstrapping](docs/dotfiles/bootstrapping.md) — Arch package install, validation
- [Customization](docs/dotfiles/customization.md) — host conditionals, monitors, shell choice
- [Structure](docs/dotfiles/structure.md) — directory layout, feature notes
