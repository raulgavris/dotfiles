#!/bin/bash

EWW=`which eww`
CFG="$HOME/.config/eww/bar"

## Run eww daemon if not running already
if [[ ! `pidof eww` ]]; then
	${EWW} daemon
	sleep 1
fi

## Open widgets 
run_eww() {
	${EWW} --config "$CFG" open-many \
		   left \
		   center \
		   right
}

## Launch or close widgets accordingly
run_eww