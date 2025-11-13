# Cloud Omarchy bashrc

# Load system-wide bashrc if it exists (Omarchy defaults)
if [ -f /etc/bash.bashrc ]; then
    . /etc/bash.bashrc
fi

# Load personal aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Custom prompt (you can change later)
export PS1="\u@\h:\w$ "

# Add ~/.local/bin to PATH
export PATH="$HOME/.local/bin:$PATH"
