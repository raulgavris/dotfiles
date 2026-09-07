#!/usr/bin/env bash
# CPU usage for tmux status bar (macOS + Linux)

# Get CPU usage
if [[ "$OSTYPE" == "darwin"* ]]; then
    cpu_usage=$(top -l 2 -n 0 -F | grep "CPU usage" | tail -1 | awk '{print int(100-$7)}')
else
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print int($2 + $4)}')
fi

# Color based on usage
if [ "$cpu_usage" -ge 80 ]; then
    color="#[fg=red]"
    icon="🔥"
elif [ "$cpu_usage" -ge 50 ]; then
    color="#[fg=yellow]"
    icon="⚡"
else
    color="#[fg=green]"
    icon="💻"
fi

echo "${color}${icon} ${cpu_usage}%#[default]"
