#!/usr/bin/env bash
# ============================================
# Dotfiles Installation Script
# Author: Raul Gavris
# ============================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_header() { echo -e "\n${BLUE}═══════════════════════════════════════${NC}\n${BLUE}  $1${NC}\n${BLUE}═══════════════════════════════════════${NC}\n"; }

# ============================================
# Check if running on macOS
# ============================================
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS only."
    exit 1
fi

print_header "🚀 Dotfiles Installation"

# ============================================
# 1. Check for Xcode Command Line Tools
# ============================================
print_info "Checking for Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
    print_warning "Xcode Command Line Tools not found. Installing..."
    xcode-select --install
    print_info "Please complete the installation and run this script again."
    exit 0
else
    print_success "Xcode Command Line Tools installed"
fi

# ============================================
# 2. Check for Homebrew
# ============================================
print_info "Checking for Homebrew..."
if ! command -v brew &>/dev/null; then
    print_warning "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == 'arm64' ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    print_success "Homebrew installed"
else
    print_success "Homebrew already installed"
fi

# ============================================
# 3. Install Homebrew packages
# ============================================
print_header "📦 Installing Homebrew Packages"

if [ -f "Brewfile" ]; then
    print_info "Installing packages from Brewfile..."
    brew bundle --file=Brewfile
    print_success "All Homebrew packages installed"
else
    print_warning "Brewfile not found, skipping package installation"
fi

# ============================================
# 4. Check for GNU Stow
# ============================================
print_info "Checking for GNU Stow..."
if ! command -v stow &>/dev/null; then
    print_warning "GNU Stow not found. Installing..."
    brew install stow
    print_success "GNU Stow installed"
else
    print_success "GNU Stow already installed"
fi

# ============================================
# 5. Backup existing configs
# ============================================
print_header "💾 Backing Up Existing Configs"

BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

configs_to_backup=(
    "$HOME/.zshrc"
    "$HOME/.gitconfig"
    "$HOME/.gitignore_global"
    "$HOME/.tmux.conf"
    "$HOME/.config/nvim"
    "$HOME/.config/karabiner"
)

for config in "${configs_to_backup[@]}"; do
    if [ -e "$config" ]; then
        print_info "Backing up $(basename $config)..."
        cp -r "$config" "$BACKUP_DIR/"
    fi
done

print_success "Backups saved to: $BACKUP_DIR"

# ============================================
# 6. Stow dotfiles
# ============================================
print_header "🔗 Symlinking Dotfiles"

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DOTFILES_DIR"

# Array of packages to stow
packages=(
    "zsh"
    "tmux"
    "git"
    "nvim"
    "karabiner"
)

for package in "${packages[@]}"; do
    if [ -d "$package" ]; then
        print_info "Stowing $package..."
        stow "$package" --adopt -t "$HOME" 2>&1 || print_warning "Failed to stow $package (might already exist)"
        print_success "$package stowed"
    else
        print_warning "Package directory $package not found, skipping"
    fi
done

# ============================================
# 7. Install Tmux Plugin Manager
# ============================================
print_header "🔌 Installing Tmux Plugin Manager"

if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    print_info "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    print_success "TPM installed"
    print_info "Run 'tmux' then press 'Ctrl-a + I' to install tmux plugins"
else
    print_success "TPM already installed"
fi

# Make tmux scripts executable
if [ -d "$HOME/.tmux" ]; then
    chmod +x "$HOME/.tmux"/*.sh 2>/dev/null || true
    print_success "Tmux scripts made executable"
fi

# ============================================
# 8. Install Oh My Zsh
# ============================================
print_header "🎨 Installing Oh My Zsh"

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    print_info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    print_success "Oh My Zsh installed"
else
    print_success "Oh My Zsh already installed"
fi

# ============================================
# 9. Install Zsh plugins
# ============================================
print_info "Installing Zsh plugins..."

# zsh-autosuggestions
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    print_success "zsh-autosuggestions installed"
fi

# zsh-syntax-highlighting
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    print_success "zsh-syntax-highlighting installed"
fi

# Powerlevel10k theme
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    print_success "Powerlevel10k theme installed"
fi

# ============================================
# 10. Configure Git
# ============================================
print_header "🔧 Configuring Git"

# The .gitconfig will be symlinked by stow, but let's verify
if [ -L "$HOME/.gitconfig" ]; then
    print_success "Git config symlinked"
else
    print_warning "Git config not symlinked properly"
fi

# Set up global gitignore
git config --global core.excludesfile ~/.gitignore_global 2>/dev/null && print_success "Global gitignore configured" || true

# ============================================
# 11. Create necessary directories
# ============================================
print_header "📁 Creating Directories"

directories=(
    "$HOME/logs"
    "$HOME/notes"
    "$HOME/.config"
)

for dir in "${directories[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        print_success "Created $dir"
    fi
done

# ============================================
# 12. Set Zsh as default shell
# ============================================
print_header "🐚 Setting Zsh as Default Shell"

if [ "$SHELL" != "$(which zsh)" ]; then
    print_info "Changing default shell to Zsh..."
    chsh -s "$(which zsh)"
    print_success "Default shell changed to Zsh"
else
    print_success "Zsh is already the default shell"
fi

# ============================================
# 13. Final steps
# ============================================
print_header "✨ Installation Complete!"

echo ""
print_info "Next steps:"
echo "  1. Restart your terminal"
echo "  2. Run 'p10k configure' to set up Powerlevel10k"
echo "  3. Open tmux and press 'Ctrl-a + I' to install tmux plugins"
echo "  4. Press 'Ctrl-a + H' in tmux to view the Tmux guide"
echo ""
print_success "Your dotfiles are ready! 🎉"
echo ""
print_info "Backup location: $BACKUP_DIR"
echo ""
