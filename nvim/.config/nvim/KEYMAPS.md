# Neovim Keymaps & Features Guide

Leader key is **Space**.

---

## Quick Open / Command Palette (like VS Code)

| VS Code | Neovim | What it does |
|---------|--------|-------------|
| `Cmd+P` | `<leader>ff` | Find files by name |
| `Cmd+Shift+P` | `<leader>cp` | Command palette (MRU tracking, recently used float to top) |
| `Cmd+Shift+F` | `<leader>fg` | Search across all files (live grep) |
| `Cmd+T` | `<leader>:` | All available commands |
| | `<leader>fr` | Recent files |
| | `<leader>fb` | Open buffers |
| | `<leader>ch` | Command history |
| | `<leader>fp` | **Switch project (workspace)** |
| | `<leader>u` | Undo tree (visual, browse and restore) |

---

## Workspaces (Multi-Root, like VS Code)

Open multiple repos in one session -- all visible in the file tree, searchable together.

### Define Workspaces

Edit `lua/core/workspaces.lua` to define your workspaces:

```lua
M.workspaces = {
    houdini = {
        "~/Projects/pws/houdiniswap-backend",
        "~/Projects/pws/houdini-swap-web",
        "~/Projects/pws/tokenexchange-admin",
    },
    myapp = {
        "~/Projects/myapp-frontend",
        "~/Projects/myapp-backend",
    },
}
```

### Workspace Keymaps

| Action | Keymap |
|--------|--------|
| **Select/open workspace** | `<leader>ws` |
| Find files across all repos | `<leader>wf` |
| Grep across all repos | `<leader>wg` |
| Grep word across all repos | `<leader>ww` |
| Show workspace info | `<leader>wi` |
| Close workspace | `<leader>wc` |

How it works:
- `<leader>ws` opens a picker showing all defined workspaces with their repos
- Selecting one: creates a workspace directory with all repos as folders, Neo-tree shows them all side by side
- `<leader>wf` / `<leader>wg` search across ALL repos in the workspace simultaneously
- Each repo keeps its own git status, LSP, etc.

### Single Project Switching

| Action | Keymap |
|--------|--------|
| Switch project (single) | `<leader>fp` |
| Restore session | `<leader>qs` |
| Restore last session | `<leader>ql` |
| Stop auto-saving session | `<leader>qd` |

- `<leader>fp` opens a project picker scanning `~/Projects/` (up to 2 levels deep), sorted by recent use
- Sessions auto-save per directory when you quit

---

## Search & Replace

