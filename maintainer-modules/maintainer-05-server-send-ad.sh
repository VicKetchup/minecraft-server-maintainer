#!/bin/bash
success=false
defaultTmuxName="server"
defaultFormat="&4"
defaultMaintainerPath=/home/ubuntu

for ARGUMENT in "$@"
do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)

    KEY_LENGTH=${#KEY}
    VALUE="${ARGUMENT:$KEY_LENGTH+1}"
    
    export "$KEY"="$VALUE"
done

if ! [ ${tmuxName:+1} ]; then
    tmuxName=$defaultTmuxName
fi
if ! [ ${format:+1} ]; then
    format=$defaultFormat
fi
if ! [ ${maintainerPath:+1} ]; then
    maintainerPath=$defaultMaintainerPath
fi

# Functions
source $maintainerPath/maintainer-common.sh

function getMessageFromUser {
    centerAndPrintString "\e[042;30m> Please enter your message: <"
    read message
    if [[ "${message}" == "" ]]; then
        unset message
    fi
}
function runAdvert() {
    # Inform and disable chat
    sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "helpop Maintainer advert module executed by user ${username}" ENTER
    sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "upc RemoveGroupPermission default essentials.chat.local" ENTER

    # windowWidth=320
    # Print logo
    while read -r line; do
        if [[ -n "$line" ]]; then
            if ! [[ "${line}" =~ "[m(\ )*" ]]; then
                visibleLine="$(echo "$line" | awk '{gsub(/ /, ".", $0); print}')"
                visibleLine="$(echo "$visibleLine" | awk '{gsub(/\x1b\[[0-9;]*m/, "", $0); print}')"
                visibleLine="${visibleLine:3}"

                if ! [[ "${visibleLine}" =~ "K".* ]]; then
                    if [[ -n "$visibleLine" ]]; then
                        printf "$visibleLine"; echo
                        sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "broadcast &a'${visibleLine}'" ENTER
                    fi
                fi
            fi
        fi
    done <<< `printLogo 1`
    # windowWidth=$(tput cols)

    # Re-enable chat
    sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "upc AddGroupPermission default essentials.chat.local" ENTER

    centerAndPrintString "\e[042;30m> Advert Broadcasted :) <"
    success=true
}

if [ ${getArgs:+1} ]; then
    if [[ "$getArgs" == "true" ]]; then
        echo "format=${defaultFormat} message=\"Text here\" tmuxName=$defaultTmuxName"
    else
        echo -e \\"e[041mBad value provided for parameter \\e[044mgetArgs\\e[041m!\\e[0m"
    fi
else
    # Code
    runAdvert
    # Log results
    if [ ${isMaintainerRun:+1} ] && [[ "${isMaintainerRun}" == "true" ]]; then
        if [[ "${success}" == "true" ]]; then
            if ! [ ${skipSuccessLog:+1} ] || [[ "${skipSuccessLog}" == "false" ]]; then
                echo "~" >> $maintainerPath/maintainer-log.txt
            fi
        fi
    fi
    skipSuccessLog=false
fi