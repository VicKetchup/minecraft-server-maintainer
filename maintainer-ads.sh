#!/bin/bash
# Set default variables here
success=false
defaultMaintainerPath=/home/ubuntu

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
if ! [ ${getArgs:+1} ]; then
    source $maintainerPath/maintainer-common.sh skipConfig=true
fi

# Advert functions
function selfPromo() {
    centerAndPrintString "\e[0m                 \e[47m▄\e[47m▒▒▒▒▒▒▒▀\e[0m\e[37m▄\e[47m█\e[47m▀\e[0m\e[37m▒▒▒▒▒▒▒▒▀\e[37m█▄▄\e[0m" $2
    centerAndPrintString "\e[0m                  \e[47m█▒\e[0m\e[37m▒       \e[47m█\e[0m\e[37m▒▒▒         \e[047m▀\e[47m██\e[37m▀\e[0m" $2
    centerAndPrintString "\e[0m                  \e[47m█\e[0m         \e[47m█▒\e[0m    \e[37m██▒▒▒▒▒▒█\e[0m" $2
    centerAndPrintString "\e[0m                  \e[47m█\e[0m     \e[33mX\e[0m     \e[37m█\e[0m\e[37m▄ \e[37m█\e[0m    \e[044m ☠ \e[37m█\e[0m" $2
    centerAndPrintString "\e[0m                    \e[040m\e[37m▀\e[37m▄      \e[37m▄      \e[037m██\e[0m   \e[044m  \e[037m█\e[0m" $2
    centerAndPrintString "\e[0m     \e[043m▄\e[0m                \e[37m▄\e[37m▀\e[37m▄▄       \e[37m▒▒\e[047m███\e[0m    \e[37m▄\e[047m█\e[0m▀\e[37m█\e[0m" $2
    centerAndPrintString "\e[0m           \e[041m▒\e[037m█\e[041m▒\e[0m             \e[47m█\e[0m\e[37m▀\e[37m▒▒▒▒▀\e[37m▄\e[37m▀\e[37m█\e[0m    \e[37m▒▒▒▀\e[37m████████\e[37m█\e[0m\e[37m▄\e[0m    #\e[0m" $2
    centerAndPrintString "\e[0m         \e[37m▄\e[037m█\e[041m▒\e[037m█\e[0m\e[37m▄\e[0m           \e[041m█\e[43m▒▒▒▒▒▒▒▒▒▒\e[47m█\e[0m    \e[37m▒▒▒▒▒\e[047m██▒▒\e[031m██\e[33m██\e[0m███\e[37m▒\e[0m" $2
    centerAndPrintString "\e[0m     \e[037m█\e[041m▒ ▒\e[037m█\e[0m         \e[041m█▀\e[041m            \e[047m█\e[0m    \e[37m▒▒▒▒▒██████\e[0m" $2
    centerAndPrintString "\e[0m     \e[037m█\e[041m▒  ▒\e[037m█\e[0m       \e[041m█▀\e[041m               \e[47m█\e[0m\e[37m▄\e[37m▄\e[37m▄\e[37m▄\e[37m▄\e[37m▄\e[37m▄\e[37m▄\e[037m█\e[0m \e[037m▒ \e[037m▒\e[0m \e[037m█\e[0m" $2
    centerAndPrintString "\e[0m    \e[037m█\e[041m▒  ▒\e[037m█\e[0m▀ \e[0m     \e[041m█ \e[30mKetchup&Co.\e[0m\e[041m \e[041m█     \e[041m▀\e[41m█\e[0m  \e[37m█\e[0m \e[37m█\e[0m      \e[37m█\e[0m" $2
    centerAndPrintString "\e[0m   \e[037m█\e[041m▒▒ ▒\e[037m█\e[0m      \e[041m█             █\e[0m \e[41m█      █\e[0m  \e[37m▀\e[37m█\e[0m      \e[37m█\e[0m" $2
    centerAndPrintString "\e[0m   \e[037m█\e[041m▒▒\e[0m \e[41m▒\e[037m█\e[0m      \e[041m█             █\e[0m  \e[041m█      █\e[0m   \e[037m█\e[0m    \e[37m█\e[0m" $2
    centerAndPrintString "\e[0m    \e[037m█\e[41m▒\e[0m  \e[037m▒█\e[0m    \e[41m█              █\e[040m   \e[041m█\e[43m▒▒▒▒▒▒\e[41m█\e[0m   \e[37m█\e[0m   \e[37m█\e[0m" $2
    centerAndPrintString "\e[0m      \e[037m█\e[0m    \e[037m█\e[0m   \e[041m█             █\e[0m     \e[040m█      \e[37m▀\e[040m█▄▀    \e[37m█\e[0m" $2
    centerAndPrintString "\e[0m      \e[037m█\e[0m    \e[037m█\e[0m   \e[041m█             █\e[0m      \e[047m█\e[0m             \e[37m█\e[0m" $2
    centerAndPrintString "\e[0m      \e[037m█\e[0m    \e[037m█\e[0m   \e[041m█             █\e[0m▄\e[44m▀▀▀▀▀▀▀▀\e[040m▄▄          ▀\e[0m▄\e[0m" $2
    centerAndPrintString "\e[0m    \e[037m█\e[0m    \e[037m█\e[0m   \e[041m█              █\e[44m           ▀\e[040m▄       \e[37m▄▀\e[0m" $2
    centerAndPrintString "\e[0m  \e[037m█\e[0m    \e[037m█\e[0m   \e[041m█              ▀█\e[44m    ▒▄▄▄▄▄▄▀▀▀▀▀▀▀\e[0m\e[37m█▄\e[0m" $2
    centerAndPrintString "\e[0m  \e[037m█\e[0m    \e[037m█\e[0m    \e[041m█\e[45m▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒\e[41m█\e[44m    ▀              \e[37m█\e[0m" $2
    centerAndPrintString "\e[0m  \e[037m█\e[0m    \e[037m▀\e[0m▄  ▄█\e[044m▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀       ▒            \e[37m█\e[0m" $2
    centerAndPrintString "\e[0m  \e[037m▀\e[0m▄    \e[037m▀▀▀\e[44m▒                   ▄▄\e[0m▀\e[44m█\e[44m▒         ▒\e[37m█\e[0m" $2
    centerAndPrintString "$footer"
    success=true
    sleep $1;
}

if [ ${getArgs:+1} ]; then
    if [[ "$getArgs" == "true" ]]; then
        echo "maintainerPath=$defaultMaintainerPath"
    else
        echo -e \\"e[041mBad value provided for parameter \\e[044mgetArgs\\e[041m!\\e[0m"
    fi
else
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