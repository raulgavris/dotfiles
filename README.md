# 🚀 Raul's Dotfiles

My personal macOS dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## ✨ Features

### 🎨 Shell (Zsh)
- **Oh My Zsh** with Powerlevel10k theme
- **Zsh plugins**: autosuggestions, syntax highlighting, git, sudo, extract
- **Smart navigation** with zoxide
- **Useful aliases** and functions for git, tmux, navigation
- **Auto NVM** version switching based on `.nvmrc`
- **SSH Keychain** integration for macOS

### 🖥️ Tmux
- **Prefix**: `Ctrl-a` (not the default Ctrl-b)
- **Quick Sessionizer**: Instant project jumping with fzf
- **Workspace Creator**: Multi-repo workspace management
- **Smart Session Switcher**: Enhanced fzf session picker
- **Auto-save/restore**: Sessions persist across reboots (tmux-resurrect + continuum)
- **Vi copy mode** with clipboard integration
- **Custom status bar**: CPU, Memory, Battery indicators
- **Pane logging** with color stripping
- **100+ keybindings** - Press `Ctrl-a + H` for full guide

### 📝 Git
- **40+ aliases** for common git operations
- **Beautiful log formats** with colors and graphs
- **Smart defaults**: auto-rebase, auto-prune, force-with-lease
- **Global gitignore** for macOS, editors, node_modules, etc.

### 🎯 Neovim
- Custom configuration (expand as needed)

### ⌨️ Karabiner
- Custom keyboard mappings

## 🚀 Quick Start

### Fresh macOS Installation

```bash
# Clone this repo
git clone https://github.com/yourusername/dotfiles.git ~/Projects/dotfiles
cd ~/Projects/dotfiles

# Run the installer
./install.sh
```

The installer will:
1. ✅ Install Xcode Command Line Tools
2. ✅ Install Homebrew
3. ✅ Install all packages from Brewfile
4. ✅ Backup existing configs
5. ✅ Symlink all dotfiles
6. ✅ Install Tmux Plugin Manager
7. ✅ Install Oh My Zsh + plugins
8. ✅ Configure Git
9. ✅ Set Zsh as default shell

### Manual Installation

If you prefer to install specific components:

```bash
# Install specific package
stow zsh -t $HOME
stow tmux -t $HOME
stow git -t $HOME

# Or install everything
stow */ -t $HOME
```

## 📦 Structure

```
dotfiles/
├── git/
│   ├── .gitconfig           # Git configuration & aliases
│   └── .gitignore_global    # Global gitignore
├── tmux/
│   ├── .tmux.conf           # Tmux configuration
│   ├── .tmux/               # Tmux scripts
│   └── TMUX_GUIDE.md        # Comprehensive tmux guide
├── zsh/
│   └── .zshrc               # Zsh configuration
├── nvim/
│   └── .config/nvim/        # Neovim configuration
├── karabiner/
│   └── .config/karabiner/   # Karabiner configuration
├── Brewfile                 # Homebrew packages
└── install.sh               # Installation script
```

## 🎯 After Installation

### 1. Configure Powerlevel10k
```bash
p10k configure
```

### 2. Install Tmux Plugins
```bash
# Open tmux
tmux

# Press: Ctrl-a + I (capital i)
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

## 🔑 Key Bindings

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

## 📝 Customization

### Add Your Own Local Config

Create `~/.zshrc.local` for machine-specific settings that won't be committed:

```bash
# ~/.zshrc.local
export WORK_PROJECT_DIR="/path/to/work/projects"
alias work="cd $WORK_PROJECT_DIR"
```

### Update Brewfile

After installing new packages:

```bash
cd ~/Projects/dotfiles
brew bundle dump --force --describe
git add Brewfile
git commit -m "Update Brewfile"
```

### Customize Tmux Sessionizer Paths

Edit `~/.tmux/sessionizer.sh` and update:

```bash
PROJECT_DIRS=(
    "$HOME/Projects"
    "$HOME/work"
    # Add your paths here
)
```

## 🛠️ Maintenance

### Update Everything

```bash
# Update Homebrew packages
brew update && brew upgrade

# Update Oh My Zsh
omz update

# Update Tmux plugins
# In tmux: Ctrl-a + U
```

### Backup Current Setup

```bash
# Backup Homebrew packages
cd ~/Projects/dotfiles
brew bundle dump --force

# Commit changes
git add .
git commit -m "Update dotfiles"
git push
```

## 📚 Documentation

- **Tmux**: Press `Ctrl-a + H` in tmux or read `tmux/TMUX_GUIDE.md`
- **Git aliases**: Run `git aliases`
- **Zsh functions**: Run `type <function_name>` (e.g., `type killport`)

## 🐛 Troubleshooting

### Zsh not loading properly
```bash
# Check for errors
zsh -n ~/.zshrc

# Source manually
source ~/.zshrc
```

### Tmux plugins not loading
```bash
# Reinstall TPM
rm -rf ~/.tmux/plugins/tpm
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# In tmux: Ctrl-a + I
```

### Stow conflicts
```bash
# Use --adopt to merge existing files
stow --adopt <package> -t $HOME
```

## 📖 Resources

- [GNU Stow Manual](https://www.gnu.org/software/stow/manual/stow.html)
- [Oh My Zsh](https://ohmyz.sh/)
- [Tmux Cheat Sheet](https://tmuxcheatsheet.com/)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)

## 📄 License

MIT License - See LICENSE file

---

**Made with ❤️ by Raul Gavris**
