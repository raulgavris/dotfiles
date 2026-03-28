#!/usr/bin/env bash
# Battery status for tmux status bar (macOS + Linux)

if [[ "$OSTYPE" == "darwin"* ]]; then
    # Get battery info
    battery_info=$(pmset -g batt | grep -Eo "[0-9]+%" | sed 's/%//')

    # Get charging status
    charging=$(pmset -g batt | grep -q "AC Power" && echo "⚡" || echo "")
else
    if [ -d /sys/class/power_supply/BAT0 ]; then
        battery_info=$(cat /sys/class/power_supply/BAT0/capacity)
        status=$(cat /sys/class/power_supply/BAT0/status)
        [ "$status" = "Charging" ] && charging="⚡" || charging=""
    elif [ -d /sys/class/power_supply/BAT1 ]; then
        battery_info=$(cat /sys/class/power_supply/BAT1/capacity)
        status=$(cat /sys/class/power_supply/BAT1/status)
        [ "$status" = "Charging" ] && charging="⚡" || charging=""
    fi
fi

# Battery icon based on level
if [ -n "$battery_info" ]; then
    if [ "$battery_info" -ge 80 ]; then
        icon="🔋"
    elif [ "$battery_info" -ge 50 ]; then
        icon="🔋"
    elif [ "$battery_info" -ge 20 ]; then
        icon="🪫"
    else
        icon="🪫"
    fi

    # Color based on level
    if [ "$battery_info" -ge 50 ]; then
        color="#[fg=green]"
    elif [ "$battery_info" -ge 20 ]; then
        color="#[fg=yellow]"
    else
        color="#[fg=red]"
    fi

    echo "${color}${icon} ${battery_info}%${charging}#[default]"
else
    echo "🔌"
fi
