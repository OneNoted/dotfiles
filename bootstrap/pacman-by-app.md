# Pacman one-shot installs by app

Commands are based on `bootstrap/packages.toml` and use `--needed` so they can be re-run safely. For component-aware installs, prefer the wrapper scripts in `bootstrap/` when available.

## All apps (one command)

```bash
sudo pacman -S --needed chezmoi jujutsu fish zsh nushell neovim kitty tmux zellij starship eza fd ripgrep fzf zoxide atuin yazi jq wl-clipboard ffmpeg playerctl brightnessctl pre-commit shellcheck shfmt stylua taplo-cli hyprland hyprpaper hyprlock swww slurp wf-recorder hyprshot niri btop fastfetch lua-language-server yaml-language-server gopls rust-analyzer && paru -S --needed carapace-bin hyprpanel-git zen-browser-bin qmlls6
```

## All apps (no Hyprland/Niri)

```bash
sudo pacman -S --needed chezmoi jujutsu fish zsh nushell neovim kitty tmux zellij starship eza fd ripgrep fzf zoxide atuin yazi jq wl-clipboard ffmpeg playerctl brightnessctl pre-commit shellcheck shfmt stylua taplo-cli btop fastfetch lua-language-server yaml-language-server gopls rust-analyzer && paru -S --needed carapace-bin zen-browser-bin qmlls6
```

## All apps (no Hyprland/Niri/Neovim)

```bash
sudo pacman -S --needed chezmoi jujutsu fish zsh nushell kitty tmux zellij starship eza fd ripgrep fzf zoxide atuin yazi jq wl-clipboard ffmpeg playerctl brightnessctl pre-commit shellcheck shfmt btop fastfetch && paru -S --needed carapace-bin zen-browser-bin
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
bash bootstrap/nvim.sh --install
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
