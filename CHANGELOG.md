# Changelog

## 2026-02-07 — Cross-Platform Support (macOS + Ubuntu/Debian)

### install.sh — Added superfile (terminal file manager)
- Installs [superfile](https://github.com/yorukot/superfile) (`spf`) — modern TUI file manager
- macOS: `brew install superfile`
- Linux: `curl -sLo- https://superfile.dev/install.sh | bash`
- Skips install if `spf` command already exists

### zsh/.zshrc + install.sh — Replaced Powerlevel10k with Oh My Posh
- Removed Powerlevel10k instant prompt, theme setting, and p10k config sourcing from `.zshrc`
- Added Oh My Posh init with exported theme config (`~/.ohmyposh.omp.json`)
- `install.sh`: cross-platform install (brew on macOS, curl on Linux), fzf theme picker with live preview (124+ themes)
- Added `omp-theme` command (`~/.local/bin/omp-theme`) — reopen theme picker anytime with arrow navigation + live preview
- Tab key in theme picker cycles filter: All → Single line → Multi line (detects multi-line themes via `"newline"` block type)
- Oh My Zsh stays for plugins (git, autosuggestions, syntax-highlighting)
- **Reason**: Oh My Posh is cross-platform, has 170+ themes, and doesn't depend on Oh My Zsh for theming.

### zsh/.zshrc + install.sh — Replaced nvm with fnm
- Removed nvm initialization block from `.zshrc`
- Added `eval "$(fnm env --use-on-cd --shell zsh)"` — auto-switches Node versions on `cd` into dirs with `.nvmrc`/`.node-version`
- `install.sh` Linux section: replaced nvm curl install with fnm (`https://fnm.vercel.app/install`)
- Removed duplicate bun export block in `.zshrc`
- **Reason**: fnm is significantly faster than nvm (Rust-based), supports `.nvmrc` out of the box with `--use-on-cd`, and has simpler shell init.

### git/.gitconfig + install.sh — Git identity moved to install prompt
- Removed hardcoded `user.name` and `user.email` from `.gitconfig`
- `install.sh` now prompts for name and email during installation
- Input validation: name must be 2+ chars, email must match standard format
- Skips prompt if git identity is already configured
- `today` alias now dynamically reads `git config user.name` instead of hardcoded author
- **Reason**: Personal credentials shouldn't be in a shared dotfiles repo. Each user should provide their own identity at install time.

### tmux/.tmux.conf — Window keybinding changes
- New window: `prefix + n` (was `prefix + c`)
- Window cycling: `Alt+Tab` (next) / `Alt+Shift+Tab` (previous), no prefix needed
- Enabled `extended-keys` and `terminal-features` for CSI u key support (requires tmux 3.3+)
- **Reason**: More intuitive keybindings — `n` for "new", Ctrl+Tab matches browser/IDE muscle memory.

### install.sh — Full rewrite with OS detection
- Added `detect_os()` function using `$OSTYPE` and `/etc/os-release`
- **macOS path**: unchanged (Xcode CLI tools, Homebrew, `brew bundle`)
- **Linux path**: apt packages, Neovim via PPA, nvm/pyenv/zoxide via install scripts
- **GNOME keyboard**: `gsettings` to remap Super → Ctrl (macOS-style shortcuts)
- **Shared steps**: backup, stow, TPM, Oh My Zsh, zsh plugins, Powerlevel10k, git config, directory creation, default shell
- **Reason**: Original script only supported macOS. Needed to work on Ubuntu/Debian with equivalent tools.

### tmux/.tmux.conf — Restored full config + cross-platform fixes
- Restored full config that was wiped by `stow --adopt` (was reduced to 4 lines)
- Prefix `Ctrl-a`, all keybindings, status bar, plugins, copy mode — all restored
- `pbcopy` → `if-shell` conditional: `pbcopy` on macOS, `xclip -selection clipboard` on Linux
- `open` → `if-shell` conditional: `open` on macOS, `xdg-open` on Linux (URL opener)
- `cursor` → `${EDITOR:-nvim}` for log file opening (was hardcoded to Cursor editor)
- `@continuum-boot` options wrapped in macOS-only `if-shell`
- Help guide path updated from `~/Projects/dotfiles/` to `~/Sites/dotfiles/`
- Added `set -g set-clipboard on` for OSC 52 clipboard passthrough (iTerm2/SSH)
- **Reason**: `stow --adopt` replaced the repo's full config with the user's local minimal version. Cross-platform conditionals needed for clipboard and URL handling.

### tmux/.tmux/cpu.sh — Cross-platform CPU monitoring
- Added `$OSTYPE` detection
- macOS: `top -l 2` (existing)
- Linux: `top -bn1 | grep "Cpu(s)"`
- **Reason**: macOS `top` flags are incompatible with Linux `top`.

### tmux/.tmux/memory.sh — Cross-platform memory monitoring
- Added `$OSTYPE` detection
- macOS: `memory_pressure` (existing)
- Linux: `free | awk`
- **Reason**: `memory_pressure` command doesn't exist on Linux.

### tmux/.tmux/battery.sh — Cross-platform battery monitoring
- Added `$OSTYPE` detection
- macOS: `pmset -g batt` (existing)
- Linux: reads from `/sys/class/power_supply/BAT0` (with BAT1 fallback)
- **Reason**: `pmset` is macOS-only. Linux exposes battery info via sysfs.

### zsh/.zshrc — Removed hardcoded macOS paths
- All `/Users/raulgavris/` paths replaced with `$HOME`
- Java/Android block wrapped in `if [[ "$OSTYPE" == "darwin"* ]]` with Linux fallback for `/usr/lib/jvm/`
- nvm: added Linux fallback (`$NVM_DIR/nvm.sh`) alongside Homebrew path
- `brewup` alias wrapped in macOS conditional
- Deduplicated Antigravity export
- **Reason**: Hardcoded paths broke on any machine that wasn't the original author's Mac.

### nvim/.config/nvim/lua/plugins/telescope.lua — Removed hardcoded project paths
- Replaced `/Users/raulgavris/Projects/...` entries with `vim.fn.expand("~/Sites/")`
- Left commented example for adding custom project directories
- **Reason**: Hardcoded paths caused "not accessible by the current user" errors on other machines.

### nvim/.config/nvim/lua/plugins/treesitter.lua — Fixed config errors
- Changed `require("nvim-treesitter.config")` to `require("nvim-treesitter.configs")` (module name was wrong — singular vs plural)
- Removed `swift` from `ensure_installed` (fails to compile on Linux due to `tree-sitter-cli` version mismatch, not needed outside macOS)
- Removed deprecated options that newer nvim-treesitter rejects:
  - `autopairs` — now handled by nvim-autopairs plugin directly
  - `autotag` — now handled by nvim-ts-autotag plugin directly
  - `context_commentstring` — now handled by nvim-ts-context-commentstring plugin directly
  - `highlight.disable = ""` — changed to `{}` (wrong type, must be a table)
- **Reason**: Config was written for an older nvim-treesitter version. The module system was removed and these options moved to their respective plugins.

### nvim/.config/nvim/lua/core/options.lua — OSC 52 clipboard
- Added `vim.g.clipboard` with OSC 52 provider as default
- Works across SSH, iTerm2, Termux, any modern terminal
- No dependency on `xclip`, `pbcopy`, or X server
- **Reason**: `checkhealth` showed "No clipboard tool found" over SSH. OSC 52 works universally through terminal escape sequences.

### keyd/ — Removed entirely
- Removed keyd stow package and all references
- keyd operated at kernel level, couldn't be scoped to GUI-only apps
- Caps Lock → Esc remapping affected terminal (unwanted)
- Super → Ctrl mappings broke GNOME shortcuts (Super+A, Super+L)
- keyd v2.6.0 crashed with SEGV on reload
- **Replaced with**: GNOME native `gsettings` XKB option `altwin:ctrl_win` — makes Super/Win keys act as Ctrl without affecting other keys
- **Reason**: keyd was too aggressive (system-wide, kernel-level). GNOME native approach is simpler, doesn't require building from source, and integrates properly with the desktop environment.

### nvim/.config/nvim/lua/plugins/treesitter.lua — Rewritten for nvim-treesitter v1.0+
- `:Lazy sync` pulled the new nvim-treesitter which removed the `configs` module entirely
- Changed `require("nvim-treesitter.configs").setup()` to `require("nvim-treesitter").setup()`
- `ensure_installed`, `highlight`, `indent`, `auto_install` options removed (no longer part of the API)
- Parser installation now uses `require("nvim-treesitter.install").install()` programmatically
- Removed `jsonc` parser (unsupported in new version)
- Highlight and indentation are now built into Neovim 0.11+ natively
- **Reason**: nvim-treesitter v1.0+ completely rewrote the API. The old `configs` module no longer exists.

### nvim/.config/nvim/lua/plugins/bufferline.lua — Fixed buffer close behavior
- Changed mode from `"tabs"` to `"buffers"` (tabs mode crashed when closing the last tab)
- Added `close_command` and `right_mouse_command` to use `mini.bufremove` instead of `:bdelete`
- **Reason**: Closing the last buffer/tab via the X button or keybind was exiting nvim entirely. `mini.bufremove` switches to another buffer instead.

### nvim/.config/nvim/lua/core/keymaps.lua — Notification dismiss + terminal + buffer close fixes
- Added `<Esc>` mapping to dismiss Noice notifications and clear search highlights
- Added `<leader>nd` mapping to dismiss notifications explicitly
- Added `<A-t>` (Alt+T) to normal and terminal modes for FTerm toggle (was only in insert mode)
- Changed `<C-w>` close buffer to use `mini.bufremove` instead of `:bdelete`
- **Reason**: No way to dismiss notification popups. Terminal toggle only worked in insert mode. Buffer close exited nvim on last buffer.

### tmux/.tmux.conf — Removed conflicting themepack plugin
- Removed `jimeh/tmux-themepack` plugin
- **Reason**: themepack had a custom `raul.tmuxtheme` that was overriding the onedark theme's status-right, hiding the CPU/memory/battery widgets. Two theme plugins were fighting over the status bar.

### Documentation updates
- **README.md**: Rewritten for cross-platform support, updated structure, installation steps, troubleshooting
- **CLAUDE.md**: Updated to reflect cross-platform architecture, removed keyd references
- **TMUX_GUIDE.md**: Updated paths from `~/Projects/dotfiles/` to `~/Sites/dotfiles/`
- **nvim/README.md**: Updated author line
- **Authors**: Added Ice alongside Raul Gavris in README.md, nvim/README.md, install.sh
