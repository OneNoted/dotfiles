set shell := ["bash", "-euo", "pipefail", "-c"]

default:
    @just --list

check: check-shell check-format check-scripts check-bootstrap

check-shell:
    zsh -n dot_config/zsh/dot_zshrc
    fish -n dot_config/private_fish/config.fish.tmpl
    nu --commands 'source dot_config/nushell/env.nu'
    nu --commands 'source dot_config/nushell/config.nu'

check-format:
    mapfile -t files < <(rg --files -g "*.toml" -g "!.jj/**" -g "!dot_config/yazi/flavors/**/readonly_*.toml"); taplo fmt --check "${files[@]}"
    stylua --check dot_config/nvim dot_config/yazi/init.lua dot_config/yazi/plugins/whoosh.yazi/main.lua dot_config/yazi/plugins/folder-rules.yazi/main.lua

check-scripts:
    shfmt -d dot_config/niri/executable_snappers-record-toggle.sh dot_config/hypr/executable_screenshot-region.sh bootstrap/bootstrap.sh bootstrap/nvim.sh dot_local/bin/executable_niri-session dot_local/bin/executable_niri-session-install-system-bridge dot_local/bin/executable_niri-tmux-session-picker dot_local/bin/executable_portal-session-refresh dot_local/bin/executable_sesh-picker-terminal dot_local/bin/executable_tv dot_local/bin/executable_xdg-open dot_local/bin/executable_yazi-wrapper.sh dot_local/bin/executable_niri-launch-eww
    shellcheck dot_config/niri/executable_snappers-record-toggle.sh dot_config/hypr/executable_screenshot-region.sh bootstrap/bootstrap.sh bootstrap/nvim.sh dot_local/bin/executable_niri-session dot_local/bin/executable_niri-session-install-system-bridge dot_local/bin/executable_niri-tmux-session-picker dot_local/bin/executable_portal-session-refresh dot_local/bin/executable_sesh-picker-terminal dot_local/bin/executable_tv dot_local/bin/executable_xdg-open dot_local/bin/executable_yazi-wrapper.sh dot_local/bin/executable_niri-launch-eww

check-bootstrap:
    bash bootstrap/bootstrap.sh --plan >/dev/null
    bash bootstrap/nvim.sh --plan >/dev/null

precommit:
    pre-commit run --all-files
