#!/usr/bin/env bash
# Quick Sessionizer - Jump to any project instantly
# Inspired by ThePrimeagen's tmux-sessionizer
# Usage: prefix + Ctrl-f

set -euo pipefail

# Define your project directories here
# Add or modify these paths to match where you keep your projects
PROJECT_DIRS=(
    "$HOME/Projects"
    "$HOME/Projects/pws"
    "$HOME/Projects/dotfiles"
)

# -----------------------------
# 1️⃣ Find all directories
# -----------------------------
# Search 1-3 levels deep in each project directory
find_projects() {
    for dir in "${PROJECT_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            # Find directories 1-3 levels deep, excluding common ignore patterns
            find "$dir" -mindepth 0 -maxdepth 1 -type d \
                ! -path "*/node_modules/*" \
                ! -path "*/.git/*" \
                ! -path "*/venv/*" \
                ! -path "*/.venv/*" \
                ! -path "*/__pycache__/*" \
                ! -path "*/dist/*" \
                ! -path "*/build/*" \
                2>/dev/null || true
        fi
    done
}

# -----------------------------
# 2️⃣ Let user pick with fzf
# -----------------------------
selected=$(find_projects | sort -u | fzf --prompt="📁 Jump to project > " --height=40% --reverse --preview="ls -la {}" --preview-window=right:50%)

# Exit if nothing selected
if [ -z "$selected" ]; then
    exit 0
fi

# -----------------------------
# 3️⃣ Create session name from path
# -----------------------------
# Convert /Users/john/Projects/my-app -> my-app
session_name=$(basename "$selected" | tr . _)

# -----------------------------
# 4️⃣ Create or switch to session
# -----------------------------
# Check if session already exists
if ! tmux has-session -t="$session_name" 2>/dev/null; then
    # Create new session detached
    tmux new-session -ds "$session_name" -c "$selected"
fi

# Switch to the session
if [ -n "${TMUX:-}" ]; then
    # We're inside tmux, use switch-client
    exec tmux switch-client -t "$session_name"
else
    # We're outside tmux, attach
    exec tmux attach-session -t "$session_name"
fi
