#!/usr/bin/env bash
set -euo pipefail

current="$(tmux display-message -p '#S')"

# Pick session(s) to kill with preview (multi-select with Tab)
targets="$(
  tmux list-sessions -F '#{session_name}|#{session_windows}|#{?session_attached,attached,detached}' |
  awk -F'|' '{printf "%-20s %2s windows  %s\n", $1, $2, $3}' |
  grep -v "^$current " |
  fzf --multi \
      --reverse \
      --prompt='Kill session(s) (Tab to select multiple) > ' \
      --header='⚠️  Select sessions to kill (current session excluded)' \
      --preview='tmux list-windows -t {1}' \
      --preview-window=right:60% |
  awk '{print $1}'
)" || exit 0

if [ -z "$targets" ]; then
  exit 0
fi

# Kill each selected session
while IFS= read -r session; do
  if [ -n "$session" ]; then
    tmux kill-session -t "$session"
  fi
done <<< "$targets"
