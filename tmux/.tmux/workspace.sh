#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# 🔐 SSH Agent Setup
# -----------------------------
# Check if ssh-agent is running
if [ -z "${SSH_AUTH_SOCK:-}" ] || ! ssh-add -l &>/dev/null; then
    echo "🔐 Starting SSH agent..."
    eval "$(ssh-agent -s)" > /dev/null
    
    # Find and add all SSH private keys
    ssh_dir="$HOME/.ssh"
    if [ -d "$ssh_dir" ]; then
        # Find private keys (exclude .pub, known_hosts, config, etc.)
        while IFS= read -r key; do
            # Check if it's actually a private key
            if ssh-keygen -l -f "$key" &>/dev/null; then
                echo "  Adding key: $(basename "$key")"
                ssh-add "$key" 2>/dev/null || echo "  ⚠️  Skipped: $(basename "$key") (passphrase required or invalid)"
            fi
        done < <(find "$ssh_dir" -maxdepth 1 -type f ! -name "*.pub" ! -name "known_hosts*" ! -name "config" ! -name "authorized_keys" 2>/dev/null)
    fi
    echo ""
else
    echo "✅ SSH agent already running"
    echo ""
fi

# -----------------------------
# 1️⃣ Pick multiple directories
# -----------------------------
dirs=$(zoxide query -l | fzf --multi --reverse --prompt='Select repos > ') || exit 0

if [ -z "$dirs" ]; then
  exit 0
fi

# Convert to array (compatible method)
dirs_array=()
while IFS= read -r line; do
    dirs_array+=("$line")
done <<< "$dirs"

# --------------------------------------
# 2️⃣ Get workspace name from user
# --------------------------------------
default_name=$(basename "${dirs_array[0]}")
# Use head -1 to get what user typed (not what they selected)
workspace=$(echo "$default_name" | fzf --print-query --prompt="Workspace name > " --header="Type name and press Enter (default: $default_name)" | head -1) || exit 0

# Use default if empty
workspace=${workspace:-$default_name}

# --------------------------------------
# 3️⃣ Create session if it doesn't exist
# --------------------------------------
if ! tmux has-session -t "$workspace" 2>/dev/null; then
    # First window = first repo
    first_dir="${dirs_array[0]}"
    if git -C "$first_dir" rev-parse --show-toplevel &>/dev/null; then
        first_dir=$(git -C "$first_dir" rev-parse --show-toplevel)
    fi
    tmux new-session -ds "$workspace" -c "$first_dir" -n "$(basename "$first_dir")"
    
    # Remaining windows = other repos
    for i in "${!dirs_array[@]}"; do
        if [ "$i" -eq 0 ]; then
            continue  # Skip first element (already created)
        fi
        repo_dir="${dirs_array[$i]}"
        if git -C "$repo_dir" rev-parse --show-toplevel &>/dev/null; then
            repo_dir=$(git -C "$repo_dir" rev-parse --show-toplevel)
        fi
        tmux new-window -d -t "$workspace:" -c "$repo_dir" -n "$(basename "$repo_dir")"
    done
fi

# -----------------------------
# 4️⃣ Switch to the workspace session
# -----------------------------
if [ -n "${TMUX:-}" ]; then
    # Inside tmux - switch client
    exec tmux switch-client -t "$workspace"
else
    # Outside tmux - attach directly  
    exec tmux attach -t "$workspace"
fi
