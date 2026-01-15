#!/usr/bin/env bash
# Attach to an existing session or create a new one with a consistent name

if [ -n "$TMUX" ]; then
    echo "Already inside tmux"
    exit 0
fi

# Check if there are any sessions
if tmux has-session 2>/dev/null; then
    # List sessions and let user pick, or attach to first one
    session=$(tmux list-sessions -F '#S' | fzf --prompt="Select session (Ctrl-C to create 'main') > ") || {
        # User cancelled - create new main session
        tmux new-session -As main
        exit 0
    }
    tmux attach -t "$session"
else
    # No sessions exist - create main session
    tmux new-session -s main
fi
