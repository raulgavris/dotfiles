# Dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/). Supports **macOS** and **Ubuntu/Debian**.

## Features

### Shell (Zsh)
- **Oh My Zsh** with Powerlevel10k theme
- **Zsh plugins**: autosuggestions, syntax highlighting, git
- **Smart navigation** with zoxide
- **Useful aliases** and functions for git, tmux, navigation
- **Auto NVM** version switching based on `.nvmrc`
- **[superfile](https://github.com/yorukot/superfile)**: Modern terminal file manager (run `spf`)

### Tmux
- **Prefix**: `Ctrl-a` (not the default Ctrl-b)
- **Quick Sessionizer**: Instant project jumping with fzf
- **Workspace Creator**: Multi-repo workspace management
- **Smart Session Switcher**: Enhanced fzf session picker
- **Auto-save/restore**: Sessions persist across reboots (tmux-resurrect + continuum)
- **Vi copy mode** with clipboard integration (pbcopy on macOS, xclip on Linux)
- **Custom status bar**: CPU, Memory, Battery indicators
- **Pane logging** with color stripping
- Press `Ctrl-a + H` for full guide

### Git
- **40+ aliases** for common git operations
- **Beautiful log formats** with colors and graphs
- **Smart defaults**: auto-rebase, auto-prune, force-with-lease
- **Global gitignore** for editors, node_modules, etc.

### Neovim
- Custom configuration with LSP, Treesitter, Telescope, and more
- See [nvim/README.md](nvim/README.md) for full details

### Keyboard Remapping
- **macOS**: Karabiner for custom keyboard mappings
- **Linux**: GNOME native — Super/Win keys act as Ctrl (macOS-style shortcuts via `gsettings`)

## Quick Start

### Fresh Installation

```bash
# Clone this repo
git clone https://github.com/yourusername/dotfiles.git ~/Sites/dotfiles
cd ~/Sites/dotfiles

# Run the installer
./install.sh
```

The installer detects your OS and:

**On macOS:**
1. Installs Xcode Command Line Tools
2. Installs Homebrew
3. Installs all packages from Brewfile
4. Backs up existing configs
5. Symlinks all dotfiles (including Karabiner)
6. Installs TPM, Oh My Zsh, plugins, Powerlevel10k
7. Sets Zsh as default shell

**On Ubuntu/Debian:**
1. Installs CLI tools via apt (fzf, ripgrep, tmux, stow, zsh, etc.)
2. Installs Neovim via PPA
3. Installs fnm, pyenv, zoxide, superfile via their install scripts
4. Configures GNOME keyboard (Super → Ctrl for macOS-style shortcuts)
5. Backs up existing configs
6. Symlinks all dotfiles
7. Installs TPM, Oh My Zsh, plugins, Powerlevel10k
8. Sets Zsh as default shell

### Manual Installation

```bash
# Install specific package
stow zsh -t $HOME
stow tmux -t $HOME
stow git -t $HOME
stow nvim -t $HOME

# Or install everything
stow */ -t $HOME
```

## Structure

```
dotfiles/
├── git/
│   ├── .gitconfig           # Git configuration & aliases
│   └── .gitignore_global    # Global gitignore
├── tmux/
│   ├── .tmux.conf           # Tmux configuration
│   ├── .tmux/               # Tmux scripts (sessionizer, workspace, etc.)
│   └── TMUX_GUIDE.md        # Comprehensive tmux guide
├── zsh/
│   └── .zshrc               # Zsh configuration
├── nvim/
│   └── .config/nvim/        # Neovim configuration
├── karabiner/               # macOS only
│   └── .config/karabiner/   # Karabiner configuration
├── Brewfile                 # Homebrew packages (macOS)
└── install.sh               # Cross-platform installation script
```

## After Installation

### 1. Configure Powerlevel10k
```bash
p10k configure
```

### 2. Install Tmux Plugins
```bash
# Open tmux, then press: Ctrl-a + I (capital i)
tmux
```

### 3. View Tmux Guide
```bash
# Inside tmux, press: Ctrl-a + H
```

### 4. Test Git Aliases
```bash
git s          # status
git l          # pretty log
git aliases    # show all aliases
```

## Key Bindings

### Tmux Highlights
| Key | Action |
|-----|--------|
| `Ctrl-a + Ctrl-f` | Quick sessionizer (jump to any project) |
| `Ctrl-a + f` | Workspace creator (multi-repo) |
| `Ctrl-a + s` | Session switcher |
| `Ctrl-a + N` | Quick notes |
| `Ctrl-a + H` | View full guide |

### Zsh Aliases
| Alias | Command |
|-------|---------|
| `..` | Go up one directory |
| `gs` | git status |
| `gl` | git log (pretty) |
| `t` | tmux attach or create |
| `killport 3000` | Kill process on port 3000 |

## Customization

### Machine-Specific Config

Create `~/.zshrc.local` for machine-specific settings (not tracked by git):

```bash
# ~/.zshrc.local
export WORK_PROJECT_DIR="/path/to/work/projects"
alias work="cd $WORK_PROJECT_DIR"
```

### Update Brewfile (macOS)

After installing new packages:

```bash
cd ~/Sites/dotfiles
brew bundle dump --force --describe
git add Brewfile
git commit -m "Update Brewfile"
```

### Customize Tmux Sessionizer Paths

Edit `~/.tmux/sessionizer.sh` and update:

```bash
PROJECT_DIRS=(
    "$HOME/Projects"
    "$HOME/Sites"
    "$HOME/work"
    # Add your paths here
)
```

### Customize Telescope Project Dirs (Neovim)

Edit `nvim/.config/nvim/lua/plugins/telescope.lua` and update the `base_dirs` list in the project extension config.

## Maintenance

### Update Everything

```bash
# macOS: Update Homebrew packages
brew update && brew upgrade

# Linux: Update apt packages
sudo apt update && sudo apt upgrade

# Update Oh My Zsh
omz update

# Update Tmux plugins (in tmux: Ctrl-a + U)

# Update Neovim plugins
nvim -c "Lazy sync"
```

## Documentation

- **Tmux**: Press `Ctrl-a + H` in tmux or read `tmux/TMUX_GUIDE.md`
- **Neovim**: See `nvim/README.md`
- **Git aliases**: Run `git aliases`

## Troubleshooting

### Zsh not loading properly
```bash
zsh -n ~/.zshrc
source ~/.zshrc
```

### Tmux plugins not loading
```bash
rm -rf ~/.tmux/plugins/tpm
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
# In tmux: Ctrl-a + I
```

### Stow conflicts
```bash
# Use --adopt to merge existing files (overwrites repo versions!)
stow --adopt <package> -t $HOME
```

## Resources

- [GNU Stow Manual](https://www.gnu.org/software/stow/manual/stow.html)
- [Oh My Zsh](https://ohmyz.sh/)
- [Tmux Cheat Sheet](https://tmuxcheatsheet.com/)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)

## License

MIT License

---

**Made with ❤️ by Raul Gavris & Ice**
