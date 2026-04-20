#!/usr/bin/env bash
# ============================================
# Dotfiles Installation Script
# Authors: Raul Gavris & Ice
# Supports: macOS, Ubuntu/Debian
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
# Detect OS
# ============================================
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "linux"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            if [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID_LIKE" == *"debian"* ]]; then
                OS="linux"
            else
                print_error "Unsupported Linux distribution: $ID. Only Ubuntu/Debian are supported."
                exit 1
            fi
        else
            print_error "Cannot detect Linux distribution."
            exit 1
        fi
    else
        print_error "Unsupported OS: $OSTYPE"
        exit 1
    fi
}

detect_os

# Cross-platform in-place sed (macOS BSD sed requires -i '', GNU sed requires -i)
sedi() {
    if [[ "$OS" == "macos" ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

print_header "🚀 Dotfiles Installation ($OS)"

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# ============================================
# macOS: Xcode CLI Tools + Homebrew
# ============================================
if [ "$OS" = "macos" ]; then
    print_info "Checking for Xcode Command Line Tools..."
    if ! xcode-select -p &>/dev/null; then
        print_warning "Xcode Command Line Tools not found. Installing..."
        xcode-select --install
        print_info "Please complete the installation and run this script again."
        exit 0
    else
        print_success "Xcode Command Line Tools installed"
    fi

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

    print_header "📦 Installing Homebrew Packages"

    if [ -f "$DOTFILES_DIR/Brewfile" ]; then
        print_info "Installing packages from Brewfile..."
        brew bundle --file="$DOTFILES_DIR/Brewfile"
        print_success "All Homebrew packages installed"
    else
        print_warning "Brewfile not found, skipping package installation"
    fi

    print_info "Checking for GNU Stow..."
    if ! command -v stow &>/dev/null; then
        print_warning "GNU Stow not found. Installing..."
        brew install stow
        print_success "GNU Stow installed"
    else
        print_success "GNU Stow already installed"
    fi

    # Oh My Posh
    print_info "Installing Oh My Posh..."
    if ! command -v oh-my-posh &>/dev/null; then
        brew install jandedobbeleer/oh-my-posh/oh-my-posh
        print_success "Oh My Posh installed"
    else
        print_success "Oh My Posh already installed"
    fi

    # Superfile (terminal file manager)
    print_info "Installing superfile..."
    if ! command -v spf &>/dev/null; then
        brew install superfile
        print_success "superfile installed"
    else
        print_success "superfile already installed"
    fi

    # Yazi (terminal file manager)
    print_info "Installing yazi..."
    if ! command -v yazi &>/dev/null; then
        brew install yazi ffmpeg sevenzip jq poppler imagemagick
        print_success "yazi installed"
    else
        print_success "yazi already installed"
    fi

    # Ghostty (terminal emulator)
    print_info "Installing Ghostty..."
    if ! brew list --cask ghostty &>/dev/null; then
        brew install --cask ghostty
        print_success "Ghostty installed"
    else
        print_success "Ghostty already installed"
    fi

    # peon-ping (sound effects + notifications for Claude Code)
    print_info "Installing peon-ping..."
    if ! command -v peon &>/dev/null; then
        brew install peonping/tap/peon-ping
        print_success "peon-ping installed"
    else
        print_success "peon-ping already installed"
    fi
fi

# ============================================
# Linux: apt packages + tools from source/scripts
# ============================================
if [ "$OS" = "linux" ]; then
    print_header "📦 Installing Packages (apt)"

    print_info "Updating package lists..."
    sudo apt update

    print_info "Installing CLI tools..."
    sudo apt install -y \
        cowsay \
        fd-find \
        fortune-mod \
        fzf \
        lolcat \
        tig \
        tmux \
        stow \
        ripgrep \
        zsh \
        curl \
        git \
        xclip \
        build-essential \
        ffmpeg \
        jq \
        poppler-utils \
        imagemagick

    # 7-Zip — package name changed: `p7zip-full` on 22.04, `7zip` on 23.10+.
    # Prefer `7zip` if the repo offers it, fall back to `p7zip-full` otherwise.
    if apt-cache show 7zip >/dev/null 2>&1; then
        sudo apt install -y 7zip
    else
        sudo apt install -y p7zip-full
    fi

    print_success "apt packages installed"

    # Neovim (latest via PPA)
    print_info "Installing Neovim..."
    if ! command -v nvim &>/dev/null; then
        sudo apt install -y software-properties-common
        sudo add-apt-repository -y ppa:neovim-ppa/unstable
        sudo apt update
        sudo apt install -y neovim
        print_success "Neovim installed"
    else
        print_success "Neovim already installed"
    fi

    # Go (latest stable from official tarball)
    print_info "Installing Go..."
    if ! command -v go &>/dev/null; then
        GO_VERSION=$(curl -sL https://go.dev/VERSION?m=text | head -1)
        ARCH=$(uname -m)
        if [ "$ARCH" = "x86_64" ]; then
            GO_ARCH="amd64"
        elif [ "$ARCH" = "aarch64" ]; then
            GO_ARCH="arm64"
        else
            GO_ARCH="amd64"
        fi
        curl -sL "https://go.dev/dl/${GO_VERSION}.linux-${GO_ARCH}.tar.gz" -o /tmp/go.tar.gz
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf /tmp/go.tar.gz
        rm /tmp/go.tar.gz
        print_success "Go ${GO_VERSION} installed to /usr/local/go"
    else
        print_success "Go already installed ($(go version))"
    fi

    # Node.js via fnm (Fast Node Manager)
    print_info "Installing fnm..."
    if ! command -v fnm &>/dev/null && [ ! -d "$HOME/.local/share/fnm" ]; then
        curl -fsSL https://fnm.vercel.app/install | bash
        print_success "fnm installed"
    else
        print_success "fnm already installed"
    fi

    # Lazygit (latest from GitHub releases)
    print_info "Installing lazygit..."
    if ! command -v lazygit &>/dev/null; then
        LAZYGIT_VERSION=$(curl -sL https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep '"tag_name"' | cut -d'"' -f4 | sed 's/^v//')
        ARCH=$(uname -m)
        if [ "$ARCH" = "x86_64" ]; then
            LG_ARCH="x86_64"
        elif [ "$ARCH" = "aarch64" ]; then
            LG_ARCH="arm64"
        else
            LG_ARCH="x86_64"
        fi
        curl -sL "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_${LG_ARCH}.tar.gz" -o /tmp/lazygit.tar.gz
        tar -xzf /tmp/lazygit.tar.gz -C /tmp lazygit
        sudo install -m 755 /tmp/lazygit /usr/local/bin/lazygit
        rm /tmp/lazygit.tar.gz /tmp/lazygit
        print_success "lazygit ${LAZYGIT_VERSION} installed"
    else
        print_success "lazygit already installed"
    fi

    # pyenv
    print_info "Installing pyenv..."
    if ! command -v pyenv &>/dev/null && [ ! -d "$HOME/.pyenv" ]; then
        sudo apt install -y \
            libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
            libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
            libffi-dev liblzma-dev
        curl https://pyenv.run | bash
        print_success "pyenv installed"
    else
        print_success "pyenv already installed"
    fi

    # zoxide
    print_info "Installing zoxide..."
    if ! command -v zoxide &>/dev/null && [ ! -d "$HOME/.local/bin/zoxide" ]; then
        curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
        print_success "zoxide installed"
    else
        print_success "zoxide already installed"
    fi

    # Oh My Posh
    print_info "Installing Oh My Posh..."
    if ! command -v oh-my-posh &>/dev/null; then
        curl -s https://ohmyposh.dev/install.sh | bash -s
        print_success "Oh My Posh installed"
    else
        print_success "Oh My Posh already installed"
    fi

    # Superfile (terminal file manager)
    print_info "Installing superfile..."
    if ! command -v spf &>/dev/null; then
        bash -c "$(curl -sLo- https://superfile.dev/install.sh)"
        print_success "superfile installed"
    else
        print_success "superfile already installed"
    fi

    # Yazi (terminal file manager)
    print_info "Installing yazi..."
    if ! command -v yazi &>/dev/null; then
        YAZI_VERSION=$(curl -sL https://api.github.com/repos/sxyazi/yazi/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
        ARCH=$(uname -m)
        if [ "$ARCH" = "x86_64" ]; then
            YAZI_ARCH="x86_64-unknown-linux-gnu"
        elif [ "$ARCH" = "aarch64" ]; then
            YAZI_ARCH="aarch64-unknown-linux-gnu"
        else
            print_error "Unsupported architecture for yazi: $ARCH"
            YAZI_ARCH=""
        fi
        if [ -n "$YAZI_ARCH" ]; then
            YAZI_URL="https://github.com/sxyazi/yazi/releases/download/${YAZI_VERSION}/yazi-${YAZI_ARCH}.zip"
            YAZI_TMP=$(mktemp -d)
            curl -sL "$YAZI_URL" -o "$YAZI_TMP/yazi.zip"
            unzip -q "$YAZI_TMP/yazi.zip" -d "$YAZI_TMP"
            sudo install -m 755 "$YAZI_TMP/yazi-${YAZI_ARCH}/yazi" /usr/local/bin/yazi
            sudo install -m 755 "$YAZI_TMP/yazi-${YAZI_ARCH}/ya" /usr/local/bin/ya
            rm -rf "$YAZI_TMP"
            print_success "yazi ${YAZI_VERSION} installed"
        fi
    else
        print_success "yazi already installed"
    fi

    # Ghostty (terminal emulator)
    print_info "Installing Ghostty..."
    if ! command -v ghostty &>/dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"
        print_success "Ghostty installed"
    else
        print_success "Ghostty already installed"
    fi

    # GNOME keyboard settings (Super/Win keys act as Ctrl for macOS-style shortcuts)
    if command -v gsettings &>/dev/null; then
        print_info "Configuring GNOME keyboard settings (Super → Ctrl)..."
        gsettings set org.gnome.desktop.input-sources xkb-options "['altwin:ctrl_win']"
        print_success "Super/Win keys now act as Ctrl (macOS-style)"
    fi

    # peon-ping (sound effects + notifications for Claude Code)
    print_info "Installing peon-ping..."
    if ! command -v peon &>/dev/null; then
        curl -fsSL https://raw.githubusercontent.com/PeonPing/peon-ping/main/install.sh | bash
        print_success "peon-ping installed"
    else
        print_success "peon-ping already installed"
    fi
fi

# ============================================
# Backup existing configs
# ============================================
print_header "💾 Backing Up Existing Configs"

BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

configs_to_backup=(
    "$HOME/.zshrc"
    "$HOME/.zshrc.base"
    "$HOME/.gitconfig"
    "$HOME/.gitignore_global"
    "$HOME/.tmux.conf"
    "$HOME/.config/nvim"
    "$HOME/.config/ghostty"
    "$HOME/.config/termdesk/config.toml"
)

if [ "$OS" = "macos" ]; then
    configs_to_backup+=("$HOME/.config/karabiner")
fi

for config in "${configs_to_backup[@]}"; do
    if [ -e "$config" ]; then
        print_info "Backing up $(basename "$config")..."
        cp -r "$config" "$BACKUP_DIR/"
    fi
done

print_success "Backups saved to: $BACKUP_DIR"

# ============================================
# Stow dotfiles
# ============================================
print_header "🔗 Symlinking Dotfiles"

cd "$DOTFILES_DIR"

# Shared packages
packages=(
    "zsh"
    "tmux"
    "git"
    "nvim"
    "ghostty"
    "termdesk"
    "claude"
)

# OS-specific packages
if [ "$OS" = "macos" ]; then
    packages+=("karabiner")
fi

for package in "${packages[@]}"; do
    if [ -d "$package" ]; then
        print_info "Stowing $package..."
        # `claude` uses --no-folding so we get file-level symlinks inside ~/.claude/.
        # Claude Code writes runtime state (sessions/, todos/, file-history/) into
        # that directory — directory-level folding would collide with those.
        if [ "$package" = "claude" ]; then
            stow "$package" --no-folding -t "$HOME" 2>&1 || print_warning "Failed to stow $package"
        else
            stow "$package" --adopt -t "$HOME" 2>&1 || print_warning "Failed to stow $package (might already exist)"
        fi
        print_success "$package stowed"
    else
        print_warning "Package directory $package not found, skipping"
    fi
done

# ============================================
# Claude Code: merge hook registrations + chmod scripts
# ============================================
if [ -f "$HOME/.claude/settings.template.json" ]; then
    print_header "🤖 Wiring Claude Code hooks"

    if ! command -v jq >/dev/null 2>&1; then
        print_warning "jq not found — skipping Claude hook registration. Install jq and re-run."
    else
        # Ensure executable bits on hook scripts
        find "$HOME/.claude/hooks" -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null
        find "$HOME/.claude/hooks" -name "*.sh" -type l -exec chmod +x {} \; 2>/dev/null
        print_success "Hook scripts marked executable"

        # Expand $HOME in the template, then merge into ~/.claude/settings.json.
        # Merge strategy: union hook arrays by "command" path so re-runs are idempotent.
        tpl_expanded=$(mktemp)
        sed "s|\$HOME|$HOME|g" "$HOME/.claude/settings.template.json" > "$tpl_expanded"

        if [ ! -f "$HOME/.claude/settings.json" ]; then
            echo '{}' > "$HOME/.claude/settings.json"
        fi

        # Backup then merge. The merge adds any hook whose command isn't already present.
        cp "$HOME/.claude/settings.json" "$HOME/.claude/settings.json.backup-claude-stow-$(date +%Y%m%d-%H%M%S)"

        merged=$(mktemp)
        jq --slurpfile tpl "$tpl_expanded" '
          def mergeHookEvent($existing; $incoming):
            ($existing // []) as $e
            | ($incoming // []) as $i
            | reduce $i[] as $group (
                $e;
                ($group.matcher // "") as $m
                | . as $acc
                | if any(.[]; (.matcher // "") == $m) then
                    map(
                      if (.matcher // "") == $m then
                        .hooks = (
                          (.hooks // []) + (
                            ($group.hooks // []) | map(
                              . as $new
                              | select(
                                  ([$acc[] | select((.matcher // "") == $m) | (.hooks // [])[] | .command] | index($new.command)) == null
                                )
                            )
                          )
                        )
                      else . end
                    )
                  else . + [$group]
                  end
              );

          ($tpl[0].hooks // {}) as $T
          | .hooks = (
              (.hooks // {}) as $H
              | reduce ($T | keys_unsorted[]) as $event (
                  $H;
                  .[$event] = mergeHookEvent(.[$event]; $T[$event])
                )
            )
          | del(._comment)
        ' "$HOME/.claude/settings.json" > "$merged"

        if [ -s "$merged" ] && jq -e . "$merged" >/dev/null 2>&1; then
            # Use `command cp -f` to avoid any interactive `mv -i` alias.
            command cp -f "$merged" "$HOME/.claude/settings.json"
            print_success "Claude hooks merged into ~/.claude/settings.json"
        else
            print_warning "jq merge produced invalid JSON — leaving settings.json unchanged. Backup available."
        fi
        command rm -f "$merged" "$tpl_expanded"

        # Bootstrap Claude Code plugins from the declared inventory. The state files
        # in claude/state/plugins/ are the source of truth; the `claude plugin` CLI
        # actually downloads the plugin code into ~/.claude/plugins/{cache,marketplaces}.
        # Earlier versions of this script only seeded the state JSON, which left the
        # cache empty and plugins showing as "disabled" in `claude plugin list`.
        plugin_state_src="$DOTFILES_DIR/claude/state/plugins"
        if [ -d "$plugin_state_src" ] && command -v claude >/dev/null 2>&1; then
            # 1. Register marketplaces (idempotent — skip if already present).
            if [ -f "$plugin_state_src/known_marketplaces.json" ]; then
                existing_mps=$(claude plugin marketplace list 2>/dev/null || true)
                while IFS=$'\t' read -r mp_name mp_repo; do
                    [ -z "$mp_name" ] || [ -z "$mp_repo" ] && continue
                    if printf '%s\n' "$existing_mps" | grep -qE "❯[[:space:]]+${mp_name}\$"; then
                        continue
                    fi
                    print_info "Adding Claude marketplace: $mp_name ($mp_repo)"
                    claude plugin marketplace add "$mp_repo" >/dev/null 2>&1 \
                        && print_success "marketplace $mp_name registered" \
                        || print_warning "marketplace $mp_name failed (check 'claude plugin marketplace add $mp_repo')"
                done < <(jq -r 'to_entries[] | [.key, (.value.source.repo // "")] | @tsv' "$plugin_state_src/known_marketplaces.json")
            fi

            # 2. Install user-scoped plugins. Skip the loop entirely if the plugin
            # cache already has content — treat that as "bootstrap already done"
            # so normal re-runs of install.sh stay fast. Force a re-run by deleting
            # ~/.claude/plugins/cache/ or by invoking `claude plugin install` manually.
            if [ -f "$plugin_state_src/installed_plugins.json" ]; then
                cache_dir="$HOME/.claude/plugins/cache"
                if [ -d "$cache_dir" ] && [ -n "$(ls -A "$cache_dir" 2>/dev/null)" ]; then
                    print_success "Claude plugin cache present — skipping plugin install loop"
                else
                    print_info "Installing Claude plugins from inventory (this takes a few minutes)..."
                    plugin_count=0
                    plugin_failed=0
                    while IFS= read -r plugin_ref; do
                        [ -z "$plugin_ref" ] && continue
                        plugin_count=$((plugin_count + 1))
                        if claude plugin install "$plugin_ref" -s user >/dev/null 2>&1; then
                            printf '  %s installed\n' "$plugin_ref"
                        else
                            plugin_failed=$((plugin_failed + 1))
                            print_warning "  $plugin_ref — install failed (removed upstream or network error)"
                        fi
                    done < <(jq -r '.plugins | to_entries[] | select(.value[] | .scope == "user") | .key' "$plugin_state_src/installed_plugins.json")
                    if [ "$plugin_failed" -eq 0 ]; then
                        print_success "Installed $plugin_count Claude plugins"
                    else
                        print_warning "Installed $((plugin_count - plugin_failed))/$plugin_count plugins ($plugin_failed failed — see warnings above)"
                    fi
                fi
            fi
        fi

        # Run peon-ping-setup so the hook directory + default sound packs are in place.
        if command -v peon-ping-setup >/dev/null 2>&1 && [ ! -d "$HOME/.claude/hooks/peon-ping" ]; then
            print_info "Running peon-ping-setup (downloads default sound packs)..."
            peon-ping-setup >/dev/null 2>&1 \
                && print_success "peon-ping hooks + packs installed" \
                || print_warning "peon-ping-setup failed (run manually to retry)"
        fi

        # Register useful local MCP servers if `claude` CLI is available and the
        # server isn't already registered. User-scoped so it works across projects.
        if command -v claude >/dev/null 2>&1; then
            if ! claude mcp list 2>/dev/null | grep -q '^chrome-devtools:'; then
                print_info "Registering chrome-devtools MCP (user scope)..."
                claude mcp add -s user chrome-devtools -- npx -y chrome-devtools-mcp@latest >/dev/null 2>&1 \
                    && print_success "chrome-devtools MCP registered" \
                    || print_warning "chrome-devtools MCP registration failed (re-run 'claude mcp add ...' manually)"
            else
                print_success "chrome-devtools MCP already registered"
            fi
        fi
    fi
fi

# Install .zshrc as a regular file (not symlinked by stow)
# This allows p10k configure and other tools to modify ~/.zshrc
# without polluting the git repo. The real config lives in .zshrc.base.
if [ -L "$HOME/.zshrc" ]; then
    # Migration: replace stow symlink with a copy
    rm "$HOME/.zshrc"
    cp "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
    print_success ".zshrc migrated from symlink to regular file"
elif [ ! -f "$HOME/.zshrc" ]; then
    cp "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
    print_success ".zshrc installed"
elif ! grep -q '\.zshrc\.base' "$HOME/.zshrc" 2>/dev/null; then
    # Existing .zshrc doesn't source .zshrc.base — likely the default Oh My Zsh
    # template that the OMZ installer dropped in. Replace it, keeping a backup.
    cp "$HOME/.zshrc" "$HOME/.zshrc.pre-dotfiles-$(date +%Y%m%d-%H%M%S)"
    cp "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
    print_warning ".zshrc didn't source .zshrc.base — replaced (backup saved as ~/.zshrc.pre-dotfiles-*)"
else
    print_success ".zshrc already exists (not overwriting)"
fi

# ============================================
# Install Tmux Plugin Manager
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
# Install Oh My Zsh
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
# Install Zsh plugins
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

# ============================================
# Configure Git
# ============================================
print_header "🔧 Configuring Git"

# The .gitconfig will be symlinked by stow, but let's verify
if [ -L "$HOME/.gitconfig" ]; then
    print_success "Git config symlinked"
else
    print_warning "Git config not symlinked properly"
fi

# Prompt for git user identity — writes to ~/.gitconfig.local (not the symlinked .gitconfig)
GIT_LOCAL="$HOME/.gitconfig.local"
if [ -f "$GIT_LOCAL" ] && grep -q "\[user\]" "$GIT_LOCAL" 2>/dev/null; then
    local_name=$(git config --file "$GIT_LOCAL" user.name 2>/dev/null)
    local_email=$(git config --file "$GIT_LOCAL" user.email 2>/dev/null)
    print_success "Git identity already configured: $local_name <$local_email>"
else
    print_info "Git user identity not configured. Let's set it up."

    # Prompt for name
    while true; do
        read -rp "$(echo -e "${BLUE}ℹ${NC}") Enter your full name for git commits: " git_name
        if [[ -z "$git_name" ]]; then
            print_error "Name cannot be empty."
        elif [[ ${#git_name} -lt 2 ]]; then
            print_error "Name must be at least 2 characters."
        else
            break
        fi
    done

    # Prompt for email
    while true; do
        read -rp "$(echo -e "${BLUE}ℹ${NC}") Enter your email for git commits: " git_email
        if [[ -z "$git_email" ]]; then
            print_error "Email cannot be empty."
        elif [[ ! "$git_email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            print_error "Invalid email format."
        else
            break
        fi
    done

    git config --file "$GIT_LOCAL" user.name "$git_name"
    git config --file "$GIT_LOCAL" user.email "$git_email"
    print_success "Git identity saved to ~/.gitconfig.local: $git_name <$git_email>"
fi

# ============================================
# Tmux status bar position
# ============================================
print_header "🔧 Configuring Tmux"

print_info "Where do you want the tmux status bar?"
echo "  1) top (default)"
echo "  2) bottom"
while true; do
    read -rp "$(echo -e "${BLUE}ℹ${NC}") Choose [1/2] (default: 1): " tmux_pos
    tmux_pos="${tmux_pos:-1}"
    if [[ "$tmux_pos" == "1" ]]; then
        sedi "s/set -g status-position .*/set -g status-position top/" "$DOTFILES_DIR/tmux/.tmux.conf"
        print_success "Tmux status bar set to top"
        break
    elif [[ "$tmux_pos" == "2" ]]; then
        sedi "s/set -g status-position .*/set -g status-position bottom/" "$DOTFILES_DIR/tmux/.tmux.conf"
        print_success "Tmux status bar set to bottom"
        break
    else
        print_error "Please enter 1 or 2."
    fi
done

# ============================================
# Prompt engine
# ============================================
print_header "🎨 Configuring Shell Prompt"

print_info "Which prompt engine would you like?"
echo "  1) Powerlevel10k — classic zsh prompt, configure with 'p10k configure' (Recommended)"
echo "  2) Oh My Posh — 124+ themes with live preview, cross-platform"
while true; do
    read -rp "$(echo -e "${BLUE}ℹ${NC}") Choose [1/2] (default: 1): " prompt_choice
    prompt_choice="${prompt_choice:-1}"
    if [[ "$prompt_choice" == "1" || "$prompt_choice" == "2" ]]; then
        break
    else
        print_error "Please enter 1 or 2."
    fi
done

if [[ "$prompt_choice" == "2" ]]; then
    # --- Oh My Posh ---
    # Find themes directory
    POSH_THEMES=""
    for dir in \
        "${HOME}/.cache/oh-my-posh/themes" \
        "/usr/local/share/oh-my-posh/themes" \
        "$(brew --prefix oh-my-posh 2>/dev/null)/themes"; do
        if [ -d "$dir" ]; then
            POSH_THEMES="$dir"
            break
        fi
    done

    if [ -d "$POSH_THEMES" ] && command -v fzf &>/dev/null; then
        print_info "Select a theme (↑↓ to navigate, Tab to filter, Enter to select):"

        # Build theme lists for Tab filtering
        _tmp_dir=$(mktemp -d)
        _tmp_all="$_tmp_dir/all"
        _tmp_single="$_tmp_dir/single"
        _tmp_multi="$_tmp_dir/multi"

        ls "$POSH_THEMES"/*.omp.* 2>/dev/null | \
            xargs -I{} basename {} | \
            sed -E 's/\.omp\.(json|yaml|toml)$//' | \
            sort -u > "$_tmp_all"

        > "$_tmp_single"
        > "$_tmp_multi"
        while IFS= read -r _theme; do
            _tf=""
            for ext in json yaml toml; do
                if [ -f "$POSH_THEMES/$_theme.omp.$ext" ]; then
                    _tf="$POSH_THEMES/$_theme.omp.$ext"
                    break
                fi
            done
            if [ -n "$_tf" ] && grep -qE '"newline"|type: newline|type = "newline"' "$_tf" 2>/dev/null; then
                echo "$_theme" >> "$_tmp_multi"
            else
                echo "$_theme" >> "$_tmp_single"
            fi
        done < "$_tmp_all"

        # Helper script for Tab cycling (works with all fzf versions)
        cat > "$_tmp_dir/cycle.sh" << 'CYCLE'
#!/usr/bin/env bash
dir="$1"
state=$(cat "$dir/state" 2>/dev/null || echo "all")
case "$state" in
    all)
        echo "single" > "$dir/state"
        echo "── Filter: Single line ──"
        cat "$dir/single"
        ;;
    single)
        echo "multi" > "$dir/state"
        echo "── Filter: Multi line ──"
        cat "$dir/multi"
        ;;
    *)
        echo "all" > "$dir/state"
        echo "── Filter: All themes ──"
        cat "$dir/all"
        ;;
esac
CYCLE
        chmod +x "$_tmp_dir/cycle.sh"
        echo "all" > "$_tmp_dir/state"

        omp_theme=$({ echo "── Filter: All themes ──"; cat "$_tmp_all"; } | \
            fzf \
                --height=80% \
                --layout=reverse \
                --border=rounded \
                --ansi \
                --header="Tab: filter | ↑↓ Navigate | Enter Select | Esc Cancel" \
                --header-lines=1 \
                --prompt="Theme > " \
                --preview="oh-my-posh print primary --config '${POSH_THEMES}/{}.omp.json' --shell plain 2>/dev/null || oh-my-posh print primary --config '${POSH_THEMES}/{}.omp.yaml' --shell plain 2>/dev/null || oh-my-posh print primary --config '${POSH_THEMES}/{}.omp.toml' --shell plain 2>/dev/null || echo 'Preview not available'" \
                --preview-window=down:3:wrap \
                --bind "tab:reload($_tmp_dir/cycle.sh $_tmp_dir)" \
            || true)

        rm -rf "$_tmp_dir"

        if [ -n "$omp_theme" ]; then
            for ext in json yaml toml; do
                if [ -f "$POSH_THEMES/$omp_theme.omp.$ext" ]; then
                    cp "$POSH_THEMES/$omp_theme.omp.$ext" "$HOME/.ohmyposh.omp.json"
                    break
                fi
            done
            print_success "Oh My Posh theme set to: $omp_theme"
        else
            # No theme selected — create empty sentinel so Oh My Posh loads with defaults
            echo '{}' > "$HOME/.ohmyposh.omp.json"
            print_warning "No theme selected, Oh My Posh will use its default prompt"
        fi
    else
        # No fzf or themes dir — create empty sentinel so Oh My Posh loads with defaults
        echo '{}' > "$HOME/.ohmyposh.omp.json"
        print_warning "Themes directory or fzf not found. Oh My Posh will use its default prompt."
    fi

else
    # --- Powerlevel10k ---
    # Remove Oh My Posh config so .zshrc.base picks p10k
    rm -f "$HOME/.ohmyposh.omp.json"

    # Install Powerlevel10k
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
        print_success "Powerlevel10k installed"
    else
        print_success "Powerlevel10k already installed"
    fi
    print_info "Run 'p10k configure' after restart to set up your prompt"
fi

# ============================================
# Create necessary directories
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
# Set Zsh as default shell
# ============================================
print_header "🐚 Setting Zsh as Default Shell"

if [[ "$(basename "$SHELL")" != "zsh" ]]; then
    print_info "Changing default shell to Zsh..."
    zsh_path="$(which zsh)"
    while true; do
        if chsh -s "$zsh_path"; then
            print_success "Default shell changed to Zsh"
            break
        fi
        print_warning "chsh failed or was cancelled."
        read -rp "$(echo -e "${BLUE}ℹ${NC}") Retry? [Y/n/skip]: " retry_choice
        retry_choice="${retry_choice:-y}"
        case "$retry_choice" in
            [Yy]*) continue ;;
            [Ss]*|[Nn]*)
                print_warning "Skipping shell change. Run 'chsh -s $zsh_path' later to set Zsh as default."
                break
                ;;
            *) print_error "Please enter Y, n, or skip." ;;
        esac
    done
else
    print_success "Zsh is already the default shell"
fi

# ============================================
# Final steps
# ============================================
print_header "✨ Installation Complete!"

echo ""
print_info "Next steps:"
if [[ "$prompt_choice" == "1" ]]; then
    echo "  1. Run 'p10k configure' to set up Powerlevel10k prompt"
else
    echo "  1. Run 'omp-theme' to change Oh My Posh theme anytime"
fi
echo "  2. Open tmux and press 'Ctrl-a + I' to install tmux plugins"
echo "  3. Press 'Ctrl-a + H' in tmux to view the Tmux guide"
echo "  4. Open 'nvim' — first launch auto-installs plugins (~30s)"
echo "  5. Press F10 or Space M in nvim for the VS Code-style menu bar"
echo ""
print_success "Your dotfiles are ready! 🎉"
echo ""
print_info "Backup location: $BACKUP_DIR"
echo ""
print_info "Reloading shell..."
exec zsh
