#!/bin/bash
run=false
defaultBackup=false
defaultTmuxName="server"
defaultMaintainerPath=/home/ubuntu
numberReg='^[0-9]+$'

for ARGUMENT in "$@"
do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)

    KEY_LENGTH=${#KEY}
    VALUE="${ARGUMENT:$KEY_LENGTH+1}"
    allArgs+=("$KEY"="$VALUE")

    export "$KEY"="$VALUE"
done

if ! [ ${tmuxName:+1} ]; then
    tmuxName=$defaultTmuxName
fi
if ! [ ${backup:+1} ]; then
    backup=$defaultBackup
fi
if ! [ ${maintainerPath:+1} ]; then
    maintainerPath=$defaultMaintainerPath
fi
maintainerModulesPath=$maintainerPath/maintainer-modules

# Functions
source $maintainerPath/maintainer-common.sh

function confirmation() {
    centerAndPrintString "\e[041mAre you sure about this? [y/n]"
    read runstring
    if [[ "${runstring,,}" == "y" ]]; then
        run=true
    elif [[ "${runstring,,}" == "n" ]]; then
        run=false
    else
        centerAndPrintString "\e[041mInvalid input, please type 'y' or 'n'"
        confirmation
    fi
    echo
}
function backup() {
    backedUp=1
    if compgen -G "${maintainerModulesPath}/maintainer-[0-9]*-server-backuper.sh" > /dev/null; then
        if /bin/bash ${maintainerModulesPath}/maintainer-[0-9]*-server-backuper.sh skipSuccessLog=true serverStop=true serverRestart=true "${allArgs[*]}"; then
            if [ ${isMaintainerRun:+1} ] && [[ "${isMaintainerRun}" == "true" ]]; then
                backedUp=0
            fi
        fi
    else
        centerAndPrintString "\e[41m> Cannot backup the server as the module \e[044m server-backuper \e[041m is missing!"
    fi
    return $backedUp
}
function restart() {
    isServerRunning=true
    pid=$(pgrep -u ubuntu java 2>/dev/null)
    if ! [[ $pid =~ $numberReg ]]; then
        pid=$(pgrep -u root java 2>/dev/null)
        if ! [[ $pid =~ $numberReg ]]; then
            isServerRunning=false
        fi
    fi

    if $isServerRunning; then
        if stop; then
            if start; then
                success=true
            fi
        else
            centerAndPrintString "\e[41m> Cannot stop the server as the module \e[044m server-stopper \e[041m is missing!"
        fi
    else
        if start; then
            success=true
        fi
    fi
}
function start() {
    started=1
    if compgen -G "${maintainerModulesPath}/maintainer-[0-9]*-server-starter.sh" > /dev/null; then
        if /bin/bash ${maintainerModulesPath}/maintainer-[0-9]*-server-starter.sh skipSuccessLog=true; then
            started=0
        fi
    else
        centerAndPrintString "\e[41m> Couldn't start the server as module\e[044m server-starter \e[041m is missing!"
    fi
    return $started
}
function stop() {
    stopped=1
    if compgen -G "${maintainerModulesPath}/maintainer-[0-9]*-server-stopper.sh" > /dev/null; then
        if /bin/bash ${maintainerModulesPath}/maintainer-[0-9]*-server-stopper.sh action=restarting skipSuccessLog=true; then
            stopped=0
        fi
    else
        centerAndPrintString "\e[41m> Cannot stop the server as the module \e[044m server-stopper \e[041m is missing!"
    fi
    return $stopped
}

if [ ${getArgs:+1} ]; then
    if [[ "$getArgs" == "true" ]]; then
        echo "tmuxName=$defaultTmuxName"
    else
        echo -e \\"e[041mBad value provided for parameter \\e[044mgetArgs\\e[041m!\\e[0m"
    fi
else
    # Code
    success=false
    confirmation
    if $run; then
        if $backup; then
            if backup; then
                success=true
            else
                restart
            fi
        else
            restart
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