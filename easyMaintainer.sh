#!/bin/bash
export "isMaintainerRun"="true"
# Default arguments
defaultMaintainerPath=/home/ubuntu

# Get passed arguments
for ARGUMENT in "$@"
do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)

    KEY_LENGTH=${#KEY}
    VALUE="${ARGUMENT:$KEY_LENGTH+1}"

    argsToPass+=("$KEY"="$VALUE")

    export "$KEY"="$VALUE"
done
if ! [ ${maintainerPath:+1} ]; then
    maintainerPath=$defaultMaintainerPath
    export "maintainerPath"="$defaultMaintainerPath"
fi

if [ ${getArgs:+1} ]; then
    if [[ "$getArgs" == "true" ]]; then
        echo ""
    else
        echo -e \\"e[041mBad value provided for parameter \\e[044mgetArgs\\e[041m!\\e[0m"
    fi
else
    # Code
    source $maintainerPath/maintainer-common.sh
    
    cd $maintainerPath
    /bin/bash ${maintainerPath}/maintainer.sh easyMode=true isMaintainerRun=true ${argsToPass[*]}
fi