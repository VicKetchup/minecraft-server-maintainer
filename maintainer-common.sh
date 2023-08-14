#!/bin/bash
defaultJarName=spigot
defaultTmuxName=server
defaultMaintainerPath=/home/ubuntu
defaultPath=$defaultMaintainerPath/server
maintainerMainUser=ubuntu
if [ "$TERM_PROGRAM" != tmux ]; then
    resize >/dev/null
fi
function getVisibleLength() {
    local string="$1"
    # echo "getVisibleLength: input string: $string" >&2
    # Remove all escape sequences
    string=$(echo -n "$string" | sed -r 's/(\\e|\\033)\[[0-9;]*[a-zA-Z]//g')
    # Remove newline characters and literal \n sequences
    string="${string//$'\n'}"
    string="${string//\\n}"
    # echo "getVisibleLength: string after removing escape sequences, newline characters, and literal \\n sequences: $string" >&2
    # Count the remaining characters
    local visibleLength=$(echo -n "$string" | wc -m)
    # echo "getVisibleLength: visible length: $visibleLength" >&2
    echo "$visibleLength"
}

# Function to center and print a given string with a blue background
function centerAndPrintString() {
    # Check if a shorter string was provided for use in case of a very slim window
    if [[ -n $centerAndPrintStringShort ]] && [[ $(getVisibleLength "$1") -gt "$windowWidth" ]]; then
        stringToCenter="$centerAndPrintStringShort"
    else
        stringToCenter="$1"
    fi
    windowWidth=$(tput cols)

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

footer=" \e[0m© \e[40;33mProduct of \e[31mVicKetchup\e[33m of \e[31mKetchup \e[37m& \e[31mCo\e[37m.\e[33m Please respect the copyright \e[0m© "

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
    centerAndPrintString "\e[0m               ▄█▀▀▀▀▀▀█▄█\e[047m▀▒▒▒▒▒▒▒▒▀\e[0m█▄▄\e[0m"
    centerAndPrintString "\e[0m                 \e[040m█         █\e[047m▒▒▒\e[0m         ▀██▀\e[0m"
    centerAndPrintString "\e[0m                 \e[040m█         █▒    ██\e[0m☰☰☰☰☰☰█\e[0m"
    centerAndPrintString "\e[0m                  ▀\e[040m█    ▒     █▄ █\e[0m   \e[044m▒☠ ▒█\e[0m"
    centerAndPrintString "\e[0m                   \e[040m \e[047m▀\e[040m▄     ▄      ██\e[0m  \e[044m▒▒▒\e[047m█\e[0m"
    centerAndPrintString "\e[0m    \e[043m▄\e[0m                \e[040m▄▀▒▀▄▄▄    ▒▒███\e[0m    ▄\e[047m▀\e[0m▀\e[047m█\e[0m"
    centerAndPrintString "\e[0m         \e[041m▒█▒\e[0m             ▄\e[040m▀▒▒▒▒▒ ▀▄▀▒   ▒▒▀█████▒▒██▄\e[0m   ▒"
    centerAndPrintString "\e[0m       ▄\e[041m█ █\e[0m▄          ▄\e[041m█▒▒▒▒▒▒▒▒▒▒\e[040m█▒▒    ▒▒▒██▒▒\e[041m▀▀\e[43m▀▀\e[0m▄▄▄"
    centerAndPrintString "\e[0m    \e[041m█▒ ▒█\e[0m         ▄\e[041m▀            █\e[0m█▒▒▒▒▒▀████████ \e[0m"
    centerAndPrintString "\e[0m   \e[041m█▒  ▒█\e[0m       ▄\e[041m▀                 \e[040m██▒▒▒▒▒█ ▒ ▒ █\e[0m"
    centerAndPrintString "\e[0m   \e[041m█▒  ▒\e[0m█▀      \e[041m█ \e[037mKetchup&Co. █      \e[0m██ █ █      █ \e[0m"
    centerAndPrintString "\e[0m  \e[041m█▒▒ ▒█\e[0m      \e[041m█             █\e[0m \e[41m█      \e[040m█  \e[0m██      █\e[0m"
    centerAndPrintString "\e[0m  \e[041m█▒▒\e[0m \e[41m▒█\e[0m      \e[041m█             █\e[0m  \e[041m█      \e[040m█   \e[040m█    █\e[0m "
    centerAndPrintString "\e[0m  \e[040m█\e[41m▒\e[0m   █    \e[41m█              █\e[040m   \e[041m█▒▒▒▒▒▒█\e[040m   █   █\e[0m"
    centerAndPrintString "\e[0m     \e[040m█    █\e[0m   \e[041m█             █\e[0m     \e[040m█      \e[040m▀█▄▀    █\e[0m "
    centerAndPrintString "\e[0m    \e[040m█    █\e[0m   \e[041m█             █\e[0m      \e[040m█             █\e[0m"
    centerAndPrintString "\e[0m     \e[040m█    █\e[0m   \e[041m█             █\e[0m▄\e[44m▀▀▀▀▀▀\e[040m▄▄▄           ▀▄\e[0m"
    centerAndPrintString "\e[0m   \e[040m█    █\e[0m   \e[041m█              █\e[44m        ▀▀▀\e[040m▄▄▄▄▄▄▄▄▄▄▀\e[0m"
    centerAndPrintString "\e[0m \e[040m█    █\e[0m   \e[041m█              ▀█\e[44m    ▒▄▄▄▄▄▄▀▀▀▀▀▀█\e[0m▄"
    centerAndPrintString "\e[0m  \e[040m█    █\e[0m    \e[041m█▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒\e[44m█     ▀              █\e[0m"
    centerAndPrintString "\e[0m \e[040m█    ▀\e[0m▄  ▄█\e[044m▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀       ▒            █\e[0m"
    centerAndPrintString "\e[0m \e[040m▀▄    ▀▀▀\e[44m▒                   ▄▄\e[0m▀\e[44m█\e[44m▒         ▒█\e[0m"
    centerAndPrintString "$footer"
    sleep $1;
}

