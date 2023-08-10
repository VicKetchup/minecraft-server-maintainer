#!/bin/bash
defaultTmuxName="server"
defaultMaintainerPath=/home/ubuntu
defaultPath=$defaultMaintainerPath/
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
    if [ -d "${defaultPath}/$jarName.jar" ]; then
        centerAndPrintString "\e[042mServer is already installed! Location:\e[0m"
        centerAndPrintString "\e[044m${defaultPath}/$jarName.jar\e[0m"
        false
    else
        true
    fi
}

function download() {
    if wget -O "https://api.papermc.io/v2/projects/paper/versions/1.20.1/builds/116/downloads/paper-1.20.1-116.jar" "$defaultPath/$jarName.jar" > /dev/null; then
        true
    else
        false
    fi
}

function start() {
    started=1
    if [ -d "${maintainerModulesPath}/maintainer-[0-9]*-server-starter.sh" ]; then
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