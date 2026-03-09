# CachyOS fish config (may not exist on all systems)
test -f /usr/share/cachyos-fish-config/cachyos-config.fish && source /usr/share/cachyos-fish-config/cachyos-config.fish

# Ensure ~/.local/bin is in PATH for chezmoi-managed scripts
fish_add_path -g ~/.local/bin

# Override CachyOS greeting with dynamic logo sizing
function fish_greeting
    if command -q fastfetch-dynamic
        fastfetch-dynamic
    else if command -q fastfetch
        fastfetch
    end
end

# Tool initialization (order matters)
command -q zoxide && zoxide init fish --cmd cd | source
command -q atuin && atuin init fish | source
command -q starship && starship init fish | source
