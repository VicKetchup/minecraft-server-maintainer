#!/bin/bash
success=false
defaultTmuxName=server
defaultColour='false'
defaultMaintainerPath=/home/ubuntu
defaultServerFolder=server

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
if ! [ ${maintainerPath:+1} ]; then
    maintainerPath=$defaultMaintainerPath
fi
if ! [ ${serverFolder:+1} ]; then
    serverFolder=$defaultServerFolder
fi
if ! [ ${colour:+1} ]; then
    if [[ "${easyMode}" == "true" ]]; then
        colour="true"
    else
        colour=$defaultColour
    fi
fi

# Functions
if ! [ ${getArgs:+1} ]; then
    source $maintainerPath/maintainer-common.sh skipConfig=false
fi


if [ ${getArgs:+1} ]; then
    if [[ "$getArgs" == "true" ]]; then
        echo "tmuxName=$defaultTmuxName colour=false"
    else
        echo -e \\"e[041mBad value provided for parameter \\e[044mgetArgs\\e[041m!\\e[0m"
    fi
else
    # Code
    # Install jq if not installed
    if ! which jq >/dev/null; then
        echo -e "\e[42mInstalling jq...\e[0m"
        sudo apt update
        sudo apt install jq
    fi

    if ! [ ${tmuxName:+1} ]; then
        tmuxName=$defaultTmuxName
    fi

    isTmuxRunning=false
    tmuxStatusString="None running"
    sudo tmux -S /var/$tmuxName-tmux/$tmuxName has-session -t $tmuxName > /dev/null 2>&1
    if [ $? == 0 ]; then
        isTmuxRunning=true
        tmuxStatusString=$tmuxName
    fi

    isServerRunning=true
    numberReg='^[0-9]+$'
    pid=$(pgrep -u ubuntu java 2>/dev/null)
    if ! [[ $pid =~ $numberReg ]]; then
        pid=$(pgrep -u root java 2>/dev/null)
        if ! [[ $pid =~ $numberReg ]]; then
            isServerRunning=false
        fi
    fi
    
    unset conditionalInfo
    storageTakenUpByServer="0"
    if compgen -G "${maintainerPath}/${serverFolder}" > /dev/null; then
        storageTakenUpByServer=$(du -sh "${maintainerPath}/${serverFolder}" | awk '{print $1}')
    fi
    infoString="tmux=$isTmuxRunning ($tmuxName) | server-running=$isServerRunning | storage-usage=$storageTakenUpByServer"
    if $isServerRunning; then
        systemColor="\e[42;30m"
        javaCPU=$(ps aux | grep java | grep -v grep | awk '{print $3 / 10}')
        cpuColor="\e[42;30m"
        if (( $(echo "$javaCPU > 15" |bc -l) )); then
            cpuColor="\e[43;30m"
            systemColor="\e[43;30m"
        elif (( $(echo "$javaCPU > 40" |bc -l) )); then
            cpuColor="\e[41;30m"
            systemColor="\e[41;30m"
        fi
        javaRAMPercent=$(ps aux | grep java | grep -v grep | awk '{print $4}')
        RAMColor="\e[42;30m"
        if (( $(echo "$javaRAMPercent > 40" |bc -l) )); then
            RAMColor="\e[43;30m"
            if [[ "$systemColor" == "\e[42;30m" ]]; then
                systemColor="\e[43;30m"
            fi
        elif (( $(echo "$javaRAMPercent > 80" |bc -l) )); then
            RAMColor="\e[41;30m"
            systemColor="\e[41;30m"
        fi
        javaRAMBytes=$(ps aux | grep java | grep -v grep | awk '{print $6}')
        javaRam=$(echo "scale=2; $javaRAMBytes / 1024 / 1024" | bc)
        storageTakenUpByBackups="0B"
        if [ -d /backups ]; then
            storageTakenUpByBackups=$(cd /backups; du -sh --exclude "./lost+found" | awk '{print $1}' | awk '{print $1}'; cd ~)
        fi
        infoString2="\e[47;30mcpu-usage\e[0m\e[44m=$cpuColor$javaCPU%%\e[0m\e[44m | \e[47;30mram-usage\e[0m\e[44m=$RAMColor$javaRAMPercent%%\e[0m\e[44m | ram-raw=${javaRam}G | backups-size=${storageTakenUpByBackups}"
        
        serverIp=`hostname -I | awk '{print $1}'`
        serverStatusData=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -X GET "https://api.mcstatus.io/v2/status/java/$serverIp")
        infoString3="version=$(jq -r '.version.name_raw' <<<"$serverStatusData") | host=$(jq -r '.host' <<<"$serverStatusData") | port=$(jq -r '.port' <<<"$serverStatusData")"
        conditionalInfo="online=$(jq -r '.online' <<<"$serverStatusData") | online-players=$(jq -r '.players.online' <<<"$serverStatusData") | max-players=$(jq -r '.players.max' <<<"$serverStatusData")"
        conditionalMotd="\e[47;30mmotd\e[0m\e[44m=\e[42;30m$(jq -r '.motd.clean' <<<"$serverStatusData")\e[0m\e[44m"
        # sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys gc ENTER
        # conditionalInfo=($(sudo tmux -S /var/$tmuxName-tmux/$tmuxName capture-pane -p -S - -E -10 -t $tmuxName.0 -J))
    fi
    if $isServerRunning; then
        statusColor=$systemColor
    else
        statusColor="\e[041m"
    fi

    if [[ "$colour" == "true" ]]; then
        centerAndPrintString "\e[044m$statusColor > Current server status < \e[44;30m"
        centerAndPrintStringShort="\e[044m$infoString"
        centerAndPrintString "\e[044m| $infoString |"
        if [ ${infoString2:+1} ]; then
            centerAndPrintStringShort="\e[044m$infoString2"
            centerAndPrintString "\e[044m| $infoString2 |"
        fi
        if [ ${infoString3:+1} ]; then
            centerAndPrintStringShort="\e[044m$infoString3"
            centerAndPrintString "\e[044m| $infoString3 |"
        fi
        if [ ${conditionalInfo:+1} ]; then
            centerAndPrintStringShort="\e[044m$conditionalInfo"
            centerAndPrintString "\e[044m| $conditionalInfo |"
            if ! [ -z "$conditionalMotd" ]; then
                centerAndPrintStringShort="\e[044m$conditionalMotd"
                centerAndPrintString "\e[044m| $conditionalMotd |"
            fi
        fi
    else
        echo "$infoString|$conditionalInfo|$conditionalMotd"
    fi
    success=true
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