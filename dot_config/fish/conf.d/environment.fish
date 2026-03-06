# Editors
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx GIT_EDITOR nvim
set -gx TERMINAL ghostty

# bat
set -gx BAT_THEME "Coldark-Dark"

# vivid LS_COLORS
set -gx LS_COLORS (vivid generate catppuccin-mocha)
