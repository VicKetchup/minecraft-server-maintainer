#!/bin/bash
if [ "$TERM" != screen ]; then
    resize >/dev/null
fi

defaultDemo=true
defaultClearForFrames=true
defaultLogSize=50
defaultMaintainerMainUser=ubuntu
defaultTmuxName=server
defaultJarName=spigot
defaultMaintainerPath=/home/ubuntu

# Get passed arguments
for ARGUMENT in "$@"
do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)

    KEY_LENGTH=${#KEY}
    VALUE="${ARGUMENT:$KEY_LENGTH+1}"
    if [[ "${VALUE}" =~ " " ]] && [[ "${VALUE}" != "\""*"\"" ]]; then
        VALUE="\"$VALUE\""
    fi
    allArgs+=("$KEY"="$VALUE")

    export "$KEY"="$VALUE"
done

function getVisibleLength() {
    local string="$1"
    # echo "getVisibleLength: input string: $string" >&2
    # Remove all escape sequences
    string=$(echo -n "$string" | sed -r 's/(\\e|\\[0-9]{0,3})\[[0-9;]*[a-zA-Z]//g')
    # Remove newline characters and literal \n sequences
    string="${string//$'\n'}"
    string="${string//\\n}"
    # echo "getVisibleLength: string after removing escape sequences, newline characters, and literal \\n sequences: $string" >&2
    # Count the remaining characters
    local visibleLength=$(echo -n "$string" | wc -m)
    # echo "getVisibleLength: visible length: $visibleLength" >&2
    echo "$visibleLength"
}
# Function to center and print a given string
function centerAndPrintString() {
    # Check if a shorter string was provided for use in case of a very slim window
    if [[ -n $centerAndPrintStringShort ]] && [[ $(getVisibleLength "$1") -gt "$windowWidth" ]]; then
        stringToCenter="$centerAndPrintStringShort"
    else
        stringToCenter="$1"
    fi
    if [[ -n $2 ]]; then
        windowWidth=$2
    else
        windowWidth=$(tput cols)
    fi

    # Extract the background color from the input string
    backgroundColor=$(echo -n "$stringToCenter" | grep -oP '(?<=\\e\[)[0-9;]*m' | head -n 1)

    # Calculate the visible string length (excluding escape sequences)
    visibleStringToCenterLength=$(getVisibleLength "$stringToCenter")
    if [ -n  "$leftEdgeSymbols" ]; then
        visibleEdgesLength=$(getVisibleLength "${leftEdgeSymbols}${rightEdgeSymbols}")
        visibleStringLength=$(( visibleStringToCenterLength + visibleEdgesLength ))
    else
        visibleStringLength=$(( visibleStringToCenterLength ))
    fi

    # Calculate the spaces needed for centering
    centeringSpacesLength=$(( (windowWidth - visibleStringLength) / 2 ))

    # Print the background color for the entire line
    printf "\033[${backgroundColor}"
    printf "${leftEdgeSymbols}"
    for ((i = 0; i < windowWidth; i++)); do
        printf " "
    done
    if [ -z  "$leftEdgeSymbols" ]; then
        printf "\n"
    fi
    # Move the cursor back up one line
    tput cuu1

    # Move the cursor to the right to center the string
    if [[ $centeringSpacesLength -gt 0 ]]; then
        printf "%${centeringSpacesLength}s"
    fi

    # Print the centered string with escape sequences intact
    printf "$stringToCenter"

    endCenteringSpacesLength=$(( windowWidth - centeringSpacesLength - visibleStringLength ))
    if [[ $endCenteringSpacesLength -gt 0 ]]; then
        printf "%${endCenteringSpacesLength}s"
    fi
    printf "${rightEdgeSymbols}\033[0m"

    ## Move the cursor to the next line
    tput cud1

    # Reset the color
    tput sgr0

    # Clear to end of line
    tput el

    # Reset the variables for the next string
    unset stringToCenter
    unset leftEdgeSymbols
    unset rightEdgeSymbols
}
function printFrame1() {
    echo
    centerAndPrintString "\e[0m \e[41m              \e[030m⛏  \e[033mServer\e[30m-\e[033mMaintainer \e[030m⛏             \e[0m "
    centerAndPrintString "\e[0m \e[41;37m \e[30m⛏  \e[41;37m¤ ¤ ¤ ¤ ¤ ¤ ¤ ¤ ¤ ¤ ¤ ¤ ¤ ¤ ¤ ¤ ¤ ¤ ¤ ¤ ¤\e[30m ⚒  \e[0m "
    centerAndPrintString "\e[0m \e[41;37m    \e[41;37m¤ \e[40;30m                                     \e[41;37m ¤\e[37m    \e[0m "
    centerAndPrintString "\e[0m \e[41;37m    \e[41;37m¤ \e[40;30m                                     \e[41;37m ¤\e[37m    \e[0m "
    centerAndPrintString "\e[0m \e[41;33m K  \e[41;37m¤ \e[40;30m    \e[43;33m                             \e[40;30m    \e[41;37m ¤\e[33m  K \e[0m "
    centerAndPrintString "\e[0m \e[41;33m e  \e[41;37m¤ \e[40;30m    \e[43;33m                             \e[40;30m    \e[41;37m ¤\e[33m  e \e[0m "
    centerAndPrintString "\e[0m \e[41;33m t  \e[41;37m¤ \e[43;33m                                     \e[41;37m ¤\e[33m  t \e[0m "
    centerAndPrintString "\e[0m \e[41;33m c  \e[41;37m¤ \e[43;33m                                     \e[41;37m ¤\e[33m  c \e[0m "
    centerAndPrintString "\e[0m \e[41;33m h  \e[41;37m¤ \e[43;33m     \e[47m    \e[44m    \e[43;33m           \e[44m    \e[47m    \e[43;33m     \e[41;37m ¤\e[33m  h \e[0m "
    centerAndPrintString "\e[0m \e[41;33m u  \e[41;37m¤ \e[43;33m     \e[47m    \e[44m    \e[43;33m           \e[44m    \e[47m    \e[43;33m     \e[41;37m ¤\e[33m  u \e[0m "
    centerAndPrintString "\e[0m \e[41;33m p  \e[41;37m¤ \e[43;33m                                     \e[41;37m ¤\e[33m  p \e[0m "
    centerAndPrintString "\e[0m \e[41;30m &  \e[41;37m¤ \e[43;33m                                     \e[41;37m ¤\e[30m  & \e[0m "
    centerAndPrintString "\e[0m \e[41;33m C  \e[41;37m¤ \e[43;33m                                     \e[41;37m ¤\e[33m  C \e[0m "
    centerAndPrintString "\e[0m \e[41;33m o  \e[41;37m¤ \e[43;33m                                     \e[41;37m ¤\e[33m  o \e[0m "
    centerAndPrintString "\e[0m \e[41;37m.   \e[41;37m¤ \e[43;33m        \e[43;30m ▀▀▃▃▃\e[43;33m         \e[43;30m▃▃▃▀▀ \e[33m        \e[41;37m ¤\e[37m   .\e[0m "
    centerAndPrintString "\e[0m \e[41;37m    \e[41;37m¤ \e[43;33m              \e[43;30m▀▀▀▀▀▀▀▀▀\e[33m              \e[41;37m ¤\e[37m    \e[0m "
    centerAndPrintString "\e[0m \e[41;37m    \e[41;37m¤ \e[43;33m                                     \e[41;37m ¤\e[37m    \e[0m "
    centerAndPrintString "\e[0m \e[41;37m    \e[41;37m¤ \e[43;33m                                     \e[41;37m ¤\e[37m    \e[0m "
    centerAndPrintString "\e[0m \e[41;37m \e[30m⚔  \e[41;37m¤ ¤ ¤ ¤ ¤ ¤ ¤ ¤ ¤ ¤ ¤ ¤ ¤ ¤ ¤ ¤ ¤ ¤ ¤ ¤ ¤\e[30m ⛑  \e[0m "
    centerAndPrintString "\e[0m \e[41m              \e[030m⛏  \e[033mServer\e[30m-\e[033mMaintainer \e[030m⛏             \e[0m "
    echo
    centerAndPrintString "$footer"
    sleep $1;
}
function printFrame0() {
    echo
    echo
    echo
    centerAndPrintString "\e[0m\e[40;30m                                    \e[0m"
    centerAndPrintString "\e[0m\e[40;30m                                    \e[0m"
    centerAndPrintString "\e[0m\e[40;30m    \e[43m                           \e[40;30m    \e[0m"
    centerAndPrintString "\e[0m\e[40;30m    \e[43m                           \e[40;30m    \e[0m"
    centerAndPrintString "\e[0m\e[43m                                    \e[0m"
    centerAndPrintString "\e[0m\e[43m                                    \e[0m"
    centerAndPrintString "\e[0m\e[43m      \e[47m    \e[44m    \e[43m         \e[44m    \e[47m    \e[43m     \e[0m"
    centerAndPrintString "\e[0m\e[43m      \e[47m    \e[44m    \e[43m         \e[44m    \e[47m    \e[43m     \e[0m"
    centerAndPrintString "\e[0m\e[43m                                    \e[0m"
    centerAndPrintString "\e[0m\e[43m                                    \e[0m"
    centerAndPrintString "\e[0m\e[43m                                    \e[0m"
    centerAndPrintString "\e[0m\e[43m                                    \e[0m"
    centerAndPrintString "\e[0m\e[43m         \e[41;31m                  \e[43m         \e[0m"
    centerAndPrintString "\e[0m\e[43m         \e[41;31m                  \e[43m         \e[0m"
    centerAndPrintString "\e[0m\e[43m                                    \e[0m"
    echo
    echo
    echo
    centerAndPrintString "$footer"
    sleep $1; 
    clear
}
function printLogo() {
    if [ -f $maintainerPath/maintainer-ads.sh ]; then
        source $maintainerPath/maintainer-ads.sh
        selfPromo 1
    fi
}
function printFrames() {
    if $1; then
        leftEdgeSymbols=" \e[30m|\e[31m ⚠ \e[30m |"
        rightEdgeSymbols="\e[30m |\e[31m ⚠ \e[30m |"
        centerAndPrintString "\e[43m\e[30m | ⛏  \e[30mServer\e[31m-\e[30mMaintainer \e[31mis \e[30mLoading\e[31m...\e[30m |"
        centerAndPrintString "\e[44m"
        centerAndPrintString "\e[44mDiscord:" 
        centerAndPrintString "\e[44mhttps://discord.gg/SrCJffMVXp"
        centerAndPrintString "\e[44m"
        centerAndPrintString "\e[43;30mWays to support Ukraine"
        centerAndPrintString "\e[43;30mhttps://ukrainianinstitute.org.uk/"
        centerAndPrintString "\e[43;30mUkraine News:"
        centerAndPrintString "\e[43;30mhttps://www.newsnow.co.uk/h/World+News/Europe/Eastern+Europe/Ukraine?type=ln"
    fi
    if [[ "$demo" == "true" ]]; then
        if $1; then
            printLogo 1
        fi
        printFrame0 0.1
        if $2; then 
            clear; 
        fi
        printFrame1 0.3
    else
        if $1; then
            printLogo 0.5
            printFrame1 0.2
        else
            printFrame1 0.3
        fi
    fi
    if $2; then 
        clear; 
    fi
}
function getMaintainerScripts() {
    scriptsToSearchFor=("./maintainer-installer.sh" "./easyMaintainer.sh" "./maintainer.sh")
    foundScripts=()
    for script in "${scriptsToSearchFor[@]}"; do
        if [ -f "$script" ]; then
            foundScripts+=("$script")
        fi
    done
    if [ ${#foundScripts[@]} -gt 1 ]; then
        unset 'foundScripts[0]'
    fi
    unset availableMaintainerScripts
    if [ ${#foundScripts[@]} -gt 0 ]; then
        availableMaintainerScripts=$( IFS=$'\n'; echo "${foundScripts[*]}" )
    fi
}
# https://stackoverflow.com/a/21189044
function parse_yaml {
    local prefix=$2
    local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
    sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
    awk -F$fs '{
        indent = length($1)/2;
        vname[indent] = $2;
        for (i in vname) {if (i > indent) {delete vname[i]}}
        if (length($3) > 0) {
            vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
            printf("%s%s%s=%s\n", "'$prefix'",vn, $2, $3);
        }
    }'
}

# Set default values
if ! [ ${maintainerPath:+1} ]; then
    maintainerPath=$defaultMaintainerPath
fi
maintainerModulesPath=$maintainerPath/maintainer-modules
footer="© \e[40;33mProduct of \e[31mVicKetchup\e[33m of \e[31mKetchup \e[37m& \e[31mCo\e[37m.\e[33m Please respect the copyright \e[0m©"
# Create log file if missing
if ! [ -f "${maintainerPath}/maintainer-log.txt" ]; then
    echo "Welcome to Maintainer log!" >> $maintainerPath/maintainer-log.txt
    echo "Here you will find all data on execution of Maintainer script :)" >> $maintainerPath/maintainer-log.txt
fi
# Load config if available and not skipped
if [[ "$skipConfig" != "true" ]] && [ -f "${maintainerPath}/maintainer-config.yaml" ]; then
    centerAndPrintString "\e[042;30mmaintainer-config.yaml found, loading..."
    # Load yaml data
    configVars=$(parse_yaml $maintainerPath/maintainer-config.yaml)
    # Export variables
    while read -r line; do
        KEY=$(echo $line | cut -f1 -d=)
        KEY_LENGTH=${#KEY}
        VALUE="${line:$KEY_LENGTH+1}"
        export "$KEY"="$VALUE"
    done <<< "$configVars"
fi
# Fill in any blanks
if ! [ ${demo:+1} ]; then
    demo=$defaultDemo
fi
if ! [ ${clearForFrames:+1} ]; then
    clearForFrames=$defaultClearForFrames
fi
if ! [ ${logSize:+1} ]; then
    logSize=$defaultLogSize
fi
if ! [ ${tmuxName:+1} ]; then
    tmuxName=$defaultTmuxName
fi
if ! [ ${jarName:+1} ]; then
    jarName=$defaultJarName
fi
if ! [ ${maintainerMainUser:+1} ]; then
    maintainerMainUser=$defaultMaintainerMainUser
fi
# Create maintaner-config.yaml if missing
if ! [ -f "${maintainerPath}/maintainer-config.yaml" ]; then
    centerAndPrintString "\e[041mmaintainer-config.yaml not found, creating one..."
    echo "demo: $demo" >> $maintainerPath/maintainer-config.yaml
    echo "clearForFrames: $clearForFrames" >> $maintainerPath/maintainer-config.yaml
    echo "logSize: $logSize" >> $maintainerPath/maintainer-config.yaml
    echo "maintainerMainUser: $maintainerMainUser" >> $maintainerPath/maintainer-config.yaml
    echo "tmuxName: $tmuxName" >> $maintainerPath/maintainer-config.yaml
    echo "jarName: $jarName" >> $maintainerPath/maintainer-config.yaml
    echo "maintainerPath: $maintainerPath" >> $maintainerPath/maintainer-config.yaml
    
    echo "# To get the key for Maintainer login, do the following:" >> $maintainerPath/maintainer-config.yaml
    echo "# Run:" >> $maintainerPath/maintainer-config.yaml
    echo "# echo \$SSH_CONNECTION" >> $maintainerPath/maintainer-config.yaml
    echo "# Then run:" >> $maintainerPath/maintainer-config.yaml
    echo "# sudo grep -F ' from <first IP in output above> port <port (second number from output above)> ' /var/log/auth.log | grep ssh" >> $maintainerPath/maintainer-config.yaml
fi
# Update window width for centerAndPrintString
windowWidth=`tput cols`
# Inform user about available maintainer scripts
if [ "$TERM" != screen ] && ! [[ $isMaintainerRun ]]; then
    getMaintainerScripts
    if [ -n "$availableMaintainerScripts" ]; then
        leftEdgeSymbols="\033[41;33m ⛑  \033[47;30m > \033[46m"
        rightEdgeSymbols="\033[47m < \033[41;33m ⛑  "
        centerAndPrintString "\e[46;30m Found Maintainer scripts, following executions are available:"
        while read -r line; do
            centerAndPrintString "\e[44;37m $line"
        done <<< "$availableMaintainerScripts"
        centerAndPrintString "\e[46;30m Copy-Paste or Type to run :)"
    fi
fi
# minecraft-server-maintaner - Level up your Minecraft Server Maintanance and Control!
# Copyright (C) 2023  Viktor Tkachuk, aka. VicKetchup, from Ketchup&Co.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.