#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
export PATH="$HOME/.local/bin:$PATH"


# --- Tokyo Night CLI tools ---
alias ls='eza --icons=auto --group-directories-first'
alias ll='eza -l --icons=auto --group-directories-first --git --time-style=relative'
alias la='eza -la --icons=auto --group-directories-first --git --time-style=relative'
alias lt='eza --tree --level=2 --icons=auto --group-directories-first'
alias cat='bat --paging=never --style=plain'
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"

# fastfetch once per kitty window (not in tmux panes or nested shells)
if [[ $TERM == xterm-kitty && -z $TMUX && -z $FASTFETCH_SHOWN ]]; then
    export FASTFETCH_SHOWN=1
    fastfetch
fi

# Starship prompt (Tokyo Night powerline) — falls back to PS1 above if not installed
command -v starship >/dev/null && eval "$(starship init bash)"
export PATH="$HOME/development/flutter/bin:$PATH"
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
export SRC_SECRET_KEY=MySuperSecretKey
export STG_SECRET_KEY=MySuperSecretKey


# Added by Antigravity CLI installer
export PATH="/home/adham/.local/bin:$PATH"

# Flutter: Arch installs Chrome as google-chrome-stable
export CHROME_EXECUTABLE=/usr/bin/google-chrome-stable
