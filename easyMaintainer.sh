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