#!/bin/bash
run=false
defaultForceRun="false"
defaultTmuxName="prison"
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
source $maintainerPath/maintainer-common.sh

function confirmation() {
    if [ ${extramessage:+1} ]; then
        centerAndPrintString "\e[041m$extramessage\e[0m"
    fi
    centerAndPrintString "\e[041mAre you sure about this? [y/n]\e[0m"
    read runstring
    if [[ "${runstring,,}" == "y" ]]; then
        run=true
    elif [[ "${runstring,,}" == "n" ]]; then
        run=false
    else
        centerAndPrintString "\e[041mInvalid input, please type 'y' or 'n'\e[0m"
        confirmation
    fi
    echo
}

function reboot() {
    if [[ $pid =~ $numberReg ]]; then
        if compgen -G "${maintainerModulesPath}/maintainer-[0-9]*-server-backuper.sh" > /dev/null; then
            /bin/bash ${maintainerModulesPath}/maintainer-[0-9]*-server-backuper.sh serverStop=true serverRestart=false "${allArgs[*]}"
            if [ ${isMaintainerRun:+1} ] && [[ "${isMaintainerRun}" == "true" ]]; then
                cd $maintainerPath
                head -n -1 maintainer-log.txt > temp-maintainer-log.txt; mv temp-maintainer-log.txt maintainer-log.txt
                cd $maintainerModulesPath
            fi
        fi
    fi
    centerAndPrintString "\e[043;30m Exiting module and Rebooting... \e[040;37m"
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
    if [[ "${forceRun}" == "false" ]]; then
        confirmation
        if $run; then
            sudo tmux -S /var/$tmuxName-tmux/$tmuxName has-session -t $tmuxName 2>/dev/null
            if [ $? == 0 ]; then
                extramessage="Tmux session $tmuxName is still running!"
                confirmation
                unset extramessage
                if $run; then
                    pid=$(pgrep -u ubuntu java 2>/dev/null)
                    if ! [[ $pid =~ $numberReg ]]; then
                        pid=$(pgrep -u root java 2>/dev/null)
                    fi
                    if [[ $pid =~ $numberReg ]]; then
                        extramessage="Java session is still running on \e[044m $pid "
                        confirmation
                        unset extramessage
                        if $run; then
                            reboot
                        fi
                    fi
                fi
            else
                reboot
            fi
        fi
    else
        reboot
    fi
fi