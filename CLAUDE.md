# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a macOS dotfiles repository managed with GNU Stow. Each top-level directory (git, tmux, zsh, nvim, karabiner) is a "stow package" that gets symlinked to `$HOME`.

## Commands

### Installation
```bash
./install.sh                    # Full installation (Homebrew, stow, oh-my-zsh, etc.)
stow <package> -t $HOME         # Symlink a single package (git, tmux, zsh, nvim, karabiner)
stow */ -t $HOME                # Symlink all packages
stow --adopt <package> -t $HOME # Adopt existing files and symlink
```

### Updating Brewfile
```bash
brew bundle dump --force --describe  # Regenerate Brewfile from installed packages
```

### Tmux
- Prefix is `Ctrl-a` (not default Ctrl-b)
- `Ctrl-a + I` - Install plugins via TPM
- `Ctrl-a + H` - View tmux guide (opens TMUX_GUIDE.md)
- `Ctrl-a + r` - Reload tmux config

## Architecture

### Stow Package Structure
Each directory mirrors the home directory structure:
- `git/.gitconfig` -> `~/.gitconfig`
- `zsh/.zshrc` -> `~/.zshrc`
- `tmux/.tmux.conf` -> `~/.tmux.conf`
- `tmux/.tmux/` -> `~/.tmux/` (contains helper scripts)
- `nvim/.config/nvim/` -> `~/.config/nvim/`
- `karabiner/.config/karabiner/` -> `~/.config/karabiner/`

### Tmux Scripts (~/.tmux/)
Helper scripts for tmux workflow:
- `sessionizer.sh` - Quick project jumping with fzf (Ctrl-a + Ctrl-f)
- `workspace.sh` - Multi-repo workspace management (Ctrl-a + f)
- `switchsession.sh` - Enhanced session picker (Ctrl-a + s)
- `killsession.sh` - Kill sessions via fzf (Ctrl-a + K)
- `attach-or-create.sh` - Auto-attach or create session on terminal open
- `cpu.sh`, `memory.sh`, `battery.sh` - Status bar widgets

### Zsh Configuration
- Uses Oh My Zsh with Powerlevel10k theme
- Auto-starts tmux on terminal open
- Auto-switches Node version based on `.nvmrc` via nvm
- Machine-specific config goes in `~/.zshrc.local` (not tracked)

### Neovim
- Uses lazy.nvim for plugin management
- Config entry point: `nvim/.config/nvim/init.lua`
- Plugins defined in `nvim/.config/nvim/lua/`
