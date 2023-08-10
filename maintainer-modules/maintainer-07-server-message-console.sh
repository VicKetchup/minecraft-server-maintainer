#!/bin/bash
success=false
defaultTmuxName="prison"
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
    centerAndPrintString "\e[042;30m> Please enter your message: <\e[0m"
    read message
    if [[ "${message}" == "" ]]; then
        unset message
    fi
}

function sendMessage {
    sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "helpop Maintainer message module executed by user ${username}" ENTER
    sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "bc $username: ${format}${message}" ENTER
    centerAndPrintString "\e[042;30m> Message Broadcasted :) <\e[0;37m"
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
    if [[ "${easyMode}" == "true" ]]; then
        getMessageFromUser
    fi
    if [ ${message:+1} ]; then
        sendMessage
    else
        getMessageFromUser
        if [ ${message:+1} ]; then
            sendMessage
        else
            sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "helpop Maintainer module 'server-message-console' executed with no message by user ${username}"  ENTER
            centerAndPrintString "\e[041m> Please provide message to broadcast it to the server <\e[0m\n"
        fi
    fi
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