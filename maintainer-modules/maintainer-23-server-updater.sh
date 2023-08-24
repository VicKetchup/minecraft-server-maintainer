#!/bin/bash
# THIS IS STILL WORK IN PROGRESS, MAY NOT WORK AS EXPECTED YET AND COULD BE COMPLETELY CHANGED IN THE FUTURE
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
if ! [ ${getArgs:+1} ]; then
    source $maintainerPath/maintainer-common.sh skipConfig=false
fi

function installDependecies() {
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
    if ! [[ -d "$maintainerModulesPath/pluGET-1.7.3" ]]; then
        centerAndPrintString "\e[42;30mpluGET is not installed. Attempting to install..."
        cd $maintainerModulesPath
        # Download pluGET
        curl -Lo pluGET.zip "https://github.com/Neocky/pluGET/archive/refs/tags/v1.7.3.zip"
        # Extract pluGET
        unzip "pluGET.zip"
        # Install dependencies
        pip3 install -r pluGET-1.7.3/requirements.txt
        # Set config
        generate_pluGET_config
    fi
    
}
generate_pluGET_config() {
    cd "$maintainerModulesPath/pluGET-1.7.3"
    cat > pluGET_config.yaml <<EOL
#
# Configuration File for pluGET
# https://www.github.com/Neocky/pluGET 
#

# What should be used for the connection (local, sftp, ftp)
Connection: local

Local:
  PathToPluginFolder: $maintainerPath/$serverFolder/plugins
  # If a different folder should be used to store the updated plugins change to (True/False) and the path below
  SeperateDownloadPath: false
  PathToSeperateDownloadPath: $maintainerPath/$serverFolder/plugins/updated

Remote:
  Server: 0.0.0.0
  Username: user
  Password: password
  # If a different Port for SFTP/FTP will be used
  SFTP_Port: 22
  FTP_Port: 21
  # If a different folder should be used to store the updated plugins change to (True/False) and the path below
  SeperateDownloadPath: false
  PathToSeperateDownloadPath: /plugins/updated
  # Change the path below if the plugin folder path is different on the SFTP/FTP server (Change only if you know what you are doing)
  PluginFolderOnServer: /plugins
EOL
}
function collectPluginInfo() {
    installDependecies
    centerAndPrintString "\e[042;30mLooking for plugin updates..."
    cd $maintainerModulesPath
    # Run pluGET to list installed plugins and their versions
    while read -r line; do
        if [[ "$line" == *"No."* ]] || [[ "$line" == *"True"* ]] || [[ "$line" == *"False"* ]]; then
            noUpdate=false
            if [[ "$line" == *"True"* ]] || [[ "$line" == *"False"* ]]; then
                lineToPrint=$(echo $line | sed -r 's/^[0-9]+ //')
                if [[ "$line" == *"False"* ]]; then
                    noUpdate=true
                fi
            else
                # Replace spaces in header titles with underscores
                line=${line//Installed V./Installed_V.}
                line=${line//Latest V./Latest_V.}
                line=${line//Update available/Update_available}
                lineToPrint=${line#*No\.}
            fi
            IFS=' ' read -ra values <<< "$lineToPrint"
            # Remove the Update_available column and its values
            columnIndex=3 # Set this variable to the index of the Update_available column (0-based)
            values=("${values[@]:0:$columnIndex}" "${values[@]:$((columnIndex+1))}")
            # Calculate column widths based on window width and number of columns
            numColumns=${#values[@]}
            columnWidth=$((windowWidth / numColumns))
            # Print values with calculated column width
            needEcho=true
            pluginIdRegex='^\[[0-9]+\]-spigot$'
            if $noUpdate; then
                for value in "${values[@]}"; do
                    if [[ $value =~ $pluginIdRegex ]]; then
                        baseLink="https://www.spigotmc.org/resources"
                        pluginId=${value#*[}
                        pluginId=${pluginId%]*}
                        plugnLink="$baseLink/$pluginId"
                        allValuesString=${values[@]}
                        pluginName=$(echo "$allValuesString" | awk '{print $1}')
                        if [[ "$pluginName" == "ServerSigns" ]]; then
                            pluginVersion=$(echo "$allValuesString" | awk '{print "v" $2}')
                        else
                            pluginVersion=$(echo "$allValuesString" | awk '{print $2}')
                        fi
                        pluginOnlineLatestV=$(echo "$allValuesString" | awk '{print $3}')
                        pluginDetails=$(echo "$allValuesString" | awk '{print $4}')
                        printColor="\e[43;30m"
                        version="($pluginVersion)"
                        versionMissMatch=false
                        if [[ "$pluginVersion" != "$pluginOnlineLatestV" ]]; then
                            printColor="\e[41;30m"
                            version="version mismatch ($pluginVersion vs $pluginOnlineLatestV)"
                            versionMissMatch=true
                        fi
                        noUpdateWithIdPlugins+=("$printColor$pluginName $version $pluginDetails")
                        if $versionMissMatch; then
                            noUpdateWithIdPlugins+=("$printColor$plugnLink/updates")
                        fi
                    elif [[ "$value" =~ "()-N/A" ]]; then
                        allValuesString=${values[@]}
                        pluginAndVersion=${allValuesString%%N/A*}
                        noUpdateNoIdPlugins+=("\e[47;30m$pluginAndVersion")
                    fi
                done
                needEcho=false
            else
                for value in "${values[@]}"; do
                    printf "\e[44;37m%-${columnWidth}s" "$value"
                    if [[ $value =~ $pluginIdRegex ]]; then
                        baseLink="https://www.spigotmc.org/resources"
                        pluginId=${value#*[}
                        pluginId=${pluginId%]*}
                        plugnLink="$baseLink/$pluginId"
                        centerAndPrintString "\e[46;30m$plugnLink/updates"
                        needEcho=false
                    fi
                done
            fi
            if $needEcho; then
                echo
            fi
        elif
            [[ "$line" == *"Plugins with available updates"* ]]; then
            pluginsWithAvailableUpdatesLine="\e[46;30m$line"
        else
            centerAndPrintString "\e[41;37m$line"
        fi
    done <<< `cd pluGET-1.7.3 && python3 pluget.py check all | grep -E 'pluGET|True|False|Plugins with available updates|No\.'`
    if [[ ${#noUpdateWithIdPlugins[@]} -gt 0 ]]; then
        centerAndPrintString "\e[43;30mPlugins with no updates:"
        for plugin in "${noUpdateWithIdPlugins[@]}"; do
            centerAndPrintString "$plugin"
        done
    fi
    if [[ ${#noUpdateNoIdPlugins[@]} -gt 0 ]]; then
        centerAndPrintString "\e[47;30mUnknown/Premium plugins:"
        for plugin in "${noUpdateNoIdPlugins[@]}"; do
            if ! [[ "$plugin" =~ "EssentialsX"* ]]; then
                centerAndPrintString "$plugin"
            fi
        done
    fi
    if [[ ${#pluginsWithAvailableUpdatesLine[@]} -gt 0 ]]; then
        centerAndPrintString "$pluginsWithAvailableUpdatesLine"
    fi
}
function collectServerInfo() {
    cd $maintainerModulesPath
    centerAndPrintString "\e[042;30mCollecting server info..."
    # Run pluGET to list installed plugins and their versions
    while read -r line; do
        if [[ "$line" =~ "pluGET"* ]]; then
            centerAndPrintString "\e[41;37m$line"
        else
            IFS=' ' read -ra values <<< "$line"
            # Calculate column widths based on window width and number of columns
            numColumns=${#values[@]}
            columnWidth=$((windowWidth / numColumns))
            # Print values with calculated column width
            for value in "${values[@]}"; do
                printf "\e[44m%-${columnWidth}s" "$value"
            done
            echo
        fi
    done <<< `cd pluGET-1.7.3 && python3 pluget.py check serverjar`
    centerAndPrintString "\e[46;30mhttps://papermc.io/downloads/all"
}
function updatePlugins() {
    cd $maintainerModulesPath
    (cd pluGET-1.7.3 && python3 pluget.py update all)
}
function updateServer() {
    cd $maintainerModulesPath
    (cd pluGET-1.7.3 && python3 pluget.py update serverjar)
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
    collectServerInfo
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