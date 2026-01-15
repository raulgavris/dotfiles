# 🚀 Neovim Configuration

Modern, blazingly fast Neovim configuration with LSP, Treesitter, and tons of productivity features.

## ✨ Features

### 🎨 **UI & Appearance**
- **Theme**: OneDark (with Gruvbox available)
- **Statusline**: Lualine with git integration
- **Bufferline**: Beautiful buffer/tab line
- **Dashboard**: Custom start screen
- **Noice**: Modern UI for messages, cmdline, and popups
- **Dressing**: Better vim.ui.select and vim.ui.input
- **Fidget**: LSP progress indicator
- **Icons**: Nerd Font icons everywhere

### ⚡ **Navigation**
- **Flash**: Lightning-fast navigation (replaces Hop)
  - `s` - Jump to any word
  - `S` - Treesitter selection
- **Telescope**: Fuzzy finder with FZF native for speed
  - `<leader>ff` - Find files
  - `<leader>fg` - Live grep
  - `<leader>fb` - Buffers
  - `<leader>fr` - Recent files
- **Harpoon**: Quick file bookmarking
  - `<leader>hm` - Mark file
  - `<leader>hn/hp` - Next/Previous mark
- **Neo-tree**: Modern file explorer with git integration (`Ctrl-e`)
- **Breadcrumbs**: Visual file path and symbol location (top of window)
- **Aerial**: Symbol outline sidebar (`<leader>o`)
- **Satellite**: Code minimap on the right with diagnostics/git/search indicators

### 🔍 **Search & Replace**
- **Spectre**: Project-wide search and replace with preview
  - `<leader>S` - Toggle Spectre
  - `<leader>sw` - Search current word
  - `<leader>sp` - Search in current file
- **Telescope grep**: Blazing fast with ripgrep
- **Flash search**: Enhanced search with labels
- **Which-key**: Shows available keybindings

### 💻 **LSP & Completion**
- **Mason**: LSP/DAP/Linter manager
- **LSP Config**: Pre-configured language servers
- **LSP Saga**: Better LSP UI
- **Null-ls**: Formatters and linters
- **Nvim-cmp**: Autocompletion
- **Windsurf (Codeium)**: FREE AI-powered inline code suggestions (like Copilot!)
- **LuaSnip**: Snippet engine
- **Treesitter**: Better syntax highlighting

### 🐛 **Debugging (DAP)**
- **nvim-dap**: Debug Adapter Protocol
- **nvim-dap-ui**: Beautiful debugger UI
- **nvim-dap-virtual-text**: Inline variable values
- **Mason-DAP**: Auto-install debuggers
  - `<leader>db` - Toggle breakpoint
  - `<leader>dc` - Start/Continue
  - `<leader>di/o/O` - Step into/over/out
  - `<leader>du` - Toggle debug UI
- **Supported**: JavaScript, TypeScript, Python, and more

### 📝 **Editing**
- **Mini.nvim suite**:
  - **mini.ai**: Better text objects
  - **mini.surround**: Add/delete/change surroundings
  - **mini.pairs**: Auto-close brackets
  - **mini.bufremove**: Better buffer deletion
  - **mini.indentscope**: Indent guides
  - **mini.animate**: Smooth cursor movements
- **Comment**: Smart commenting
- **Autopairs**: Auto-close brackets (enhanced)
- **Multicursor**: Multiple cursors support
- **Todo-comments**: Highlight TODO, FIXME, etc.

### 🔧 **Git Integration**
- **Gitsigns**: Git decorations in sign column
- **Gitblame**: Inline git blame
- **LazyGit**: Git UI in Neovim
- **Diffview**: Beautiful git diffs
  - `<leader>gdo` - Open diffview
  - `<leader>gdh` - File history
- **Telescope git**: Browse commits, branches, status

### 🐛 **Diagnostics**
- **Trouble**: Beautiful diagnostics list
  - `<leader>xx` - Toggle diagnostics
  - `<leader>xX` - Buffer diagnostics
- **Todo-comments integration**: Find all TODOs
  - `]t` / `[t` - Next/prev TODO

### 🎯 **Special Features**
- **Session Management**: Restore your workspace instantly
  - `<leader>qs` - Restore session (for current directory)
  - `<leader>ql` - Restore last session
  - `<leader>qd` - Don't save current session
