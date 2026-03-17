# config.nu
#
# Installed by:
# version = "0.107.0"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Nushell sets "sensible defaults" for most configuration settings,
# so your `config.nu` only needs to override these defaults if desired.
#
# You can open this file in your default editor using:
#     config nu
#
# You can also pretty-print and page through the documentation for configuration
# options using:
#     config nu --doc | nu-highlight | less -R

# General

$env.config.buffer_editor = "nvim"

# Appearance
source ~/.config/nushell/themes/catppuccin_mocha.nu
$env.config.show_banner = false

# Shared shell aliases/env vars from chezmoi data
source ../shared/shell-core.nu

# Initialize

# Zoxide
source ~/.config/nushell/inits/.zoxide.nu
source ~/.config/nushell/inits/starship.nu
source ~/.config/nushell/inits/carapace.nu
source ~/.config/nushell/inits/atuin.nu
