#!/bin/bash
success=false
ramDefault=8
ramToUse=0 # is overwritten later
numberReg='^[0-9]+$'
maintainerExecution=false
defaultMaintainerPath=/home/ubuntu
defaultPath=$defaultMaintainerPath/server
defaultJarName=spigot
defaultTmuxName=server

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

# Functions
source $maintainerPath/maintainer-common.sh

function startJar() {
    tmux -S /var/$tmuxName-tmux/$tmuxName new -s $tmuxName -d
    tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "cd $path" Enter
    tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "java -Xms${ramToUse}G -Xmx${ramToUse}G -XX:+UseG1GC -jar ${jarName}.jar nogui" Enter
    success=true
}

if [ ${getArgs:+1} ]; then
    if [[ "$getArgs" == "true" ]]; then
        echo "ram=$ramDefault path=$defaultPath jarName=$defaultJarName tmuxName=$defaultTmuxName"
    else
        echo -e \\"e[041mBad value provided for parameter \\e[044mgetArgs\\e[041m!\\e[0m"
    fi
else
    # Code
    if [ ${isMaintainerRun:+1} ] && [ $isMaintainerRun=true ]; then
        maintainerExecution=true
    fi

    if [ ${ram:+1} ]; then
        if ! [[ $ram =~ $numberReg ]]; then
            ramToUse=$ramDefault
            if ! $maintainerExecution; then
                centerAndPrintString "\e[041mProvided RAM parameter is not a number, using default value: \e[044m$ramToUse\e[0m\n"
            fi
        fi
    else
        ramToUse=$ramDefault
    fi

    if ! [ ${path:+1} ]; then
        path=$defaultPath
    fi

    if ! [ ${jarName:+1} ]; then
        jarName=$defaultJarName
    fi

    if ! [ ${tmuxName:+1} ]; then
        tmuxName=$defaultTmuxName
    fi

    sudo chmod g+ws /var/$tmuxName-tmux/$tmuxName
    tmux -S /var/$tmuxName-tmux/$tmuxName has-session -t $tmuxName 2>/dev/null
    if [ $? != 0 ]; then
        if compgen -G "${path}/${jarName}.jar" > /dev/null; then
            centerAndPrintString "\e[042;30mStarting \e[0m\e[044m ${jarName}.jar \e[042;30m in \e[0m\e[044m $path \e[042;30m with \e[0m\e[044m ${ramToUse}GB \e[042;30m of RAM in tmux session \e[0m\e[044m ${tmuxName} \e[042;30m...\e[0m"
            if ! $maintainerExecution; then
                centerAndPrintString "\e[044m> You can change these parameters by executing the script with jarName, path and ram parameters\e[0m\n"
            fi
            echo
            startJar
        fi
    else
        centerAndPrintString "\e[041m Cannot start server as a tmux session with name \e[0m\e[044m $tmuxName \e[0m\e[041m alraedy exists...\e[0m\n"
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

