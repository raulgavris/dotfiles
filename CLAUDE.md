# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a macOS dotfiles repository managed with GNU Stow. Each top-level directory (git, tmux, zsh, nvim, karabiner, iterm2) is a "stow package" that gets symlinked to `$HOME`.

## Commands

### Installation
```bash
./install.sh                    # Full installation (Homebrew, stow, oh-my-zsh, etc.)
stow <package> -t $HOME         # Symlink a single package
stow */ -t $HOME                # Symlink all packages
stow --adopt <package> -t $HOME # Adopt existing files and symlink
```

### Neovim
```bash
:Lazy sync          # Install/update plugins
:Lazy health        # Check plugin health
:Mason              # Manage LSP servers, formatters, linters
:TSUpdate           # Update Treesitter parsers
:Reload             # Custom command: reload core config without restarting
:Format             # Custom command: format current file (prefers none-ls formatters)
:Update             # Custom command: git pull config updates
:LuaSnipEdit        # Custom command: edit snippets for current filetype
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
Each directory mirrors the home directory structure. For example:
- `git/.gitconfig` -> `~/.gitconfig`
- `nvim/.config/nvim/` -> `~/.config/nvim/`
- `tmux/.tmux/` -> `~/.tmux/` (contains helper scripts)

### Neovim Config Architecture

Entry point: `nvim/.config/nvim/init.lua` — supports VSCode-Neovim (loads only `core.options` when `vim.g.vscode` is set). Disables netrw (replaced by Neo-tree).

**Load order:**
1. `lua/core/init.lua` → requires utils, keymaps, options
2. `lua/pluginsloader.lua` → bootstraps lazy.nvim, imports `plugins/` and `plugins/lsp/`
3. Theme selected via `local name = "onedark"` in `init.lua` → loads matching `plugins/theme/<name>.lua` config, then sets colorscheme

**Core modules (`lua/core/`):**
- `utils.lua` — Global helper functions (`set_keymaps`, `set_option`, `set_global`, `format_code`, `run_code`, `disable_arrows`). Defines custom commands `:Format`, `:Reload`, `:Update`, `:LuaSnipEdit`. Formatting logic: prefers none-ls formatters when available, falls back to LSP. `run_code()` supports running files for many languages (JS, TS, Python, Go, Rust, C/C++, etc.) in a bottom terminal split.
- `keymaps.lua` — All keybindings in a declarative table structure (`keymaps.normal_mode`, `insert_mode`, `terminal_mode`, `visual_mode`, `visual_block_mode`, `command_mode`), applied via `set_keymaps()`. Leader is Space. Includes a custom command palette (`<C-P>` or `<leader>cp`) with MRU tracking — recently used commands float to top with ↺ prefix. Visual mode has its own command palette with selection-aware actions.
- `options.lua` — Vim options: 2-space indentation, relative line numbers, system clipboard (`unnamedplus`), no swap/backup files, persistent undo, dark background.

**Plugin convention:** Each file in `lua/plugins/` returns a lazy.nvim plugin spec table. Lazy auto-imports everything via `{ import = "plugins" }` and `{ import = "plugins.lsp" }`. Base dependencies (`plenary.nvim`, `vim-tmux-navigator`, `vim-ReplaceWithRegister`) are in `plugins/init.lua`.

**LSP setup:**
- Mason (`plugins/lsp/mason.lua`) — three specs: `mason.nvim` (base), `mason-lspconfig.nvim` (server install), `mason-null-ls.nvim` (formatter/linter install)
- `plugins/lsp/lspconfig.lua` — configures servers using `vim.lsp.config()` / `vim.lsp.enable()`. Global config applies `cmp-nvim-lsp` capabilities and `vim-illuminate` on_attach to all servers.
- TypeScript uses `typescript-tools.nvim` instead of ts_ls (ts_ls is explicitly disabled via empty filetypes + `vim.lsp.enable("ts_ls", false)`)
- `plugins/lsp/null-ls.lua` — actually `none-ls.nvim` (maintained fork of null-ls). Handles formatting (prettier with `prefer_local` for project node_modules, stylua, black, isort, clang-format) and diagnostics (eslint_d, conditionally enabled when eslint config exists)
- Default enabled LSPs: eslint, html, cssls, tailwindcss, emmet_ls, jsonls (with schemastore), yamlls (with schemastore), lua_ls
- Additional LSPs available but commented out: dockerls, docker_compose_language_service, graphql, prismals, pyright, clangd

**Adding a new plugin:** Create `lua/plugins/yourplugin.lua` returning a lazy.nvim spec. It will be auto-discovered.

**Adding a keymap:** Add to the appropriate mode table in `lua/core/keymaps.lua`. Format: `["<key>"] = { cmd = "...", desc = "..." }`. Optionally add `opt` for custom keymap options.

**Changing the theme:** Edit `local name = "onedark"` in `init.lua`. Available themes have config files in `plugins/theme/` (onedark, gruvbox). To add a new theme, create `plugins/theme/<name>.lua` with the plugin spec and add the colorscheme install to `plugins/theme/init.lua`.

### Tmux Scripts (`tmux/.tmux/`)
- `sessionizer.sh` — Quick project jumping with fzf (`Ctrl-a + Ctrl-f`)
- `workspace.sh` — Multi-repo workspace management (`Ctrl-a + f`)
- `switchsession.sh` — Enhanced session picker (`Ctrl-a + s`)
- `killsession.sh` — Kill sessions via fzf (`Ctrl-a + K`)
- `attach-or-create.sh` — Auto-attach or create session on terminal open
- `cpu.sh`, `memory.sh`, `battery.sh` — Status bar widgets

### Zsh Configuration
- Uses Oh My Zsh with Powerlevel10k theme
- Auto-starts tmux on terminal open
- Auto-switches Node version based on `.nvmrc` via nvm
- Machine-specific config goes in `~/.zshrc.local` (not tracked)
