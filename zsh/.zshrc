# Powerlevel10k instant prompt (must be at the very top)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]] && [[ ! -f "$HOME/.ohmyposh.omp.json" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Source local config first (sets PATH needed by base config)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# Source base configuration (managed by dotfiles)
source "$HOME/.zshrc.base"


# Source user profile (machine-specific aliases / PATH — optional)
[[ -f "$HOME/.profile" ]] && source "$HOME/.profile"

# Task Master aliases added on 2/10/2026
alias tm='task-master'
alias taskmaster='task-master'
alias hamster='task-master'
alias ham='task-master'

# Claude Code deferred MCP loading (added by Taskmaster)
export ENABLE_EXPERIMENTAL_MCP_CLI='true'
export PATH="$HOME/.local/bin:$PATH"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
