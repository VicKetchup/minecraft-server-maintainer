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
if ! [ ${getArgs:+1} ]; then
    source $maintainerPath/maintainer-common.sh skipConfig=false
fi

function installed() {
    installed=1
    if [ -n "$(compgen -G "$path/$jarName.jar")" ]; then
        centerAndPrintString "\e[042;30mServer is already installed!"
        centerAndPrintString "\e[044mServer location: $path/$jarName.jar"
        installed=0
    fi
    return $installed
}

function download() {
    downloaded=1
    if wget "https://api.papermc.io/v2/projects/paper/versions/1.20.1/builds/116/downloads/paper-1.20.1-116.jar" -O "$defaultPath/$jarName.jar" > /dev/null; then
        downloaded=0
    fi
    return $downloaded
}

function start() {
    started=1
    if compgen -G "${maintainerModulesPath}/maintainer-[0-9]*-server-starter.sh"; then
        if /bin/bash ${maintainerModulesPath}/maintainer-[0-9]*-server-starter.sh skipSuccessLog=true; then
            started=0
        fi
    else
        centerAndPrintString "\e[41m> Couldn't start the server as module\e[044m server-starter \e[041m is missing!"
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
    if ! installed; then
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
# This file is part of Minecraft Server-Maintainer.
#
# Minecraft Server-Maintainer is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Minecraft Server-Maintainer is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Minecraft Server-Maintainer.  If not, see <https://www.gnu.org/licenses/>.