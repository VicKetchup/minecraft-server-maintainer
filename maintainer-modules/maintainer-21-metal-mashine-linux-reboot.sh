#!/bin/bash
run=false
defaultForceRun="false"
defaultTmuxName="server"
numberReg='^[0-9]+$'
defaultMaintainerPath=/home/ubuntu

for ARGUMENT in "$@"
do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)

    KEY_LENGTH=${#KEY}
    VALUE="${ARGUMENT:$KEY_LENGTH+1}"
    allArgs+=("$KEY"="$VALUE")

    export "$KEY"="$VALUE"
done

if ! [ ${forceRun:+1} ]; then
    forceRun=$defaultForceRun
fi
if ! [ ${tmuxName:+1} ]; then
    tmuxName=$defaultTmuxName
fi
if ! [ ${maintainerPath:+1} ]; then
    maintainerPath=$defaultMaintainerPath
fi
maintainerModulesPath=$maintainerPath/maintainer-modules

# Functions
if ! [ ${getArgs:+1} ]; then
    source $maintainerPath/maintainer-common.sh skipConfig=false
fi

function confirmation() {
    if [ ${extramessage:+1} ]; then
        centerAndPrintString "\e[041m$extramessage"
    fi
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

function reboot() {
    if [[ $pid =~ $numberReg ]]; then
        if compgen -G "${maintainerModulesPath}/maintainer-[0-9]*-server-backuper.sh" > /dev/null; then
            /bin/bash ${maintainerModulesPath}/maintainer-[0-9]*-server-backuper.sh serverStop=true serverRestart=false skipSuccessLog=true"${allArgs[*]}"
            if [ ${isMaintainerRun:+1} ] && [[ "${isMaintainerRun}" == "true" ]]; then
                cd $maintainerPath
                head -n -1 maintainer-log.txt > temp-maintainer-log.txt; mv temp-maintainer-log.txt maintainer-log.txt
                cd $maintainerModulesPath
            fi
        fi
    fi
    centerAndPrintString "\e[043;30m Exiting module and Rebooting... "
    if [ ${isMaintainerRun:+1} ] && [[ "${isMaintainerRun}" == "true" ]]; then
        echo "~sudo reboot" >> $maintainerPath/maintainer-log.txt
    else
        sudo reboot
    fi
}

if [ ${getArgs:+1} ]; then
    if [[ "$getArgs" == "true" ]]; then
        echo "forceRun=$defaultForceRun"
    else
        echo -e \\"e[041mBad value provided for parameter \\e[044mgetArgs\\e[041m!\\e[0m"
    fi
else
    # Code
    unset extramessage
    pid=$(pgrep -u ubuntu java 2>/dev/null)
    if ! [[ $pid =~ $numberReg ]]; then
        pid=$(pgrep -u root java 2>/dev/null)
    fi
    if [[ "${forceRun}" == "false" ]]; then
        confirmation
        if $run; then
            sudo tmux -S /var/$tmuxName-tmux/$tmuxName has-session -t $tmuxName 2>/dev/null
            if [ $? == 0 ]; then
                extramessage="Tmux session $tmuxName is still running!"
                confirmation
                unset extramessage
                if $run; then
                    if [[ $pid =~ $numberReg ]]; then
                        extramessage="Java session is still running on \e[044m $pid \e[041m"
                        confirmation
                        unset extramessage
                        if $run; then
                            reboot
                        else
                            centerAndPrintString "\e[42;30mReboot cancelled as Java session is still running on \e[044m $pid \e[42;30m"
                        fi
                    else
                        reboot
                    fi
                else
                    centerAndPrintString "\e[42;30mReboot cancelled as Tmux session \e[44;37m $tmuxName \e[42;30m is still running"
                fi
            else
                reboot
            fi
        else
            centerAndPrintString "\e[42;30mReboot cancelled by user"
        fi
    else
        reboot
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