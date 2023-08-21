#!/bin/bash
success=false
defaultTmuxName=server
defaultAction=stopping
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
if ! [ ${action:+1} ]; then
    action=$defaultAction
fi
if ! [ ${maintainerPath:+1} ]; then
    maintainerPath=$defaultMaintainerPath
fi

# Functions
source $maintainerPath/maintainer-common.sh

if [ ${getArgs:+1} ]; then
    if [[ "$getArgs" == "true" ]]; then
        echo "tmuxName=$defaultTmuxName action=$defaultAction maintainerPath=$defaultMaintainerPath"
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
        centerAndPrintString "\e[042;30mCan't stop server in tmux session '\e[0m\e[044m $tmuxName \e[042;30m', as the session doesn't exist!"
    else
        pid=$(pgrep -u ubuntu java 2>/dev/null)
        numberReg='^[0-9]+$'
        if ! [[ $pid =~ $numberReg ]]; then
            pid=$(pgrep -u root java 2>/dev/null)
        fi
        if [[ $pid =~ $numberReg ]]; then
            centerAndPrintString "\e[043;30m> Stopping server... <"
            sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "bc &4Server is $action in &d 25 &4 seconds!" ENTER
            sudo sleep 14
            sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "bc &4Server is $action in &d 10 &4 seconds!" ENTER
            sudo sleep 4
            sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "bc &4Server is $action in &d 5 &4 seconds!" ENTER
            sudo sleep 1
            sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "bc &4Server is $action in &d 4 &4 seconds!" ENTER
            sudo sleep 1
            sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "bc &4Server is $action in &d 3 &4 seconds!" ENTER
            sudo sleep 1
            sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "bc &4Server is $action in &d 2 &4 seconds!" ENTER
            sudo sleep 1
            sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "bc &4Server is $action in &d 1 &4 seconds!" ENTER
            sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 stop ENTER
            sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "bc &4Server is $action in &d 0 &4 seconds!" ENTER
            timeout 10 tail --pid=$pid -f /dev/null
            centerAndPrintString "\e[042;30m> Server stopped, closing tmux session '\e[0m\e[044m $tmuxName \e[042;30m' :) <"
        else
            centerAndPrintString "\e[044mNo instances of java were found!"
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