# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a cross-platform dotfiles repository managed with GNU Stow. Supports **macOS** and **Ubuntu/Debian**. Each top-level directory (git, tmux, zsh, nvim, karabiner, ghostty, termdesk) is a "stow package" that gets symlinked to `$HOME`.

## Commands

### Installation
```bash
./install.sh                    # Full installation (detects OS automatically)
stow <package> -t $HOME         # Symlink a single package (git, tmux, zsh, nvim, karabiner, ghostty, termdesk)
stow */ -t $HOME                # Symlink all packages
stow --adopt <package> -t $HOME # Adopt existing files and symlink
```

### Updating Brewfile (macOS only)
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
- `zsh/.zshrc` -> `~/.zshrc` (copied by install.sh, NOT symlinked — allows p10k to modify it freely)
- `zsh/.zshrc.base` -> `~/.zshrc.base` (main config, symlinked via stow)
- `tmux/.tmux.conf` -> `~/.tmux.conf`
- `tmux/.tmux/` -> `~/.tmux/` (contains helper scripts)
- `nvim/.config/nvim/` -> `~/.config/nvim/`
- `karabiner/.config/karabiner/` -> `~/.config/karabiner/` (macOS only)
- `ghostty/.config/ghostty/config` -> `~/.config/ghostty/config`
- `termdesk/.config/termdesk/config.toml` -> `~/.config/termdesk/config.toml` (runtime state not tracked)

### Cross-Platform Notes
- `install.sh` uses `detect_os()` to set `OS` to "macos" or "linux"
- macOS uses Homebrew + Karabiner; Linux uses apt + GNOME keyboard remap (Super → Ctrl)
- tmux.conf uses `if-shell "uname | grep -q Darwin"` for platform-specific bindings (clipboard, URL opener)
- tmux status scripts (cpu.sh, memory.sh, battery.sh) detect OS via `$OSTYPE`
- .zshrc wraps macOS-specific paths (java_home, brew) in OS conditionals

### Tmux Scripts (~/.tmux/)
Helper scripts for tmux workflow:
- `sessionizer.sh` - Quick project jumping with fzf (Ctrl-a + Ctrl-f)
- `workspace.sh` - Multi-repo workspace management (Ctrl-a + f)
- `switchsession.sh` - Enhanced session picker (Ctrl-a + s)
- `killsession.sh` - Kill sessions via fzf (Ctrl-a + K)
- `attach-or-create.sh` - Auto-attach or create session on terminal open
- `cpu.sh`, `memory.sh`, `battery.sh` - Status bar widgets (cross-platform)

### Zsh Configuration
- `.zshrc` is a thin wrapper copied (not symlinked) by install.sh; sources `.zshrc.local` then `.zshrc.base`
- `.zshrc.base` contains the main config (Oh My Zsh, plugins, prompt engine); symlinked via stow
- Machine-specific config goes in `~/.zshrc.local` (not tracked)
- Prompt engine is determined by sentinel file `~/.ohmyposh.omp.json` (exists = Oh My Posh, absent = Powerlevel10k)
- Uses Oh My Zsh with Powerlevel10k theme
- Auto-starts tmux on terminal open
- Auto-switches Node version based on `.nvmrc` via fnm

### Neovim
- LazyVim distro with extras (TypeScript, Go, JSON, Biome, Codeium)
- Config entry point: `nvim/.config/nvim/init.lua`
- LazyVim setup + extras: `nvim/.config/nvim/lua/config/lazy.lua`
- Extras manifest: `nvim/.config/nvim/lazyvim.json`
- Plugins defined in `nvim/.config/nvim/lua/plugins/`
- VS Code-style layout via edgy.nvim (`lua/plugins/layout.lua`): Neo-tree left, Claude right, terminals bottom
- Custom winbar with buffer tabs and terminal tabs (`lua/plugins/ui.lua`)
- Custom top menu bar (`lua/plugins/menu.lua`) — toggled with Ctrl+F10/Alt+m
- Left sidebar tabs: Files | Git | Debug — clickable tabs sharing the left panel (`lua/plugins/ui.lua`)
  - **Files**: Neo-tree file explorer (default)
  - **Git**: Custom Source Control panel (`lua/config/git-panel.lua`) with Nerd Font icon toolbar (commit/push/pull/fetch/stash), branch + ahead/behind, staged/unstaged/untracked sections, inline diff on Enter
  - **Debug**: DAP UI panels (appears when debugger is active)
- DAP debugging: full VS Code-style debug experience (`lua/plugins/dap.lua`) with toolbar, breakpoints, step controls
- Session persistence: `nvim .` or `nvim ~/project` auto-restores sessions via persistence.nvim (`lua/config/autocmds.lua`)
- VS Code keybindings: Ctrl+P (palette), Ctrl+S (save), Ctrl+B (sidebar), Ctrl+. (quick fix), Ctrl+D (multi-cursor), etc.
