#!/bin/bash
success=false
forceStart="false"
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
maintainerModulesPath=$maintainerPath/maintainer-modules

# Functions
source $maintainerPath/maintainer-common.sh

function enterConsole() {
    centerAndPrintString "\e[46;30mThere are multiple ways to exit nested tmux session (the server server console will be open as one):"
    centerAndPrintString "\e[044mHold \e[043;30m Ctrl \e[044;37m while double-tapping \e[043;30m B \e[044;37m, then (let go of Ctrl)"
    centerAndPrintString "\e[044;37m    hit \e[043;30m D \e[044;37m :)"
    centerAndPrintString "\e[044;37mOR"
    centerAndPrintString "\e[044;37m    type \e[043;30m :detach \e[044;37m and hit \e[043;30m ENTER \e[044;37m"
    centerAndPrintString "\e[41mAre you ready to enter the console? [y/n]:"
    read enterstring
    if [[ "${enterstring,,}" == "y" ]]; then
        sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "helpop user $username has entered console with maintainer script" ENTER
        sudo tmux -S /var/$tmuxName-tmux/$tmuxName attach -t $tmuxName
    elif [[ "${enterstring,,}" != "n" ]]; then
        centerAndPrintString "\e[041mInvalid input, please type 'y' or 'n'"
        enterConsole
    fi
    echo
}

if [ ${getArgs:+1} ]; then
    if [[ "$getArgs" == "true" ]]; then
        echo "tmuxName=$defaultTmuxName forceStart=false"
    else
        echo -e \\"e[041mBad value provided for parameter \\e[044mgetArgs\\e[041m!\\e[0m"
    fi
else
    # Code
    if [[ "$forceStart" == "true" ]]; then
        if compgen -G "${maintainerModulesPath}/maintainer-[0-9]*-server-starter.sh" > /dev/null; then
            /bin/bash ${maintainerModulesPath}/maintainer-[0-9]*-server-starter.sh
        else
            centerAndPrintString "\e[41m> Couldn't start the server as module\e[044mserver-starter\e[041m is missing!"
        fi
    fi
    if ! [ ${tmuxName:+1} ]; then
        tmuxName=$defaultTmuxName
    fi
    enterConsole
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