# Neovim Setup Plan: LazyVim for VS Code Users

## Context

Fresh Neovim config based on **LazyVim distro** for a developer transitioning from VS Code/WebStorm. Primary languages: TypeScript/Node.js/Go. Formatter: Biome. Must be fast, discoverable, and UX-friendly with a custom top navigation menu.

All previous nvim files were deleted. Started from scratch.

## Architecture Decisions

### Why LazyVim?
- Pre-configured, maintained distro — no need to wire up LSP, treesitter, formatters manually
- Extras system for language support (TypeScript, Go, JSON, Biome)
- Snacks.nvim ecosystem (picker, lazygit, terminal, notifications)
- blink.cmp for fast completion
- Active community and regular updates

### Key Adaptations from Previous Config
- **Snacks.picker** replaces Telescope (LazyVim default)
- **blink.cmp** replaces nvim-cmp (LazyVim v14+ default)
- **Built-in flash/mini.comment** replaces separate plugins
- **Custom command palette** (`Ctrl+P`) carried forward with `vim.ui.select`
- **Custom menu bar** using tabline + floating windows (unique feature)

### Menu Bar Architecture
- **Tabline** (vim.o.tabline) renders the always-visible category bar at the topmost position
- Click handlers via `%N@v:lua.MenuBarClick@` tabline format
- **Floating windows** (focusable, zindex 250) for dropdown menus
- Dropdowns support both keyboard (h/j/k/l/Enter/Esc) and mouse (click to execute)
- `CursorMoved` autocmd skips separator lines
- `WinLeave` autocmd closes dropdown when clicking outside
- Lualine winbar replaces bufferline for buffer tabs (below menu, above content)

### Project Switcher
- Scans `persistence.nvim` saved sessions (~/.local/state/nvim/sessions/)
- Decodes session filenames back to directory paths
- Filters to existing directories, sorts by most recently used
- On selection: closes all buffers, cd's to project, loads session
- Available via `<leader>fp`, command palette, menu bar, and welcome screen

### Formatting Strategy
- Biome as the sole formatter for JS/TS/JSON (no prettier conflict)
- `require_cwd = true` — biome only activates in projects with biome.json
- LazyVim's conform.nvim handles the integration

## File Inventory (13 files)

| File | Purpose |
|------|---------|
| `init.lua` | Bootstrap lazy.nvim |
| `lua/config/lazy.lua` | LazyVim core + extras (TS, Go, JSON, Biome) |
| `lua/config/options.lua` | Absolute line numbers, 2-space indent, system clipboard |
| `lua/config/keymaps.lua` | VS Code keybindings, command palette, all leader groups |
| `lua/config/autocmds.lua` | Go tabs/4-wide, TS spaces/2-wide |
| `lua/plugins/colorscheme.lua` | OneDark "darker" (matches tmux) |
| `lua/plugins/editor.lua` | Neo-tree, which-key, vim-tmux-navigator, Claude Code |
| `lua/plugins/ui.lua` | Lualine (statusline + winbar), mini.starter, noice |
| `lua/plugins/coding.lua` | blink.cmp with Tab/Enter |
| `lua/plugins/formatting.lua` | Biome-only for JS/TS/JSON |
| `lua/plugins/lang.lua` | Extra treesitter parsers, vtsls relative imports |
| `lua/plugins/menu.lua` | Top nav menu bar (tabline + floating dropdowns) |
| `lazyvim.json` | Extras manifest for first boot |

## Modified Files

| File | Change |
|------|--------|
| `install.sh` | Added nvim first-launch hint and menu bar hint to "Next steps" |

## Screen Layout (top to bottom)

```
┌─────────────────────────────────────────────────────┐
│ File  Edit  View  Search  Code  Git  Terminal       │ ← Tabline (menu bar)
├─────────────────────────────────────────────────────┤
│ [buf1.ts] [buf2.go] [buf3.json]                     │ ← Winbar (lualine buffers)
├──────────┬──────────────────────────────────────────┤
│ Neo-tree │  Editor content                          │
│          │                                          │
│          │                                          │
├──────────┴──────────────────────────────────────────┤
│ NORMAL │ main │ utf-8 │ typescript │ 42:15          │ ← Statusline (lualine)
├─────────────────────────────────────────────────────┤
│ :                                                   │ ← Cmdline
└─────────────────────────────────────────────────────┘
```

## Known Limitations

- **Biome requires biome.json**: Projects without it get no JS/TS formatting. Add prettier fallback later if needed.
- **Menu click executes immediately**: Single click on dropdown item runs the action (no hover-then-click pattern).
- **F10 repurposed**: Previous config used F10 for debug step-over. Now it's the menu bar. Debug step-over moved to `<leader>do`.
- **Buffer tabs per-window**: Lualine winbar shows in each window (splits). Acceptable trade-off for menu at top.
- **mini.starter**: LazyVim uses mini.starter for the welcome screen (not dashboard-nvim or snacks.dashboard).
