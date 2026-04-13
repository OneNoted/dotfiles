function tv_sesh --description "Run tv sesh from a fish key binding"
    if not command -q tv
        return 127
    end

    set -l command_buffer
    if status is-interactive
        set command_buffer (commandline)
        commandline -r ""
    end

    tv sesh
    set -l tv_status $status

    if status is-interactive
        commandline -r -- $command_buffer
        commandline -f repaint
    end

    return $tv_status
end