- **Floating terminal**: Toggle with `Alt-t`
- **Code runner**: Run code with `F5`
- **UFO**: Better folding
- **Colorizer**: Highlight color codes
- **Rainbow**: Rainbow parentheses
- **Remote**: SSH and Docker editing
- **Legendary**: Command palette (`Ctrl-p`)
- **Claude Code**: AI pair programming (`<leader>ac`)

## ⌨️ Key Bindings

### Leader Key
**Space** (`<Space>`) is the leader key

### Essential Mappings

#### File Navigation
| Key | Action |
|-----|--------|
| `<C-e>` | Toggle Neo-tree (file explorer) |
| `<leader>e` | Focus Neo-tree |
| `<leader>ge` | Git status in Neo-tree |
| `<leader>o` | Toggle Outline (Aerial - symbol list) |
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>fb` | Find buffers |
| `<leader>fr` | Recent files |
| `<C-p>` | Command palette (Legendary) |

#### Flash Navigation (Super Fast!)
| Key | Mode | Action |
|-----|------|--------|
| `s` | Normal/Visual | Jump to any word |
| `S` | Normal/Visual | Treesitter selection |
| `r` | Operator | Remote flash |

#### LSP
| Key | Action |
|-----|--------|
| `K` | Hover documentation |
| `gd` | Go to definition |
| `gR` | Show references |
| `gi` | Go to implementation |
| `gt` | Go to type definition |
| `<leader>ca` | Code actions |
| `<leader>rs` | Restart LSP |
| `]d` / `[d` | Next/prev diagnostic |
| `<leader>d` | Show line diagnostics |

#### Git
| Key | Action |
|-----|--------|
| `<leader>gs` | Git status |
| `<leader>gc` | Git commits |
| `<leader>gb` | Git branches |
| `<leader>gdo` | Open diffview |
| `<leader>gdc` | Close diffview |
| `<leader>gdh` | File history |

#### Trouble (Diagnostics)
| Key | Action |
|-----|--------|
| `<leader>xx` | Toggle diagnostics |
| `<leader>xX` | Buffer diagnostics |
| `<leader>cs` | Symbols |
| `<leader>cl` | LSP definitions |

#### Harpoon
| Key | Action |
|-----|--------|
| `<leader>hm` | Mark file |
| `<leader>hn` | Next mark |
| `<leader>hp` | Previous mark |
| `<leader>hf` | Show marks |

#### Splits & Tabs
| Key | Action |
|-----|--------|
| `<leader>sv` | Split vertically |
| `<leader>sh` | Split horizontally |
| `<leader>se` | Equal splits |
| `<leader>sq` | Close split |
| `<leader>to` | New tab |
| `<leader>tx` | Close tab |
| `<C-h/j/k/l>` | Navigate windows |

#### Editing
| Key | Action |
|-----|--------|
| `<C-s>` | Save file |
| `<C-c>` | Copy whole file |
| `<C-q>` | Close window |
| `<Esc>` | Clear search highlights |
| `Alt-f` | Fast word navigation |
| `Alt-t` | Toggle terminal |
| `<C-w>j/k` | Move line up/down |
| `<Tab>` / `<S-Tab>` | Indent in visual mode |

#### TODO Comments
| Key | Action |
|-----|--------|
| `]t` / `[t` | Next/prev TODO |
| `<leader>xt` | TODOs in Trouble |
| `<leader>st` | Search TODOs |

#### Search & Replace (Spectre)
| Key | Mode | Action |
|-----|------|--------|
| `<leader>S` | Normal | Toggle Spectre |
| `<leader>sw` | Normal | Search current word |
| `<leader>sw` | Visual | Search selection |
| `<leader>sp` | Normal | Search in current file |
| `<leader>R` | Inside Spectre | Replace all |
| `<leader>rc` | Inside Spectre | Replace current line |
| `dd` | Inside Spectre | Toggle line |

#### Debugging (DAP)
| Key | Action |
|-----|--------|
| `<leader>db` | Toggle breakpoint |
| `<leader>dB` | Conditional breakpoint |
| `<leader>dc` | Start/Continue debugging |
| `<leader>di` | Step into |
| `<leader>do` | Step over |
| `<leader>dO` | Step out |
| `<leader>dt` | Terminate debugging |
| `<leader>du` | Toggle debug UI |
| `<leader>dr` | Toggle REPL |
| `<leader>dh` | Hover variables |
| `<leader>dl` | Run last debug config |

#### Session Management
| Key | Action |
|-----|--------|
| `<leader>qs` | Restore session for current dir |
| `<leader>ql` | Restore last session |
| `<leader>qd` | Don't save current session |

#### Claude Code (AI)
| Key | Mode | Action |
|-----|------|--------|
| `<leader>ac` | Normal | Toggle Claude |
| `<leader>af` | Normal | Focus Claude |
| `<leader>ar` | Normal | Resume Claude |
| `<leader>aC` | Normal | Continue Claude |
| `<leader>am` | Normal | Select model |
| `<leader>ab` | Normal | Add current buffer |
| `<leader>as` | Visual | Send to Claude |
| `<leader>aa` | Normal | Accept diff |
| `<leader>ad` | Normal | Deny diff |

### Code Runner
Press `F5` to run code in supported languages:
- Python, JavaScript, TypeScript, Go, Rust, Java, C, C++, PHP, Ruby, etc.

## 📦 Plugin List

<details>
<summary>Click to expand full plugin list</summary>

### Core
- `lazy.nvim` - Plugin manager
- `plenary.nvim` - Lua utility functions

### UI
- `onedark.nvim` / `gruvbox.nvim` - Themes
- `lualine.nvim` - Statusline
- `bufferline.nvim` - Bufferline
- `nvim-web-devicons` - Icons
- `dashboard.nvim` - Start screen
- `noice.nvim` - Modern UI
- `dressing.nvim` - Better UI elements
- `fidget.nvim` - LSP progress
- `nvim-notify` - Notifications

### Navigation
- `flash.nvim` - Fast navigation
- `telescope.nvim` + extensions - Fuzzy finder
- `telescope-fzf-native.nvim` - Native FZF sorter
- `neo-tree.nvim` - Modern file explorer with git integration
- `harpoon` - File bookmarks
- `nvim-navic` + `barbecue.nvim` - Breadcrumbs (file path + symbols)
- `aerial.nvim` - Symbol outline sidebar
- `satellite.nvim` - Code minimap with diagnostics/git indicators

### LSP & Completion
- `mason.nvim` - LSP installer
- `mason-lspconfig.nvim` - Mason + LSPconfig
- `nvim-lspconfig` - LSP configurations
- `lspsaga.nvim` - Better LSP UI
- `null-ls.nvim` - Formatters & linters
- `nvim-cmp` - Completion engine
- `windsurf.nvim` - FREE AI inline code suggestions (Codeium)
- `LuaSnip` - Snippet engine
- `cmp-nvim-lsp` - LSP completion source
- `cmp-buffer` - Buffer completion
- `cmp-path` - Path completion
- `cmp_luasnip` - Snippet completion

### Treesitter
- `nvim-treesitter` - Better syntax highlighting
- `nvim-treesitter-textobjects` - Text objects
- `rainbow-delimiters.nvim` - Rainbow parentheses

### Editing
- `mini.nvim` - Swiss army knife
  - `mini.ai` - Better text objects
  - `mini.surround` - Surroundings
  - `mini.pairs` - Auto-pairs
  - `mini.bufremove` - Buffer removal
  - `mini.indentscope` - Indent guides
  - `mini.animate` - Animations
- `Comment.nvim` - Commenting
- `nvim-autopairs` - Auto-close brackets
- `vim-visual-multi` - Multiple cursors

### Git
- `gitsigns.nvim` - Git decorations
- `git-blame.nvim` - Inline blame
- `lazygit.nvim` - LazyGit integration
- `diffview.nvim` - Git diffs

### Diagnostics & Debugging
- `trouble.nvim` - Diagnostics UI
- `todo-comments.nvim` - TODO highlighting
- `nvim-dap` - Debug Adapter Protocol
- `nvim-dap-ui` - Debug UI
- `nvim-dap-virtual-text` - Inline debug info
- `mason-nvim-dap` - Auto-install debuggers

### Search & Replace
- `nvim-spectre` - Project-wide search and replace

### Utilities
- `which-key.nvim` - Key binding hints
- `legendary.nvim` - Command palette
- `nvim-colorizer.lua` - Color highlighting
- `FTerm.nvim` - Floating terminal
- `nvim-ufo` - Better folding
- `persistence.nvim` - Session management

### AI
- `claudecode.nvim` - Claude AI integration
- `snacks.nvim` - Required for Claude Code

</details>

## 🚀 Installation

The plugins are automatically installed when you first open Neovim!

### Manual Plugin Installation
```vim
:Lazy sync
```

### Mason LSP Installation
```vim
:Mason
```

Then install your language servers (Python, TypeScript, etc.)

## 🔧 Configuration Structure

```
nvim/
├── init.lua                  # Entry point
├── lua/
│   ├── core/
│   │   ├── init.lua          # Core loader
│   │   ├── options.lua       # Vim options
│   │   ├── keymaps.lua       # Key mappings
│   │   └── utils.lua         # Utility functions
│   ├── plugins/
│   │   ├── init.lua          # Plugin loader
│   │   ├── lsp/              # LSP configs
│   │   ├── theme/            # Theme configs
│   │   ├── flash.lua         # Flash navigation
│   │   ├── trouble.lua       # Diagnostics
│   │   ├── diffview.lua      # Git diffs
│   │   ├── mini.lua          # Mini.nvim suite
│   │   ├── ui.lua            # UI plugins
│   │   ├── todo-comments.lua # TODO highlighting
│   │   ├── persistence.lua   # Session management
│   │   ├── dap.lua           # Debugger
│   │   ├── spectre.lua       # Search & replace
│   │   ├── claudecode.lua    # AI assistant
│   │   └── ...               # Other plugins
│   └── pluginsloader.lua     # Lazy.nvim bootstrap
└── lazy-lock.json            # Plugin versions

```

## ⚙️ Customization

### Change Theme
Edit `init.lua`:
```lua
local name = "gruvbox"  -- or "onedark"
```

### Add LSP Server
```vim
:Mason
```
Search and install your LSP server

### Add Custom Keymaps
Edit `lua/core/keymaps.lua`

### Add Plugins
Create a new file in `lua/plugins/yourplugin.lua`:
```lua
return {
    "author/plugin-name",
    opts = {
        -- configuration
    },
}
```

## 📚 Resources

- [Lazy.nvim Docs](https://github.com/folke/lazy.nvim)
- [Neovim LSP Guide](https://neovim.io/doc/user/lsp.html)
- [Telescope Docs](https://github.com/nvim-telescope/telescope.nvim)
- [Flash.nvim](https://github.com/folke/flash.nvim)
- [Mini.nvim](https://github.com/echasnovski/mini.nvim)

## 🐛 Troubleshooting

### Plugins not loading
```vim
:Lazy sync
:Lazy health
```

### LSP not working
```vim
:LspInfo
:Mason
```

### Treesitter errors
```vim
:TSUpdate
```

### Clear cache
```bash
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim
rm -rf ~/.cache/nvim
```

## 💡 Pro Tips

1. **Windsurf AI suggestions**: Just start typing - AI suggestions appear automatically (Tab to accept)!
2. **Learn Flash navigation**: Press `s` and two characters - game changer!
3. **Use Harpoon**: Mark your most-used files with `<leader>hm`
4. **Master Telescope**: `<leader>ff` and `<leader>fg` are your best friends
5. **Neo-tree git status**: Press `<leader>ge` to see all changed files
6. **Symbol outline**: `<leader>o` to see all functions/classes in current file
7. **Breadcrumbs**: Look at the top of your window to see where you are in the code structure
8. **Minimap**: Look at the right side - see your entire file with diagnostics and git changes!
9. **Trouble for diagnostics**: `<leader>xx` shows all errors beautifully
10. **Todo-comments**: Write `TODO:` or `FIXME:` and they'll be highlighted
11. **Diffview for Git**: `<leader>gdo` for beautiful diffs
12. **Flash in visual mode**: Select text with `S` using treesitter
13. **Code actions**: `<leader>ca` can fix many issues automatically
14. **Session persistence**: Your sessions auto-save! Just `<leader>qs` to restore
15. **Debug without console.log**: `<leader>db` to set breakpoints, `<leader>dc` to debug
16. **Project-wide refactoring**: Use Spectre (`<leader>S`) for safe find/replace across all files
17. **Claude Code**: Press `<leader>ac` for AI assistance - it's like having a senior dev next to you!

---

**Made with ❤️ by Raul Gavris**
