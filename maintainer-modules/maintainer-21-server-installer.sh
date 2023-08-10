#!/bin/bash
defaultTmuxName="server"
defaultMaintainerPath=/home/ubuntu
defaultPath=$defaultMaintainerPath/server
defaultJarName=spigot
numberReg='^[0-9]+$'

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
if ! [ ${jarName:+1} ]; then
    jarName=$defaultJarName
fi
if ! [ ${path:+1} ]; then
    path=$defaultPath
fi
if ! [ ${maintainerPath:+1} ]; then
    maintainerPath=$defaultMaintainerPath
fi
maintainerModulesPath=$maintainerPath/maintainer-modules

# Functions
source $maintainerPath/maintainer-common.sh

function notInstalled() {
    if compgen -G "$path/$jarName.jar"; then
        return 0
    else
        centerAndPrintString "\e[042;30mServer is already installed! Location:\e[0m"
        centerAndPrintString "\e[044m$path/$jarName\e[0m"
        return 1
    fi
}

function download() {
    if wget -O "https://api.papermc.io/v2/projects/paper/versions/1.20.1/builds/116/downloads/paper-1.20.1-116.jar" "$defaultPath/$jarName.jar" > /dev/null; then
        return 1
    else
        return 0
    fi
}

function start() {
    started=1
    if compgen -G "${maintainerModulesPath}/maintainer-[0-9]*-server-starter.sh"; then
        if /bin/bash ${maintainerModulesPath}/maintainer-[0-9]*-server-starter.sh skipSuccessLog=true; then
            started=0
        fi
    else
        centerAndPrintString "\e[41m> Couldn't start the server as module\e[044m server-starter \e[041m is missing!\e[0m"
    fi
    return $started
}

if [ ${getArgs:+1} ]; then
    if [[ "$getArgs" == "true" ]]; then
        echo "tmuxName=$defaultTmuxName maintainerPath=$defaultMaintainerPath jarName=$defaultJarName"
    else
        echo -e \\"e[041mBad value provided for parameter \\e[044mgetArgs\\e[041m!\\e[0m"
    fi
else
    # Code
    success=false
    if notInstalled; then
        if download; then
            if start; then
                success=true
            fi
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