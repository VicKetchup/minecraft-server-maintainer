#!/bin/bash
success=false
defaultTmuxName=server
defaultServerFolder=server
defaultServerStop='false'
defaultServerRestart='true'
defaultMode=root # allowed values: local, root
defaultBackupPath="/backups"
path=`pwd`
defaultMaintainerPath=/home/ubuntu

if [[ "$path" == "\\" ]]; then
    path=""
fi

for ARGUMENT in "$@"
do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)

    KEY_LENGTH=${#KEY}
    VALUE="${ARGUMENT:$KEY_LENGTH+1}"

    export "$KEY"="$VALUE"
done

if ! [ ${serverStop:+1} ]; then
    serverStop=$defaultServerStop
fi
if ! [ ${serverRestart:+1} ]; then
    serverRestart=$defaultServerRestart
fi
if ! [ ${mode:+1} ]; then
    mode=$defaultMode
fi
if ! [ ${serverFolder:+1} ]; then
    serverFolder=$defaultServerFolder
fi
if ! [ ${maintainerPath:+1} ]; then
    maintainerPath=$defaultMaintainerPath
fi
maintainerModulesPath=$maintainerPath/maintainer-modules

# Functions
source $maintainerPath/maintainer-common.sh

function backup() {
    if [ ! -d $backupPath ]; then
        cd $path
        centerAndPrintString "\e[043;30m> Creating backups folder \e[0m\e[044m ${backupPath} \e[043;30m...\e[0m"
        if [[ "$backupPath" == "$defaultBackupPath" ]]; then
            sudo mkdir backups
        else
            mkdir backups
        fi
    fi
    centerAndPrintString "\e[043;30m> Backing up server to \e[0m\e[044m $backupFile \e[043;30m...\e[0m"

    if [[ "$backupPath" == "$defaultBackupPath" ]]; then
        sudo zip -r $backupFile $maintainerPath/$serverFolder
    else
        zip -r $backupFile $maintainerPath/$serverFolder
    fi
    centerAndPrintString "\e[042;30m> Backup has been completed! File created: \e[0m\e[044m $backupFile \e[0m\n"
    success=true
}

if [ ${getArgs:+1} ]; then
    if [[ "$getArgs" == "true" ]]; then
        echo "mode=$defaultMode tmuxName=$defaultTmuxName serverFolder=$defaultServerFolder serverStop=$defaultServerStop serverRestart=$defaultServerRestart maintainerPath=$defaultMaintainerPath"
    else
        echo -e \\"e[041mBad value provided for parameter \\e[044mgetArgs\\e[041m!\\e[0m"
    fi
else
    # Code
    if ! [ ${tmuxName:+1} ]; then
        tmuxName=$defaultTmuxName
    fi

    pid=$(pgrep -u ubuntu java 2>/dev/null)
    numberReg='^[0-9]+$'
    isServerRunning=true
    if ! [[ $pid =~ $numberReg ]]; then
        pid=$(pgrep -u root java 2>/dev/null)
        if ! [[ $pid =~ $numberReg ]]; then
            isServerRunning=false
        fi
    fi

    if [[ "$mode" == "local" ]]; then
        backupPath="${path}/backups"
    elif [[ "$mode" == "root" ]]; then
        backupPath=$defaultBackupPath
    fi
    timestamp=$(date "+%Y-%m-%d-%H-%M-%S")
    backupFile="${backupPath}/backup-$timestamp.zip"
    if $isServerRunning; then
        if [[ "$serverStop" == "true" ]]; then
            if compgen -G "${maintainerModulesPath}/maintainer-[0-9]*-server-stopper.sh" > /dev/null; then
                /bin/bash ${maintainerModulesPath}/maintainer-[0-9]*-server-stopper.sh skipSuccessLog=true isMaintainerRun=true
                backup
                if [[ "${serverRestart}" == "true" ]]; then
                    if compgen -G "${maintainerModulesPath}/maintainer-[0-9]*-server-starter.sh" > /dev/null; then
                        /bin/bash ${maintainerModulesPath}/maintainer-[0-9]*-server-starter.sh skipSuccessLog=true
                    else
                        centerAndPrintString "\e[41m> Couldn't start the server as module\e[044m server-starter \e[041m is missing!\e[0m"
                    fi
                fi
            else
                centerAndPrintString "\e[41m> Cannot stop the server as the module \e[044m server-stopper \e[041m is missing!\e[0m"
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
