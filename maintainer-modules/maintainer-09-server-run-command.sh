#!/bin/bash
success=false
defaultTmuxName="server"
defaultUsername=$USER
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
if ! [ ${username:+1} ]; then
    username=$defaultUsername
fi
if ! [ ${maintainerPath:+1} ]; then
    maintainerPath=$defaultMaintainerPath
fi

# Function
source $maintainerPath/maintainer-common.sh

function getCommandFromUser {
    centerAndPrintString "\e[042;30m> Please enter command to run <\e[0m"
    read command
    if [[ "${command}" == "" ]]; then
        unset command
    fi
}

function executeCommand {
    sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "helpop executing command '${command}' by user ${username} from maintainer"  ENTER
    sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "${command}"  ENTER
    centerAndPrintString "\e[042;30m> Command executed :) <\e[0;37m"
    success=true
}

if [ ${getArgs:+1} ]; then
    if [[ "$getArgs" == "true" ]]; then
        echo "tmuxName=$defaultTmuxName command=\"command here\""
    else
        echo -e \\"e[041mBad value provided for parameter \\e[044mgetArgs\\e[041m!\\e[0m"
    fi
else
    # Code
    if [[ "${easyMode}" == "true" ]]; then
        getCommandFromUser
    fi
    if [ ${command:+1} ]; then
        executeCommand
    else
        getCommandFromUser
        if [ ${command:+1} ]; then
            executeCommand
        else
            sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "helpop Maintainer module 'server-run-command' executed with no command by user ${username}"  ENTER
            centerAndPrintString "\e[041m> Please provide command to run <\e[0m\n"
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