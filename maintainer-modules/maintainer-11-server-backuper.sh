#!/bin/bash
# Default arguments
timestamp=$(date "+%Y-%m-%d-%H-%M-%S")
defaultMode=root # allowed values: local, root
defaultTmuxName=server
defaultServerFolder=server
defaultServerStop='false'
defaultServerRestart='true'
defaultRelativeBackupPath="/backups"
defaultBackupFileName="backup-$timestamp"
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
if ! [ ${tmuxName:+1} ]; then
    tmuxName=$defaultTmuxName
fi
if ! [ ${serverFolder:+1} ]; then
    serverFolder=$defaultServerFolder
fi
if ! [ ${serverStop:+1} ]; then
    serverStop=$defaultServerStop
fi
if ! [ ${serverRestart:+1} ]; then
    serverRestart=$defaultServerRestart
fi
if ! [ ${relativeBackupPath:+1} ]; then
    relativeBackupPath=$defaultRelativeBackupPath
fi
if ! [ ${backupFileName:+1} ]; then
    backupFileName=$defaultBackupFileName
fi
if ! [ ${maintainerPath:+1} ]; then
    maintainerPath=$defaultMaintainerPath
fi
maintainerModulesPath=$maintainerPath/maintainer-modules

# Functions
source $maintainerPath/maintainer-common.sh

function backup() {
    if [ ! -d $backupPath ]; then
        centerAndPrintString "\e[043;30mCreating backups folder \e[0m\e[044m ${backupPath} \e[043;30m..."
        if [[ "$mode" == "root" ]]; then
            sudo mkdir $backupPath
        else
            mkdir $backupPath
        fi
    fi
    centerAndPrintString "\e[043;30mBacking up server to \e[0m\e[044m $backupFile \e[043;30m..."

    if [[ "$mode" == "root" ]]; then
        (cd $maintainerPath/$serverFolder && sudo zip -r $backupFile *)
    else
        (cd $maintainerPath/$serverFolder && zip -r $backupFile *)
    fi
    if compgen -G "${backupFile}" > /dev/null; then
        centerAndPrintString "\e[042;30mBackup has been completed! File created: \e[0m\e[044m $backupFile \e[042;30m..."
        success=true
    fi
}

if [ ${getArgs:+1} ]; then
    if [[ "$getArgs" == "true" ]]; then
        echo "mode=$defaultMode tmuxName=$defaultTmuxName serverFolder=$defaultServerFolder serverStop=$defaultServerStop serverRestart=$defaultServerRestart relativeBackupPath=$defaultRelativeBackupPath maintainerPath=$defaultMaintainerPath"
    else
        echo -e \\"e[041mBad value provided for parameter \\e[044mgetArgs\\e[041m!\\e[0m"
    fi
else
    # Code
    success=false
    if [[ "$mode" == "local" ]]; then
        backupPath="$maintainerPath/$relativeBackupPath"
    elif [[ "$mode" == "root" ]]; then
        backupPath=$relativeBackupPath
    fi
    backupFile="${backupPath}/$backupFileName.zip"

    pid=$(pgrep -u ubuntu java 2>/dev/null)
    numberReg='^[0-9]+$'
    isServerRunning=true
    if ! [[ $pid =~ $numberReg ]]; then
        pid=$(pgrep -u root java 2>/dev/null)
        if ! [[ $pid =~ $numberReg ]]; then
            isServerRunning=false
        fi
    fi
    
    if $isServerRunning; then
        if [[ "$serverStop" == "true" ]]; then
            if compgen -G "${maintainerModulesPath}/maintainer-[0-9]*-server-stopper.sh" > /dev/null; then
                /bin/bash ${maintainerModulesPath}/maintainer-[0-9]*-server-stopper.sh action=restarting skipSuccessLog=true isMaintainerRun=true
                backup
                if [[ "${serverRestart}" == "true" ]]; then
                    if compgen -G "${maintainerModulesPath}/maintainer-[0-9]*-server-starter.sh" > /dev/null; then
                        /bin/bash ${maintainerModulesPath}/maintainer-[0-9]*-server-starter.sh skipSuccessLog=true isMaintainerRun=true
                    else
                        centerAndPrintString "\e[41m> Couldn't start the server as module \e[044m server-starter \e[041m is missing!"
                    fi
                fi
            else
                centerAndPrintString "\e[41m> Cannot stop the server as the module \e[044m server-stopper \e[041m is missing!"
            fi
        else
            sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 save-off ENTER
            backup
            sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 save-on ENTER
        fi
    else
        backup
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