function printFrames() {
    if $1; then
        leftEdgeSymbols=" \e[30m|\e[31m ⚠ \e[30m |"
        rightEdgeSymbols="\e[30m |\e[31m ⚠ \e[30m |"
        centerAndPrintString "\e[43m\e[30m | \e[37m⛏  \e[30mServer\e[31m-\e[30mMaintainer \e[31mis \e[30mLoading...\e[30m |"
    fi
    if $demo; then
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

function runInstaller() {
    ./maintainer.sh module=server-installer
}

if ! [ ${jarName:+1} ]; then
    jarName=$defaultJarName
fi
if ! [ ${tmuxName:+1} ]; then
    tmuxName=$defaultTmuxName
fi
if ! [ ${path:+1} ]; then
    path=$defaultPath
fi
if ! [ ${maintainerPath:+1} ]; then
    maintainerPath=$defaultMaintainerPath
fi
maintainerModulesPath=$maintainerPath/maintainer-modules

windowWidth=`tput cols`
hasTmux=`dpkg -l | grep "tmux" | awk '{print $2}'`
if [[ "$hasTmux" -ne "0" ]]; then
    sudo apt update
    sudo apt install tmux
fi

if ! [ -d "$maintainerModulesPath" ]; then
    # TODO: Download maintainer from git and execute wtih server-installer module if it is available, if not, download it from the maintainer-modules folder in the repository and execute it, place holder git URL = <git-url>, execute using ssh
    # Download maintainer script from git and execute it if available - AI genereted
    if git clone https://github.com/VicKetchup/minecraft-server-maintainer minecraft-server-maintainer; then
        centerAndPrintString "\e[43;30mGit clone successful. Executing the maintainer script..."
        cd minecraft-server-maintainer
        runInstaller
    else
        centerAndPrintString "\e[42mGit clone failed. Trying to download from repository's maintainer-modules folder..."
        if wget https://github.com/VicKetchup/minecraft-server-maintainer; then
            echo "\e[43;30mDownload successful. Executing the maintainer script..."
            runInstaller
        else
            echo "\e[41mDownload failed. The maintainer script is not available."
        fi
    fi
fi