| Action | Keymap | Notes |
|--------|--------|-------|
| Search in current file | `<leader>f/` | Fuzzy find in buffer (like Cmd+F) |
| Search word under cursor | `<leader>fc` | Grep for current word across project |
| Search & Replace (project-wide) | `<leader>S` | Opens grug-far (async, better than VS Code's) |
| Search current word (replace) | `<leader>Sw` | Pre-fills current word in grug-far |
| Search in current file only | `<leader>Sf` | Scoped to current file |
| Native search | `/` then type | Standard Vim search, `n`/`N` to jump |
| Clear search highlights | `Esc` | Clears highlight after searching |

---

## Git Integration

### Inline Changes (like VS Code gutter colors)

Gitsigns shows **green** (added), **blue** (changed), **red** (deleted) markers in the sign column automatically. Plus:

| Action | Keymap |
|--------|--------|
| **Inline blame** (who changed this line) | Shown automatically at end of each line (git-blame) |
| Full blame popup | `<leader>gl` |
| Preview hunk diff | `<leader>gp` |
| Next/prev changed hunk | `]h` / `[h` |
| Stage hunk | `<leader>hs` |
| Reset hunk (discard change) | `<leader>hr` |
| Undo stage hunk | `<leader>hu` |
| Stage entire buffer | `<leader>hS` |
| Reset entire buffer | `<leader>hR` |
| Diff this file | `<leader>hd` |

### Git Operations

| Action | Keymap |
|--------|--------|
| **LazyGit** (full Git TUI) | `<leader>gg` |
| Git status (telescope) | `<leader>gs` |
| Git branches | `<leader>gb` |
| Git commits (project) | `<leader>gc` |
| Git commits (this file) | `<leader>gfc` |
| Git status in Neo-tree | `<leader>ge` |

### Diffview (side-by-side diffs)

| Action | Keymap |
|--------|--------|
| Open diffview | `<leader>gdo` |
| Close diffview | `<leader>gdc` |
| File history (all files) | `<leader>gdh` |
| Current file history | `<leader>gdH` |

### Git Conflicts (like VS Code inline conflict resolution)

`git-conflict.nvim` shows inline markers with options when you hit a merge conflict:

| Action | Keymap |
|--------|--------|
| Choose ours (current) | `co` |
| Choose theirs (incoming) | `ct` |
| Choose both | `cb` |
| Choose none | `c0` |
| Next/prev conflict | `]x` / `[x` |

### GitHub PRs (Octo)

| Action | Command |
|--------|---------|
| List PRs | `:Octo pr list` |
| Create PR | `:Octo pr create` |
| Review PR | `:Octo review start` |
| Comment | `:Octo comment add` |
| Approve/Request changes | `:Octo review submit` |

---

## AI Integration (Claude Code)

| Action | Keymap |
|--------|--------|
| Toggle Claude terminal | `<leader>ac` |
| Focus Claude panel | `<leader>af` |
| Resume conversation | `<leader>ar` |
| Continue conversation | `<leader>aC` |
| Select model | `<leader>am` |
| Add current buffer to context | `<leader>ab` |
| Accept diff suggestion | `<leader>aa` |
| Deny diff suggestion | `<leader>ad` |
| Send selection to Claude | `<leader>as` (visual mode) |

Codeium (Windsurf) also provides inline AI completions automatically in insert mode.

---

## LSP (IntelliSense equivalent)

| VS Code Feature | Keymap | What it does |
|-----------------|--------|-------------|
| Hover info | `K` | Show type/docs popup |
| Go to definition | `gd` | Jump to definition |
| Find references | `gR` | All references |
| Type definition | `<leader>lt` | Go to type definition |
| Implementations | `<leader>li` | Go to implementations |
| Code action (lightbulb) | `<leader>la` | Quick fixes, refactors |
| Rename symbol | `<leader>rn` | Live preview rename (pre-fills current word) |
| Format document | `<leader>lf` | Format (prefers Prettier/stylua via none-ls) |
| Line diagnostics | `<leader>ld` | Show error/warning on current line |
| Buffer diagnostics | `<leader>lD` | All diagnostics in file |
| Next/prev error | `]d` / `[d` | Jump between diagnostics |
| Restart LSP | `<leader>lr` | When things get stuck |

---

## TypeScript-Specific (typescript-tools.nvim)

| Action | Keymap |
|--------|--------|
| Organize imports | `<leader>roi` |
| Sort imports | `<leader>ros` |
| Remove unused imports | `<leader>ru` |
| Add missing imports | `<leader>ri` |
| Fix all errors | `<leader>ra` |
| Rename file (updates imports) | `<leader>rf` |
| Go to source definition | `<leader>rd` |

All also available via `<leader>cp` command palette.

---

## Comments

| Action | Keymap |
|--------|--------|
| Toggle line comment | `gcc` |
| Toggle block comment | `gbc` |
| Comment with motion | `gc` + motion (e.g. `gcip` = comment paragraph) |
| Block comment with motion | `gb` + motion |
| Comment above | `gcO` |
| Comment below | `gco` |
| Comment end of line | `gcA` |
| Visual: comment selection | Select lines, then `gc` |

Automatically uses correct comment syntax per language (JSX, HTML, CSS, etc. via treesitter context).

---

## File Explorer (Neo-tree, like VS Code sidebar)

| Action | Keymap |
|--------|--------|
| Toggle file tree | `<leader>e` |
| Focus file tree | `<leader>E` |
| Inside tree: open file | `Enter` |
| Split vertical | `s` |
| Split horizontal | `S` |
| Create file | `a` |
| Create directory | `A` |
| Delete | `d` |
| Rename | `r` |
| Copy/Cut/Paste | `y` / `x` / `p` |
| Toggle hidden files | `H` |
| Fuzzy find in tree | `/` |
| Toggle preview | `P` |

---

## Tabs / Buffers

| Action | Keymap |
|--------|--------|
| Delete buffer (close tab) | `<leader>bd` |
| Force delete buffer | `<leader>bD` |
| Close all other buffers | `<leader>bo` |
| Switch buffers | `<leader>fb` (telescope) |

Bufferline shows tabs at the top with LSP diagnostics.

---

## Splits / Windows

| Action | Keymap |
|--------|--------|
| Split vertical | `<leader>sv` |
| Split horizontal | `<leader>sh` |
| Equalize splits | `<leader>se` |
| Close split | `<leader>sq` |
| Navigate splits | `Ctrl+h/j/k/l` (works across tmux too) |

---

## Terminal

| Action | Keymap |
|--------|--------|
| Toggle floating terminal | `Alt+t` |
| Exit terminal mode | `Esc` |

---

## Debugging (DAP, like VS Code debugger)

| Action | Keymap |
|--------|--------|
| Toggle breakpoint | `<leader>db` |
| Conditional breakpoint | `<leader>dB` |
| Start / Continue | `<leader>dc` |
| Step over | `<leader>do` |
| Step into | `<leader>di` |
| Step out | `<leader>dO` |
| Toggle REPL | `<leader>dr` |
| Run last | `<leader>dl` |
| Terminate | `<leader>dt` |
| Toggle debug UI | `<leader>du` |
| Hover variables | `<leader>dh` |
| Pause | `<leader>dp` |
| Restart | `<leader>dR` |

Supports: JavaScript, TypeScript, React (Chrome), Python, C/C++. Auto-opens/closes debug UI.

---

## Testing (Neotest)

| Action | Keymap |
|--------|--------|
| Run nearest test | `<leader>tt` |
| Run file tests | `<leader>tf` |
| Run all tests | `<leader>ta` |
| Run last test | `<leader>tl` |
| Toggle summary panel | `<leader>ts` |
| Show output | `<leader>to` |
| Toggle output panel | `<leader>tO` |
| Stop tests | `<leader>tS` |
| Watch mode | `<leader>tw` |
| Debug nearest test | `<leader>td` |

Supports: Jest, Vitest, pytest.

---

## Diagnostics Panel (Trouble, like VS Code Problems tab)

| Action | Keymap |
|--------|--------|
| All diagnostics | `<leader>xx` |
| Buffer diagnostics | `<leader>xX` |
| Symbols outline | `<leader>xs` |
| LSP definitions/references | `<leader>xl` |
| Location list | `<leader>xL` |
| Quickfix list | `<leader>xQ` |
| Todo comments | `<leader>xt` |
| Todo/Fix/Fixme only | `<leader>xT` |
| Next/prev todo | `]t` / `[t` |

---

## Code Outline (Aerial, like VS Code breadcrumbs/outline)

| Action | Keymap |
|--------|--------|
| Toggle outline sidebar | `<leader>oo` |
| Open outline | `<leader>oO` |
| Jump prev/next symbol | `{` / `}` (in aerial-attached buffers) |

Breadcrumbs (barbecue) show file path + symbol hierarchy at the top of every buffer automatically.

---

## Sticky Scroll (treesitter-context)

Shows the function/class context at the top of the buffer when you scroll down -- same as VS Code's sticky scroll. Shows up to 3 lines. Enabled automatically.

---

## Surround (like VS Code bracket tools)

Uses `gs` prefix to avoid conflict with Flash:

| Action | Keymap | Example |
|--------|--------|---------|
| Add surround | `gsa` + motion + char | `gsaiw"` = surround word with `"` |
| Delete surround | `gsd` + char | `gsd"` = delete surrounding `"` |
| Replace surround | `gsr` + old + new | `gsr"'` = change `"` to `'` |

---

## Fast Navigation (Flash, like VS Code Ctrl+G on steroids)

| Action | Keymap |
|--------|--------|
| Flash jump (2-char search) | `s` then type 2 chars |
| Flash treesitter (select node) | `S` |
| Remote flash (operator pending) | `r` (e.g. `yr` = yank to flash target) |

---

## Tailwind CSS

| Action | Keymap |
|--------|--------|
| Sort classes | `<leader>Ts` |
| Toggle color preview | `<leader>Tc` |
| Toggle conceal (hide long classes) | `<leader>Tx` |
| Browse utilities | `<leader>Tu` |

Inline color swatches shown automatically in JSX/HTML files.

---

## Session Management

| Action | Keymap |
|--------|--------|
| Restore session (current dir) | `<leader>qs` |
| Restore last session | `<leader>ql` |
| Stop auto-saving session | `<leader>qd` |

---

## Other Useful Keys

| Action | Keymap |
|--------|--------|
| Move line up/down | `Alt+k` / `Alt+j` (works in all modes) |
| Yank entire file | `<leader>Y` |
| Dismiss notifications | `<leader>nd` |
| Indent in visual mode | `Tab` / `Shift+Tab` |
| Join selected lines | `<leader>j` (visual) |
| Visual command palette | `<leader>cp` (in visual mode -- has selection-aware actions) |
| Replace with register | `gr` + motion (e.g. `griw` replaces word with register) |
| Multi-cursor | `Ctrl+n` (vim-visual-multi, like Cmd+D) |

---

## Discovering More

Press **Space** and wait -- which-key shows all available leader groups with descriptions. Each sub-group expands as you type.
