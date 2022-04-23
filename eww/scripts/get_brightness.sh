#!/bin/bash

regex="[0-9]+%"
brightness=$(brightnessctl info)

if [[ $brightness =~ $regex ]]
    then
        brightness="${BASH_REMATCH[0]}"
fi
echo "$brightness"