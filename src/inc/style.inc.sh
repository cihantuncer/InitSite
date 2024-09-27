#!/bin/bash

# --- Style Codes ------------------------
 
blk_="\e[5m"  # Blink : Start
_blk="\e[25m" # Blink : Stop
und_="\e[4m"   # Underlined : Start
_und="\e[24m"  # Underlined : Stop

# Foregrounds
fblk_="\e[30m" # Fore Color : Black
fred_="\e[31m" # Fore Color : Red
fgrn_="\e[32m" # Fore Color : Green
fylw_="\e[33m" # Fore Color : Yellow
fblu_="\e[34m" # Fore Color : Blue
fmgt_="\e[35m" # Fore Color : Magenta
fcyn_="\e[36m" # Fore Color : Cyan
fgry_="\e[90m" # Fore Color : Grey
fwht_="\e[97m" # Fore Color : White

# Backgrounds
bblk_="\e[40m"  # Back color : Black
bred_="\e[41m"  # Back color : Red
bgrn_="\e[42m"  # Back color : Green
bylw_="\e[43m"  # Back color : Yellow
bblu_="\e[44m"  # Back color : Blue
bmgt_="\e[45m"  # Back color : Magenta
bcyn_="\e[46m"  # Back color : Cyan
bgry_="\e[100m" # Back color : Grey
bwht_="\e[107m" # Back color : White

inv_="\e[7m"    # Inverted colors
_e="\e[0m"      # Reset

declare -A colors=(

    ["black"]="30"    # Fore Color : Black
    ["red"]="31"      # Fore Color : Red
    ["green"]="32"    # Fore Color : Green
    ["yellow"]="33"   # Fore Color : Yellow
    ["blue"]="34"     # Fore Color : Blue
    ["white"]="97"    # Fore Color : White
    ["-black"]="40"   # Back Color : Black
    ["-red"]="41"     # Back Color : Red
    ["-green"]="42"   # Back Color : Green
    ["-yellow"]="43"  # Back Color : Yellow
    ["-blue"]="44"    # Back Color : Blue
    ["-white"]="107"  # Back Color : White
    ["inv"]="7"       # Inverted Colors
)

function style {

    local text="$1"

    for style in "${!colors[@]}"; do
        text=$(echo "$text" | sed -e "s|<$style>|$(printf '\e[%sm' "${colors[$style]}")|g" -e "s|</$style>|$(printf '\e[0m')|g")
    done

    text=$(echo "$text" | sed -e "s|</>|$(printf '\e[0m')|g" \
                              -e 's|<!>\([^<]*\)</!>|\\e[5m\1\\e[25m|g' \
                              -e 's|\*\([^*]*\)\*|\\e[1m\1\\e[22m|g' \
                              -e 's|_\([^_]*\)_|\\e[4m\1\\e[24m|g' \
                              -e 's|- \([^-]*\)-|\\e[9m\1\\e[29m|g' \
    )

    text="$text\e[0m"

    echo -e $text
}