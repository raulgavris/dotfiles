#!/usr/bin/env zsh
# Raul Gavris - ZSH Configuration
# Last updated: 2026-01-15

# ============================================
# 🚀 TMUX AUTO-START
# ============================================
# Auto-attach to tmux when opening terminal
if command -v tmux &>/dev/null && [ -z "$TMUX" ]; then
  ~/.tmux/attach-or-create.sh
fi

# ============================================
# 🎨 OH-MY-ZSH CONFIGURATION
# ============================================
export ZSH=$HOME/.oh-my-zsh
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  sudo
  extract
)

source $ZSH/oh-my-zsh.sh

# Autosuggestions: Accept with Ctrl+Space
bindkey '^ ' autosuggest-accept

# ============================================
# 📂 PATH CONFIGURATION
# ============================================
# Base paths
export PATH="$HOME/.local/bin:$HOME/bin:/usr/bin:$PATH"

# Console Ninja
export PATH="$HOME/.console-ninja/.bin:$PATH"

# Dart/Flutter
export PATH="$HOME/.pub-cache/bin:$PATH"
export PATH="/Users/raulgavris/fvm/default/bin:$PATH"
export PATH="$HOME/flutter/bin:$PATH"

# Java & Android
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
export PATH="$ANDROID_HOME/emulator:$PATH"
export PATH="$ANDROID_HOME/platform-tools:$PATH"
export PATH="$JAVA_HOME/bin:$PATH"

# Python (pyenv)
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# ============================================
# 🔧 NODE VERSION MANAGER (NVM)
# ============================================
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# Auto-switch node version based on .nvmrc
autoload -U add-zsh-hook
load-nvmrc() {
  local node_version="$(nvm version)"
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$node_version" ]; then
      nvm use
    fi
  elif [ "$node_version" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

# ============================================
# 🔐 SSH CONFIGURATION
# ============================================
# macOS Keychain integration for SSH keys
# To add a key: ssh-add --apple-use-keychain ~/.ssh/keyname
# Keys persist across reboots!
if [[ "$OSTYPE" == "darwin"* ]]; then
    ssh-add --apple-load-keychain 2>/dev/null
fi

# ============================================
# 📁 ZOXIDE (Smart cd)
# ============================================
eval "$(zoxide init zsh)"

# ============================================
# ⌨️ ALIASES
# ============================================
## Navigation
alias cd='z'                    # Use zoxide instead of cd
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

## Listing
alias ll='ls -lah'
alias la='ls -lAh'
alias l='ls -lh'

## Editor
alias vim='nvim'
alias v='nvim'

## Tmux
alias t='~/.tmux/attach-or-create.sh'
alias ta='tmux attach'
alias tl='tmux list-sessions'

## Brewfile management
alias brewup='cd ~/Projects/dotfiles && brew bundle dump --force --describe && git diff Brewfile'

## Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git pull'
alias gps='git push'
alias gco='git checkout'
alias gb='git branch'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'

## System
alias clr='clear'
alias h='history'
alias ports='lsof -iTCP -sTCP:LISTEN -n -P'

# ============================================
# 🛠️ FUNCTIONS
# ============================================

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Quick git commit (override oh-my-zsh git plugin alias)
unalias gcm 2>/dev/null
gcm() {
    git commit -m "$1"
}

# Git add all and commit
unalias gac 2>/dev/null
gac() {
    git add . && git commit -m "$1"
}

# Kill process by port
killport() {
    if [ -z "$1" ]; then
        echo "Usage: killport <port_number>"
        return 1
    fi
    lsof -ti:$1 | xargs kill -9 2>/dev/null && echo "✅ Killed process on port $1" || echo "❌ No process found on port $1"
}

# Extract any archive
extract() {
    if [ -f $1 ]; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar x $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Quick project search and open in editor
proj() {
    local dir=$(find ~/Projects -maxdepth 3 -type d -name ".git" 2>/dev/null | sed 's/\/.git$//' | fzf)
    if [ -n "$dir" ]; then
        cd "$dir" && nvim .
    fi
}

# Git clone and cd into it
unalias gcl 2>/dev/null
gcl() {
    git clone "$1" && cd "$(basename "$1" .git)"
}

# ============================================
# 🎨 POWERLEVEL10K
# ============================================
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ============================================
# 🔧 COMPLETIONS
# ============================================
# Dart CLI completion
[[ -f /Users/raulgavris/.dart-cli-completion/zsh-config.zsh ]] && . /Users/raulgavris/.dart-cli-completion/zsh-config.zsh || true

# FZF keybindings and fuzzy completion
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_OPTS='--height 40% --reverse --border --preview-window=right:60%'

# ============================================
# 🎯 LOCAL/CUSTOM CONFIGURATION
# ============================================
# Source local config if it exists (for machine-specific settings)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# ============================================
# 🎭 WELCOME MESSAGE (at the end to not block shell initialization)
# ============================================
if command -v fortune &>/dev/null && command -v cowsay &>/dev/null && command -v lolcat &>/dev/null; then
    fortune | cowsay | lolcat
fi
