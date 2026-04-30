def --env tv_sesh [] {
    if (which tv | is-empty) {
        return
    }

    if not $nu.is-interactive {
        ^tv sesh
        return
    }

    let command_buffer = (commandline)
    commandline edit --replace ""
    ^tv sesh
    commandline edit --replace $command_buffer
    commandline set-cursor --end
}

def --env tv_atuin_shell_history [] {
    if (which tv | is-empty) or (which atuin | is-empty) {
        return
    }

    let line = (commandline)
    let cursor = (commandline get-cursor)
    let prompt = ($line | str substring 0..$cursor)
    let output = (tv atuin-history --no-status-bar --inline --input $prompt | str trim)

    if ($output | is-not-empty) {
        commandline edit --replace $output
        commandline set-cursor --end
    }
}
