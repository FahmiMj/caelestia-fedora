# Caelestia on Fedora — personal terminal configuration.
#
# This file is sourced last (interactive shells only) by the upstream
# fish/config.fish, so aliases and the prompt here override the defaults.

# ---------------------------------------------------------------
# Exports and paths
# ---------------------------------------------------------------
if command -q nvim
    set -gx EDITOR nvim
else
    set -gx EDITOR vi
end

fish_add_path /usr/lib/ccache/bin "$HOME/.cargo/bin" "$HOME/.local/bin"

# ---------------------------------------------------------------
# General aliases
# ---------------------------------------------------------------
alias .. 'cd ..'
alias c 'clear'
alias nf 'fastfetch'
alias ff 'fastfetch'
alias pf 'fastfetch'
alias ls 'eza -a --icons=always'
alias ll 'eza -al --icons=always'
alias lt 'eza -a --tree --level=1 --icons=always'
# Single quotes would make these run the literal string "$EDITOR"; expand the
# variable at definition time instead.
alias v $EDITOR
alias vim $EDITOR
alias wifi nmtui
alias lock hyprlock
alias update-grub 'sudo grub-mkconfig -o /boot/grub/grub.cfg'

# ---------------------------------------------------------------
# Git aliases
# ---------------------------------------------------------------
alias gs 'git status'
alias ga 'git add'
alias gc 'git commit -m'
alias gp 'git push'
alias gpl 'git pull'
alias gst 'git stash'
alias gsp 'git stash; git pull'
alias gfo 'git fetch origin'
alias gcheck 'git checkout'

# ---------------------------------------------------------------
# Prompt: oh-my-posh (falls back to the default fish prompt when absent)
# ---------------------------------------------------------------
if command -q oh-my-posh; and test -f "$HOME/.config/ohmyposh/zen.toml"
    oh-my-posh init fish --config "$HOME/.config/ohmyposh/zen.toml" | source
end

# ---------------------------------------------------------------
# Fastfetch on every interactive shell
# ---------------------------------------------------------------
if test -f "$HOME/.config/caelestia-fastfetch/config.jsonc"
    fastfetch --config "$HOME/.config/caelestia-fastfetch/config.jsonc"
else
    fastfetch
end
