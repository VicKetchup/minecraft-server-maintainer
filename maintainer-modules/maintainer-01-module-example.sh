#!/bin/bash
# Set default variables here
success=true
example="true"
example2="false"
defaultMaintainerPath=/home/ubuntu
requirePermission=true

for ARGUMENT in "$@"
do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)

    KEY_LENGTH=${#KEY}
    VALUE="${ARGUMENT:$KEY_LENGTH+1}"
    allArgs+=("$KEY"="$VALUE")

    export "$KEY"="$VALUE"
done

if ! [ ${maintainerPath:+1} ]; then
    maintainerPath=$defaultMaintainerPath
fi

# Functions
source $maintainerPath/maintainer-common.sh

function exampleFunction() {
    centerAndPrintString "\e[042;30m> This is a module demo :) <\e[0m"
    centerAndPrintString "\e[044mPassed Args were: ${allArgs[*]}\e[0m"
    success=true
}

if [ ${getArgs:+1} ]; then
    if [[ "$getArgs" == "true" ]]; then
        echo "example=true example2=false requirePermission=true"
    else
        echo -e \\"e[041mBad value provided for parameter \\e[044mgetArgs\\e[041m!\\e[0m"
    fi
else
    # Code
    source $maintainerPath/maintainer-common.sh
    if [ true ]; then
        success=false
    fi

    exampleFunction

    # Log results
    if [ ${isMaintainerRun:+1} ] && [[ "${isMaintainerRun}" == "true" ]]; then
        if [[ "${success}" == "true" ]]; then
            echo "Example Message: Please implement 'success' variable" >> $maintainerPath/maintainer-log.txt
            if ! [ ${skipSuccessLog:+1} ] || [[ "${skipSuccessLog}" == "false" ]]; then
                echo "~" >> $maintainerPath/maintainer-log.txt
            fi
        fi
    fi
    skipSuccessLog=false
fi