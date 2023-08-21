#!/bin/bash
# Default arguments
timestamp=$(date "+%Y-%m-%d-%H-%M-%S")
defaultMode=notify # allowed values: notify, update
defaulUpdateLevel=plugin # allowed values: plugin, server (server operates for both server jar and/or plugins)
defaultForceUpdate=false
defaultServerFolder=server
defaultBackupPath="/backups/pre-updates"
defaultBackupFileName="update-backup-$timestamp"
defaultBackupType=root # allowed values: local, root
maintainerMainUser=ubuntu
defaultMaintainerPath=/home/ubuntu

# Get passed arguments
for ARGUMENT in "$@"
do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)

    KEY_LENGTH=${#KEY}
    VALUE="${ARGUMENT:$KEY_LENGTH+1}"

    export "$KEY"="$VALUE"
done

if ! [ ${mode:+1} ]; then
    mode=$defaultMode
fi
if ! [ ${updateLevel:+1} ]; then
    updateLevel=$defaulUpdateLevel
fi
if ! [ ${forceUpdate:+1} ]; then
    forceUpdate="${defaultForceUpdate}"
fi
if ! [ ${serverFolder:+1} ]; then
    serverFolder=$defaultServerFolder
fi
if ! [ ${backupPath:+1} ]; then
    backupPath=$defaultBackupPath
fi
if ! [ ${backupFileName:+1} ]; then
    backupFileName=$defaultBackupFileName
fi
if ! [ ${backupType:+1} ]; then
    backupType=$defaultBackupType
fi
if ! [ ${maintainerMainUser:+1} ]; then
    maintainerMainUser=$maintainerMainUser
fi
if ! [ ${maintainerPath:+1} ]; then
    maintainerPath=$defaultMaintainerPath
fi
maintainerModulesPath=$maintainerPath/maintainer-modules

# Functions
source $maintainerPath/maintainer-common.sh

function collectPluginInfo() {
    # Check for missing dependencies and attempt to install them
    dependencies=(curl zip python3-pip python3)
    for dep in "${dependencies[@]}"; do
        command="$dep"
        if [[ "$dep" == "python3-pip" ]]; then
            command="pip3"
        fi
        if ! command -v "$command" &> /dev/null; then
            centerAndPrintString "\e[42;30m$dep is not installed. Attempting to install..."
            sudo apt-get update
            sudo apt-get install -y "$dep"
        fi
    done

    # Check if pluGET is already installed
    if [ ! -d "pluGET-1.7.3" ]; then
        # Download pluGET
        curl -Lo pluGET.zip "https://github.com/Neocky/pluGET/archive/refs/tags/v1.7.3.zip"
        # Extract pluGET
        unzip "pluGET.zip"
        # Install dependencies
        pip3 install -r pluGET-1.7.3/requirements.txt
    fi

    # Run pluGET to list installed plugins and their versions
    pluginInfo=$(cd pluGET-1.7.3 && python3 pluget.py list --path $maintainerPath/$serverFolder/plugins)
}
function collectServerInfo() {
    serverInfo="server info"
}
function getPluginLevelUpdates() {
    pluginLevelUpdates="plugin updates"
}
function getServerLevelUpdates() {
    serverLevelUpdates="server updates"
}
function updatePlugins() {
    centerAndPrintString "\e[043;30mUpdating plugins..."
}
function updateServer() {
    centerAndPrintString "\e[043;30mUpdating server..."
}

if [ ${getArgs:+1} ]; then
    if [[ "$getArgs" == "true" ]]; then
        echo "mode=$defaultMode updateLevel=$defaulUpdateLevel forceUpdate=$defaultForceUpdate serverFolder=$defaultServerFolder backupPath=$defaultBackupPath backupFileName=$defaultBackupFileName backupType=$defaultBackupType maintainerMainUser=$maintainerMainUser maintainerPath=$defaultMaintainerPath"
    else
        echo -e \\"e[041mBad value provided for parameter \\e[044mgetArgs\\e[041m!\\e[0m"
    fi
else
    # Code
    success=false
    pid=$(pgrep -u ubuntu java 2>/dev/null)
    numberReg='^[0-9]+$'
    isServerRunning=true
    if ! [[ $pid =~ $numberReg ]]; then
        isServerRunning=false
    fi

    collectPluginInfo
    centerAndPrintString "\e[044mCurrently installed plugins:"
    echo $pluginInfo
    collectServerInfo
    centerAndPrintString "\e[044mCurrent server:"
    echo $serverInfo
    getPluginLevelUpdates
    echo $pluginLevelUpdates
    getServerLevelUpdates
    echo $serverLevelUpdates
    if [[ "$mode" == "update" ]]; then
        if $isServerRunning; then
            if [[ "$forceUpdate" == "true" ]]; then
                if compgen -G "${maintainerModulesPath}maintainer-server-stopper.sh" > /dev/null; then
                    /bin/bash ${maintainerModulesPath}maintainer-server-stopper.sh action=restarting skipSuccessLog=true isMaintainerRun=true
                    updateServer
                    updatePlugins
                    centerAndPrintString "\e[042;30mAll updates have completed!"
                    success=true
                    if compgen -G "${maintainerModulesPath}maintainer-server-starter.sh" > /dev/null; then
                        /bin/bash ${maintainerModulesPath}maintainer-server-starter.sh skipSuccessLog=true isMaintainerRun=true
                    else
                        centerAndPrintString "\e[41mCouldn't start the server as module\e[044mserver-starter\e[041m is missing!"
                    fi
                else
                    centerAndPrintString "\e[41mCannot force update as the server is running and module\e[044mserver-stopper\e[041m is missing!"
                fi
            else
                centerAndPrintString "\e[41mCannot update as the server is running!"
            fi
        else
            if [[ "$updateLevel" == "server" ]]; then
                updateServer
                updatePlugins
                success=true
            elif [[ "$updateLevel" == "plugin" ]]; then
                updatePlugins
                success=true
            else
                centerAndPrintString "\e[41m> Invalid \e[044mupdateLevel\e[041m specified, should be either \e[044mserver\e[041m or \e[044mplugin"
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

