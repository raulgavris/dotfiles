#!/usr/bin/env bash
# Memory usage for tmux status bar (macOS)

# Get memory info
memory_pressure=$(memory_pressure | grep "System-wide memory free percentage" | awk '{print $5}' | sed 's/%//')

# Calculate used percentage
if [ -n "$memory_pressure" ]; then
    mem_used=$((100 - memory_pressure))
else
    # Fallback method
    mem_used=$(ps -A -o %mem | awk '{s+=$1} END {print int(s)}')
fi

# Color based on usage
if [ "$mem_used" -ge 80 ]; then
    color="#[fg=red]"
    icon="💥"
elif [ "$mem_used" -ge 60 ]; then
    color="#[fg=yellow]"
    icon="📊"
else
    color="#[fg=green]"
    icon="💾"
fi

echo "${color}${icon} ${mem_used}%#[default]"
