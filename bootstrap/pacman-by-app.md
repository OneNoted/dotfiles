# Pacman one-shot installs by app

Commands are based on `bootstrap/packages.toml` and use `--needed` so they can be re-run safely.

## All apps (one command)

```bash
sudo pacman -S --needed chezmoi jujutsu fish zsh nushell neovim kitty tmux zellij starship eza fd ripgrep fzf zoxide atuin yazi jq wl-clipboard ffmpeg playerctl brightnessctl pre-commit shellcheck shfmt stylua taplo-cli hyprland hyprpaper hyprlock swww slurp wf-recorder hyprshot niri btop fastfetch lua-language-server yaml-language-server gopls rust-analyzer && paru -S --needed carapace-bin hyprpanel-git zen-browser-bin qmlls6
```

## Core tooling

```bash
sudo pacman -S --needed chezmoi jujutsu pre-commit shellcheck shfmt
```

## Fish

```bash
sudo pacman -S --needed fish atuin eza fd ripgrep fzf zoxide && paru -S --needed carapace-bin
```

## Nushell

```bash
sudo pacman -S --needed nushell
```

## Zsh

```bash
sudo pacman -S --needed zsh
```

## Neovim

```bash
sudo pacman -S --needed neovim lua-language-server yaml-language-server gopls rust-analyzer stylua taplo-cli && paru -S --needed qmlls6
```

## Kitty

```bash
sudo pacman -S --needed kitty wl-clipboard
```

## Tmux

```bash
sudo pacman -S --needed tmux
```

## Zellij

```bash
sudo pacman -S --needed zellij
```

## Starship

```bash
sudo pacman -S --needed starship
```

## Yazi

```bash
sudo pacman -S --needed yazi jq ffmpeg fd ripgrep fzf wl-clipboard
```

## Hyprland

```bash
sudo pacman -S --needed hyprland hyprpaper hyprlock swww slurp wf-recorder hyprshot brightnessctl playerctl wl-clipboard
```

## Niri + desktop extras

```bash
sudo pacman -S --needed niri btop fastfetch && paru -S --needed hyprpanel-git zen-browser-bin
```
