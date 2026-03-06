set shell := ["bash", "-euo", "pipefail", "-c"]

default:
    @just --list

check: check-shell check-format check-scripts check-bootstrap

check-shell:
    zsh -n dot_zshrc
    fish -n dot_config/private_fish/config.fish.tmpl
    nu --commands 'source dot_config/nushell/env.nu'
    nu --commands 'source dot_config/nushell/config.nu'

check-format:
    taplo fmt --check
    stylua --check dot_config/nvim dot_config/yazi/init.lua dot_config/yazi/plugins/whoosh.yazi/main.lua dot_config/yazi/plugins/folder-rules.yazi/main.lua

check-scripts:
    shfmt -d dot_config/niri/executable_region-record-toggle.sh dot_config/hypr/executable_screenshot-region.sh bootstrap/bootstrap.sh bootstrap/nvim.sh
    shellcheck dot_config/niri/executable_region-record-toggle.sh dot_config/hypr/executable_screenshot-region.sh bootstrap/bootstrap.sh bootstrap/nvim.sh

check-bootstrap:
    bash bootstrap/bootstrap.sh --plan >/dev/null
    bash bootstrap/nvim.sh --plan >/dev/null

precommit:
    pre-commit run --all-files
