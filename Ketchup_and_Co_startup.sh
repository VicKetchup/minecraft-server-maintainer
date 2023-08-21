#!/bin/bash
printServerInfo=true
clearForFrames=false
export "isMaintainerRun"="true"
source maintainer-common.sh clearForFrames=$clearForFrames
sleep 1
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
    centerAndPrintString "\e[0m  \e[040m█    █\e[0m    \e[041m█▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒\e[44m█     ▀             █\e[0m"
    centerAndPrintString "\e[0m \e[040m█    ▀\e[0m▄  ▄█\e[044m▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀       ▒            █\e[0m"
    centerAndPrintString "\e[0m \e[040m▀▄    ▀▀▀\e[44m▒                   ▄▄\e[0m▀\e[44m█\e[44m▒         ▒█\e[0m"
    centerAndPrintString "$footer"
    sleep $1;
}

function tryWindowsDriveInfo() {
    disk_info=`powershell.exe -c "wmic diskdrive get model,size" | sed -e '1d' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | awk 'NF>0 {model=substr($0, 1, 25); size=substr($0, 26); printf "%-25s %5.0fGB\n", model, size/1024/1024/1024}'`
    if [ -z  "$disk_info" ]; then
        disk_info="N/A"
    fi
}

function printServerInfo() {
    # Get the OS name and version
    os_name=$(lsb_release -si)
    os_version=$(lsb_release -sr)

    # Get the CPU model and frequency
    cpu_model=$(lscpu | grep "Model name" | cut -d ":" -f 2 | xargs)
    cpu_freq=$(cat /proc/cpuinfo | grep "cpu MHz" | head -n 1 | cut -d ":" -f 2 | xargs)

    # Get the total and free memory
    mem_total=$(free -h | grep "Mem" | awk '{print $2}')
    mem_free=$(free -h | grep "Mem" | awk '{print $4}')

    # Check if sensors package is installed
    if command -v sensors &> /dev/null; then
        # Get the CPU temperature
        cpu_temp=$(sensors 2> /dev/null | grep "Core 0" | awk '{print $3}')
    else
        # Set the CPU temperature to N/A
        cpu_temp="N/A"
    fi

    # Print the system information using the centerAndPrintString function
    centerAndPrintString "\e[44;37m Server info:"
    centerAndPrintString "\e[42;30m OS: $os_name $os_version"
    centerAndPrintString "\e[42;30m CPU: $cpu_model ($cpu_freq MHz)"
    centerAndPrintString "\e[42;30m Memory: $mem_total total, $mem_free free"
    # Print the CPU temperature only if it is not N/A
    if [ "$cpu_temp" != "N/A" ]; then
        centerAndPrintString "\e[42;30m CPU Temperature: $cpu_temp"
    fi

    # Check if lshw package is installed
    if command -v lshw &> /dev/null; then
        disk_info="$(sudo lshw -class disk 2> /dev/null | awk '/physical id:/ {sub("physical id: ", ""); gsub(/\s+/, ""); printf "%s", $0}/product:/ {sub("product: ", ""); gsub(/\s+/, " "); printf "%s ", $0} /size:/  {sub("size: ", ""); gsub(/\s+/, " "); printf "%s\n", $0}')"
        # Check if disk_info is empty
        if [ -z "$disk_info" ]; then
            tryWindowsDriveInfo
        fi
    else
        tryWindowsDriveInfo
    fi

    # Print the disk info only if it is not empty or N/A
    if [ ! -z "$disk_info" ] && [ "$disk_info" != "N/A" ]; then
        centerAndPrintString "\e[42;30m Disk(s):"
        # Loop through each line of the disk_info variable
        while read -r line; do
            # Pass the line to the centerAndPrintString function
            centerAndPrintString "\e[42;30m $line"
        done <<< "$disk_info"
    fi
}

function printFrames() {
    if $2; then 
        clear
    fi
    leftEdgeSymbols="\033[43;30m>> \033[41;33m ⛑  \033[47;30m > \033[42;30m"
    rightEdgeSymbols="\033[47m < \033[41;33m ⛑  \033[43;30m <<"
    centerAndPrintString "\e[42;30m Executing from \e[31m${0##*/}\e[30m"
    printLogo 0.1
    if $2; then 
        clear
    fi
    if $1; then 
        printServerInfo
    fi
    leftEdgeSymbols="\033[41;33m ❣ \033[47;30m > \033[46m"
    rightEdgeSymbols="\033[47;30m < \033[41;33m ❣ "
    centerAndPrintString "\e[46;30m Welcome \e[31m$USER \e[30m❣"
}

function getMaintainerScripts() {
    scriptsToSearchFor=("./maintainer-common.sh" "./easyMaintainer.sh" "./maintainer.sh")
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
    /bin/bash ${maintainerModulesPath}/maintainer-[0-9]*-server-status.sh colour=true
}

windowWidth=`tput cols`
if [ "$TERM_PROGRAM" != tmux ]; then
    resize >/dev/null
    sleep 0.1
    footer=" \e[0m© \e[40;33mProduct of \e[31mVicKetchup\e[33m of \e[31mKetchup \e[37m& \e[31mCo\e[37m.\e[33m Please respect the copyright \e[0m© "
    printFrames $printServerInfo $clearForFrames
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