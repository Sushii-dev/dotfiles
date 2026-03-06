if test -z "$SSH_AUTH_SOCK"
    set -l sock_path "$HOME/.ssh/agent.sock"

    if not ssh-add -l >/dev/null 2>&1
        rm -f $sock_path
        ssh-agent -c -a $sock_path 2>/dev/null | head -2 | source
        ssh-add ~/.ssh/id_ed25519 2>/dev/null
    else
        set -gx SSH_AUTH_SOCK $sock_path
    end
end
