function fish_user_key_bindings
    # Bind ctrl-t to open 'tv files'
    bind -M insert \ct 'commandline -r ""; tv; commandline -f repaint'

    # Bind ctrl-s to open 'tv sesh'
    bind -M insert \cs tv_sesh
    bind -M default \cs tv_sesh

    # Capture output of 'tv dirs' and cd into that directory
    set -l cd_tv 'set -l result (tv dirs); if test -n "$result"; cd $result; commandline -f repaint; end'

    bind -M insert \cg "$cd_tv"
    bind -M default \cg "$cd_tv"
end
