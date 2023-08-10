#!/bin/bash
success=false
defaultTmuxName=server
defaultMaintainerPath=/home/ubuntu

for ARGUMENT in "$@"
do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)

    KEY_LENGTH=${#KEY}
    VALUE="${ARGUMENT:$KEY_LENGTH+1}"

    export "$KEY"="$VALUE"
done

if ! [ ${maintainerPath:+1} ]; then
    maintainerPath=$defaultMaintainerPath
fi

# Functions
source $maintainerPath/maintainer-common.sh

if [ ${getArgs:+1} ]; then
    if [[ "$getArgs" == "true" ]]; then
        echo "tmuxName=$defaultTmuxName"
    else
        echo -e \\"e[041mBad value provided for parameter \\e[044mgetArgs\\e[041m!\\e[0m"
    fi
else
    # Code
    if ! [ ${tmuxName:+1} ]; then
        tmuxName=$defaultTmuxName
    fi

    sudo tmux -S /var/$tmuxName-tmux/$tmuxName has-session -t $tmuxName
    if [ $? != 0 ]; then
        centerAndPrintString "\e[042;30mCan't stop server in tmux session '\e[0m\e[044m $tmuxName \e[042;30m', as the session doesn't exist!\e[0m\n"
    else
        pid=$(pgrep -u ubuntu java 2>/dev/null)
        numberReg='^[0-9]+$'
        if ! [[ $pid =~ $numberReg ]]; then
            pid=$(pgrep -u root java 2>/dev/null)
        fi
        if [[ $pid =~ $numberReg ]]; then
            centerAndPrintString "\e[043;30m> Stopping server...\e[0m"
            sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "bc &4Server is stopping in &d 10 &4 seconds!" ENTER
            sudo sleep 4
            sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "bc &4Server is stopping in &d 5 &4 seconds!" ENTER
            sudo sleep 2
            sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "bc &4Server is stopping in &d 3 &4 seconds!" ENTER
            sudo sleep 1
            sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "bc &4Server is stopping in &d 2 &4 seconds!" ENTER
            sudo sleep 1
            sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "bc &4Server is stopping in &d 1 &4 seconds!" ENTER
            sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 stop ENTER
            sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "bc &4Server is stopping in &d 0 &4 seconds!" ENTER
            timeout 10 tail --pid=$pid -f /dev/null
            centerAndPrintString "\e[042;30m> Server stopped, closing tmux session '\e[0m\e[044m $tmuxName \e[042;30m' :)\e[0m\n"
        else
            centerAndPrintString "\e[044mNo instances of java were found!\e[0m\n"
        fi
        sudo tmux -S /var/$tmuxName-tmux/$tmuxName kill-session -t $tmuxName
        success=true
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