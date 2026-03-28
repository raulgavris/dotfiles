# Neovim Configuration

LazyVim-based Neovim setup for developers transitioning from VS Code/WebStorm. Primary languages: TypeScript, Node.js, Go. Formatter: Biome.

## Layout

VS Code-style layout managed by [edgy.nvim](https://github.com/folke/edgy.nvim):

```
┌──────────┬───────────────────────┬──────────┐
│ Files |  │  Editor (buffer tabs) │  Claude  │
│ Git |    │                       │  Code    │
│ Debug    ├───────────────────────┤          │
│          │  Terminal / Console   │          │
└──────────┴───────────────────────┴──────────┘
     ↑ Menu Bar always visible at the very top ↑
```

- **Left sidebar**: Tabbed panel with **Files | Git | Debug** tabs (width 35)
  - **Files**: Neo-tree file explorer (default)
  - **Git**: Source Control panel — staged/unstaged/untracked sections with inline diff
  - **Debug**: DAP UI panels (appears when debugger is active)
- **Bottom panel**: Terminals, QuickFix, Diagnostics, Debug REPL/Console
- **Right sidebar**: Claude Code (width 80), Symbols Outline
- **Editor area**: Buffer tabs in the winbar, one tab per open file
- All panels have **x close buttons** — click to dismiss

## Features

### Menu Bar
A permanent VS Code-style menu bar at the top of the screen with clickable categories:

**File | Edit | View | Search | Code | Debug | Git | Terminal**

- Always visible in the tabline (topmost position)
- Click a category or press **F10** to open its dropdown
- Dropdowns show actions with their keyboard shortcuts
- Navigate: `h`/`l` between categories, `j`/`k` within items, `Enter` to execute, `Esc` to close
- Mouse: click items directly

### Command Palette (Ctrl+P)
Custom implementation with categorized actions and recent-command history:
- **Normal mode**: Full action list — files, code, git, debug, test, AI, editor
- **Visual mode**: Selection-aware actions — comment, format, sort, send to Claude

Recently used commands float to the top (marked with `>>`).

### Terminal Management
Custom terminal system independent of Snacks.terminal:
- **Toggle**: `` Ctrl+` `` opens/hides the bottom terminal split
- **Exit terminal mode**: `Ctrl+]` switches to normal mode (Tab in terminal passes through to shell for autocomplete)
- **Tabs**: Each terminal gets a tab in the terminal winbar with a close button
- **New tab**: Click the `+` button in the terminal tab bar
- **Switch tabs**: Click terminal tabs to switch between them
- Terminals are routed to the bottom panel by edgy.nvim (not floating)

### Right-Click Context Menu
Full context menu with aligned keyboard shortcuts:

| Section | Actions |
|---------|---------|
| **Navigation** | Go to Definition (F12), References (S-F12), Type (gt) |
| **Code** | Hover Docs (K), Code Actions (Space+ca), Rename (F2), Format (Space+cf) |
| **Git (per-line)** | Preview Hunk, Stage Hunk, Reset Hunk, Blame Line |
| **Edit** | Toggle Comment (Ctrl-/), Cut (Ctrl-X), Copy (Ctrl-C), Paste (Ctrl-V) |

### UI & Appearance
- **Theme**: OneDark "darker" (matches tmux theme)
- **Statusline**: Lualine (onedark theme)
- **Buffer tabs**: Custom winbar — editor gets file tabs, terminals get terminal tabs
- **Panel titles**: Sidebar/panel windows show their name + close button
- **Dashboard**: mini.starter with project picker
- **Noice**: Modern UI for messages and cmdline (bottom bar style)

### Git Integration
- **Source Control panel**: VS Code-style sidebar tab (`<leader>gS`) with merge conflicts/staged/unstaged/untracked sections
  - Nerd Font icon toolbar at the top with branch name and ahead/behind counts
  - Action buttons (Enter or shortcut key):
    - `c` Commit, `g` AI Commit, `C` Commit All, `a` Amend
    - `p` Push, `P` Pull, `f` Fetch
    - `z` Stash, `Z` Stash Pop
    - `m` AI Merge (select branch, auto-resolve conflicts with Claude)
  - **Git Graph**: Visual commit history with branch topology below the file sections
    - Shows last 30 commits with graph lines, hashes, decorations, and messages
    - `Enter` on a commit shows full diff (`git show`) in the editor
    - Color-coded: graph lines, commit hashes, branch decorations
  - File actions:
    - `Enter` open file with inline diff (via Gitsigns diffthis)
    - `D` side-by-side diff (staged: HEAD vs index, unstaged: index vs working tree, conflicts: ours vs theirs)
    - `o` open file without diff
    - `s` / `S` stage file / stage all
    - `u` / `U` unstage file / unstage all
    - `d` discard changes (with confirmation)
    - `i` / `e` accept incoming (theirs) / accept current (ours) — merge conflicts only
    - `r` refresh, `q` close panel
  - AI Commit detects merge/squash context and uses git's prepared message instead of generating
  - Auto-refreshes on file save, terminal exit, focus, and `.git` filesystem changes
- **Gitsigns**: Gutter signs for changes, hunk navigation (`]h`/`[h`), stage/reset/preview per hunk
- **LazyGit**: Full TUI git client (`<leader>gg`)
- **codediff.nvim**: VS Code-style side-by-side diff with character-level highlighting (`<leader>gD`)
- **Snacks git**: Blame line, git status/log/diff pickers

### Claude Code Integration
Claude Code runs in its own right sidebar panel (separate from terminals):
- `<leader>ac` Toggle Claude
- `<leader>af` Focus Claude
- `<leader>ar` Resume conversation
- `<leader>aC` Continue conversation
- `<leader>as` Send selection (visual mode)
- `<leader>ab` Add current buffer to Claude
- `<leader>am` Select Claude model
- `<leader>aa` / `<leader>ad` Accept / Deny diff

### Navigation
- **Flash**: Lightning-fast jump (`s` to search, `S` treesitter select)
- **Snacks picker**: Fuzzy finder for files, grep, symbols, git
- **Neo-tree**: File explorer sidebar (`Ctrl+B`)
- **vim-tmux-navigator**: Seamless `Ctrl+h/j/k/l` between nvim splits and tmux panes
- **Tab/Shift+Tab**: Cycle between layout areas (editor, sidebar, terminal)
- **H/L** or **[b/]b**: Navigate between open buffers

### Debugging (DAP)
Full debug adapter protocol support with auto-installing debuggers:
- **JS/TS**: pwa-node (attach, launch, ts-node), pwa-chrome (React/browser)
- **Jest**: Debug individual test files or full suite
- **DAP UI**: Auto-opens in the **Debug** sidebar tab on debug start (scopes, breakpoints, stacks, watches, REPL, console)
- **Virtual text**: Shows variable values inline while debugging
- Breakpoint signs with custom colors (red dot, yellow conditional, green stopped arrow)
- Sidebar auto-switches between Files and Debug tabs on debug start/stop

### Testing (Neotest)
Test runner framework with adapters for Jest and Vitest:
- `<leader>tn` Run nearest test
- `<leader>tf` Run file tests
- `<leader>ta` Run all tests
- `<leader>td` Debug nearest test (via DAP)
- `<leader>ts` Toggle test summary
- `<leader>tw` Toggle watch mode

### Search & Replace
- **grug-far**: Project-wide search and replace using ripgrep for both search and replace (`<leader>sR`)
- **Snacks picker grep**: Quick search across files (`F4`, `<leader>sg`)

### LSP & Completion
- **vtsls**: TypeScript/JavaScript (relative import paths)
- **gopls**: Go (with goimports, gofumpt)
- **jsonls**: JSON with schemastore
- **blink.cmp**: Completion — Tab/Shift+Tab to navigate, Enter to accept, Ctrl+Space to trigger
- **Codeium**: AI inline completions (ghost text, Tab to accept) — requires `:Codeium Auth` on first use
- **Biome**: Formatting for JS/TS/JSON (only activates in projects with `biome.json`)

### Language Enhancements
- **nvim-ts-autotag**: Auto-close and rename HTML/JSX/TSX tags
- **nvim-colorizer**: Inline color previews for hex, CSS, and Tailwind colors
- **rainbow-delimiters**: Colorize matching brackets and parentheses
- **vim-visual-multi**: VS Code-style multi-cursor editing (Ctrl+D for next occurrence, Ctrl+click)
- **nvim-lightbulb**: VS Code-style lightbulb icon when code actions are available

## Key Bindings

### Leader Key: Space

### VS Code Style

| Key | Action |
|-----|--------|
| `Ctrl+P` | Command palette |
| `F4` | Search/grep in project |
| `Ctrl+F` | Search in current buffer |
| `Ctrl+S` | Save file |
| `Ctrl+B` | Toggle file explorer |
| `` Ctrl+` `` | Toggle terminal |
| `Ctrl+W` | Close current buffer |
| `Ctrl+/` | Toggle comment |
| `Ctrl+C` | Copy selection to clipboard |
| `Ctrl+X` | Cut line / cut selection to clipboard |
| `Ctrl+V` | Paste from clipboard |
| `Ctrl+Z` / `Ctrl+Y` | Undo / Redo |
| `Ctrl+A` | Select all |
| `Ctrl+.` | Quick fix / Code actions (lightbulb) |
| `Ctrl+G` | Go to line |
| `Ctrl+D` | Multi-cursor: add next occurrence |
| `Shift+Up/Down/Left/Right` | Select lines / characters |
| `Backspace` / `Delete` | Delete selection (visual mode) |
| `Alt+Shift+J/K` | Duplicate line down/up |
| `Tab` / `Shift+Tab` | Cycle windows (normal mode) |
| `Ctrl+]` | Exit terminal mode to normal mode |
| `F2` | Rename symbol |
| `F5` | Debug: Start/Continue |
| `F9` | Debug: Toggle breakpoint |
| `Ctrl+F10` | Toggle menu bar |
| `F10` | Debug: Step over |
| `F11` | Debug: Step into |
| `F12` | Go to definition |
| `Shift+F12` | Go to references |
| `Alt+J/K` | Move line up/down |
| `Alt+Shift+J/K` | Duplicate line down/up |
| `Alt+I` | Toggle Claude Code |
| `Alt+M` | Toggle menu bar |

### Leader Groups

| Prefix | Group | Key Examples |
|--------|-------|-------------|
| `<leader>f` | File/Find | `ff` files, `fp` projects, `fg` grep, `fr` recent, `fb` buffers, `fc` word under cursor |
| `<leader>c` | Code | `ca` actions, `cr` rename, `cf` format, `cs` symbols, `cl` LSP refs |
| `<leader>g` | Git | `gg` lazygit, `gs` status, `gS` source control, `gb` log, `gd` diff, `gB` blame, `gD` side-by-side diff |
| `<leader>s` | Search | `sg` grep, `sw` word, `sk` keymaps, `st` todos, `sr` resume, `sR` replace (grug-far), `sh` help |
| `<leader>d` | Debug | `db` breakpoint, `dB` conditional, `dc` continue, `di` step in, `do` step over, `dO` step out, `dt` terminate, `du` DAP UI |
| `<leader>x` | Diagnostics | `xx` all, `xX` buffer, `xt` todos, `xL` loclist, `xQ` quickfix |
| `<leader>a` | AI (Claude) | `ac` toggle, `af` focus, `ar` resume, `aC` continue, `as` send, `ab` add buffer, `am` model, `aa` accept, `ad` deny |
| `<leader>t` | Test | `tn` nearest, `tf` file, `ta` all, `td` debug, `ts` summary, `to` output, `tw` watch, `tS` stop |
| `<leader>o` | Organize | `oi` organize imports, `os` sort imports |
| `<leader>q` | Session | `qs` restore, `ql` last, `qd` don't save |
| `<leader>n` | Notifications | `nd` dismiss |
| `<leader>M` | Menu bar | Toggle top menu |

### LSP Navigation

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gR` | Go to references |
| `gi` | Go to implementation |
| `gt` | Go to type definition |
| `K` | Hover documentation |

### Visual Mode

| Key | Action |
|-----|--------|
| `Ctrl+P` | Command palette (selection-aware) |
| `Ctrl+C` | Copy to clipboard |
| `Ctrl+X` | Cut to clipboard |
| `Ctrl+V` | Paste from clipboard |
| `Ctrl+/` | Toggle comment |
| `Ctrl+.` | Quick fix / Code actions |
| `Tab` / `Shift+Tab` | Indent / Outdent |
| `Shift+Up/Down/Left/Right` | Extend selection |
| `Backspace` / `Delete` | Delete selection |
| `Alt+J/K` | Move selection up/down |
| `Alt+Shift+J/K` | Duplicate selection down/up |
| `<leader>as` | Send selection to Claude |

### Git Hunks (via gitsigns)

| Key | Action |
|-----|--------|
| `]h` / `[h` | Next / previous hunk |
| `<leader>ghp` | Preview hunk |
| `<leader>ghs` | Stage hunk |
| `<leader>ghr` | Reset hunk |
| `<leader>ghS` | Stage buffer |
| `<leader>ghR` | Reset buffer |

## Configuration Structure

```
nvim/.config/nvim/
├── init.lua                     # Bootstrap lazy.nvim
├── lazyvim.json                 # LazyVim extras manifest
└── lua/
    ├── config/
    │   ├── lazy.lua             # lazy.nvim + LazyVim setup + extras
    │   ├── options.lua          # Vim options (absolute lines, 2-space indent)
    │   ├── keymaps.lua          # VS Code keybindings + command palette
    │   ├── autocmds.lua         # Filetype settings (Go tabs, TS spaces), session restore
    │   └── git-panel.lua        # Source Control sidebar (staged/unstaged/untracked sections)
    └── plugins/
        ├── colorscheme.lua      # OneDark "darker"
        ├── editor.lua           # Neo-tree, which-key, tmux-nav, Claude, codediff, grug-far, visual-multi
        ├── ui.lua               # Winbar tabs, sidebar tabs, terminal management, right-click menu, lualine, noice
        ├── layout.lua           # VS Code-style layout (edgy.nvim panels: left/bottom/right)
        ├── coding.lua           # blink.cmp completion
        ├── dap.lua              # Debug Adapter Protocol (JS/TS/Chrome/Jest debugging)
        ├── testing.lua          # Neotest with Jest + Vitest adapters
        ├── formatting.lua       # Biome priority for JS/TS/JSON
        ├── lang.lua             # Treesitter, vtsls, autotag, colorizer, rainbow-delimiters
        └── menu.lua             # Top navigation menu bar
```

## LazyVim Extras Enabled

- `lazyvim.plugins.extras.lang.typescript` — vtsls, TS tooling
- `lazyvim.plugins.extras.lang.go` — gopls, goimports, gofumpt
- `lazyvim.plugins.extras.lang.json` — jsonls + schemastore
- `lazyvim.plugins.extras.formatting.biome` — biome via conform.nvim
- `lazyvim.plugins.extras.ai.codeium` — AI inline completions

## First Launch

1. Open `nvim` — plugins auto-install (~30s)
2. Run `:checkhealth` to verify LSP, treesitter, formatters
3. Press **F10** or **Space M** for the menu bar
4. Press **Ctrl+P** for the command palette
5. Run `:Codeium Auth` to enable AI completions
6. Run `:Mason` to install additional language servers

## Project Switching

Press `<leader>fp` or select "Projects" from the welcome screen. This scans saved sessions from persistence.nvim, lets you pick a project, and restores the full session (open files, cursor positions, window layout).

## Customization

### Add a plugin
Create `lua/plugins/yourplugin.lua`:
```lua
return {
  "author/plugin-name",
  opts = {},
}
```

### Add a language
Enable a LazyVim extra in `lua/config/lazy.lua`:
```lua
{ import = "lazyvim.plugins.extras.lang.python" },
```

### Change theme
Edit `lua/plugins/colorscheme.lua` and update `colorscheme` in LazyVim opts.

## Troubleshooting

```vim
:Lazy sync          " Reinstall/update plugins
:Lazy health        " Check plugin health
:checkhealth        " Full health check
:LspInfo            " Check LSP status
:Mason              " Install language servers
:TSUpdate           " Update treesitter parsers
```

### Clear cache
```bash
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim
rm -rf ~/.cache/nvim
```
