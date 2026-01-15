#!/usr/bin/env bash
set -euo pipefail

current="$(tmux display-message -p '#S')"

# Pick a session with preview
session_line="$(
  tmux list-sessions -F '#{session_name}|#{session_windows}|#{?session_attached,attached,detached}' |
  awk -F'|' '{printf "%-20s %2s windows  %s\n", $1, $2, $3}' |
  grep -v "^$current " |
  fzf --reverse \
      --prompt='Switch to session > ' \
      --header='Select session (Ctrl-X to kill)' \
      --preview='tmux list-windows -t {1}' \
      --preview-window=right:60% \
      --bind='ctrl-x:execute(tmux kill-session -t {1})+reload(tmux list-sessions -F "#{session_name}|#{session_windows}|#{?session_attached,attached,detached}" | awk -F"|" "{printf \"%-20s %2s windows  %s\\n\", \$1, \$2, \$3}" | grep -v "^'"$current"' ")' \
      --header-lines=0
)" || exit 0

if [ -z "$session_line" ]; then
  exit 0
fi

# Extract session name and window count
target_session=$(echo "$session_line" | awk '{print $1}')
window_count=$(echo "$session_line" | awk '{print $2}')

# If session has multiple windows, let user pick which one
if [ "$window_count" -gt 1 ]; then
  target_window="$(
    tmux list-windows -t "$target_session" -F '#{window_index}|#{window_name}|#{window_active}|#{window_panes} panes' |
    awk -F'|' '{printf "%s  %-30s %s\n", $1, $2, $4}' |
    fzf --reverse \
        --prompt="Select window in '$target_session' > " \
        --header='Pick a window' \
        --preview="tmux list-panes -t $target_session:{1}" \
        --preview-window=right:60% |
    awk '{print $1}'
  )" || exit 0
  
  if [ -n "$target_window" ]; then
    exec tmux switch-client -t "$target_session:$target_window"
  fi
else
  # Only one window, go directly to session
  exec tmux switch-client -t "$target_session"
fi
