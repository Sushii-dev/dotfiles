# CachyOS fish config (may not exist on all systems)
test -f /usr/share/cachyos-fish-config/cachyos-config.fish && source /usr/share/cachyos-fish-config/cachyos-config.fish

# Override CachyOS greeting with dynamic logo sizing
function fish_greeting
    fastfetch-dynamic
end

# Tool initialization (order matters)
zoxide init fish --cmd cd | source
atuin init fish | source
starship init fish | source
