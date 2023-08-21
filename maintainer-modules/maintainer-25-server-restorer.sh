#!/bin/bash
# Default arguments
timestamp=$(date "+%Y-%m-%d-%H-%M-%S")
defaulRestoreZip=latest # allowed values: latest or backup zip path
defaultForceRestore=false
defaultServerFolder=server
defaultBackupPath="/backups"
defaultRestoresPath="/backups/pre-restores"
defaultBackupFileName="restore-backup-$timestamp"
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

if ! [ ${restoreZip:+1} ]; then
    restoreZip=$defaulRestoreZip
fi
if ! [ ${forceRestore:+1} ]; then
    forceRestore=$defaultForceRestore
fi
if ! [ ${serverFolder:+1} ]; then
    serverFolder=$defaultServerFolder
fi
if ! [ ${backupPath:+1} ]; then
    backupPath=$defaultBackupPath
fi
if ! [ ${restoresPath:+1} ]; then
    restoresPath=$defaultRestoresPath
fi
if ! [ ${backupFileName:+1} ]; then
    backupFileName=$defaultBackupFileName
fi
if ! [ ${backupType:+1} ]; then
    backupType=$defaultBackupType
fi
if ! [ ${maintainerMainUser:+1} ]; then
    maintainerMainUser=$defaultMaintainerMainUser
fi
if ! [ ${maintainerPath:+1} ]; then
    maintainerPath=$defaultMaintainerPath
fi
maintainerModulesPath=$maintainerPath/maintainer-modules

# Functions
source $maintainerPath/maintainer-common.sh

function backupCurrentFiles() {
    backedUp=1
    if compgen -G "${maintainerModulesPath}/maintainer-[0-9]*-server-backuper.sh" > /dev/null; then
        /bin/bash ${maintainerModulesPath}/maintainer-[0-9]*-server-backuper.sh serverFolder=$serverFolder relativeBackupPath=$restoresPath backupFileName=$backupFileName mode=$backupType maintainerPath=$maintainerPath skipSuccessLog=true isMaintainerRun=true
        backedUp=0
    else
        centerAndPrintString "\e[41mCannot backup current files as module \e[044m server-backuper \e[041m is missing!"
        if confirmRestoreWithoutBackup; then
            backedUp=0
        fi
    fi
    return $backedUp
}

function confirmRestoreWithoutBackup() {
    confirmed=1
    centerAndPrintString "\e[41mAre you sure you want to continue? [y/n]"
    read confirmstring
    if [[ "${confirmstring,,}" == "y" ]]; then
        centerAndPrintString "\e[042;30mContinuing without backup..."
        confirmed=0
    elif [[ "${confirmstring,,}" != "n" ]]; then
        centerAndPrintString "\e[041mInvalid input, please type 'y' or 'n'"
        confirmRestoreWithoutBackup
    else
        centerAndPrintString "\e[041mAborting restore..."
    fi
    return $confirmed
}

function restore() {
    centerAndPrintString "\e[043;30m> Restoring server... <"
    # Look for backup file
    if [[ "$restoreZip" == "latest" ]]; then
        restoreZipLocation=$backupPath
        if [[ "$backupType" == "local" ]]; then
            restoreZipLocation=${maintainerPath}${backupPath}
        fi
        restoreZip=$(ls $restoreZipLocation/*.zip | tail -1)
    fi
    if [ -f $restoreZip ]; then
        centerAndPrintString "\e[042;30mUsing backup file \e[0m\e[044m $restoreZip \e[042;30m..."
        if [[ "$backupType" == "root" ]]; then
            echo $restoreZip
            echo $maintainerPath/$serverFolder
            sudo unzip -o "$restoreZip" -d "$maintainerPath/$serverFolder"
            sudo chown -R $maintainerMainUser "$maintainerPath/$serverFolder"
        else
            unzip -o "$restoreZip" -d "$maintainerPath/$serverFolder"
        fi
        centerAndPrintString "\e[042;30m> Restore completed <"
        success=true
    else
        centerAndPrintString "\e[041mCouldn't find backup file \e[0m\e[044m $restoreZip \e[041m!"
    fi
}

if [ ${getArgs:+1} ]; then
    if [[ "$getArgs" == "true" ]]; then
        echo "restoreZip=$defaulRestoreZip forceRestore=$defaultForceRestore serverFolder=$defaultServerFolder backupPath=$defaultBackupPath restoresPath=$defaulRestoresPath backupFileName=$defaultBackupFileName backupType=$defaultBackupType maintainerMainUser=$defaultMaintainerMainUser maintainerPath=$defaultMaintainerPath"
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

    if $isServerRunning; then
        if [[ "$forceRestore" == "true" ]]; then
            if compgen -G "${maintainerModulesPath}/maintainer-[0-9]*-server-stopper.sh" > /dev/null; then
                /bin/bash ${maintainerModulesPath}/maintainer-[0-9]*-server-stopper.sh action=restarting skipSuccessLog=true isMaintainerRun=true
                if backupCurrentFiles; then
                    restore
                fi
                if compgen -G "${maintainerModulesPath}/maintainer-[0-9]*-server-starter.sh" > /dev/null; then
                    /bin/bash ${maintainerModulesPath}/maintainer-[0-9]*-server-starter.sh skipSuccessLog=true isMaintainerRun=true
                else
                    centerAndPrintString "\e[41mCouldn't start the server as module \e[044m server-starter \e[041m is missing!"
                fi
            else
                centerAndPrintString "\e[41mCannot force restore as the server is running and module \e[044m server-stopper \e[041m is missing!"
            fi
        else
            centerAndPrintString "\e[41mCannot restore as the server is running!"
        fi
    else
        if backupCurrentFiles; then
            restore
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