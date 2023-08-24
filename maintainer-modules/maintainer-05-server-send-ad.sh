#!/bin/bash
success=false
defaultTmuxName="server"
defaultFormat="&4"
defaultMaintainerPath=/home/ubuntu

for ARGUMENT in "$@"
do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)

    KEY_LENGTH=${#KEY}
    VALUE="${ARGUMENT:$KEY_LENGTH+1}"
    
    export "$KEY"="$VALUE"
done

if ! [ ${tmuxName:+1} ]; then
    tmuxName=$defaultTmuxName
fi
if ! [ ${format:+1} ]; then
    format=$defaultFormat
fi
if ! [ ${maintainerPath:+1} ]; then
    maintainerPath=$defaultMaintainerPath
fi

# Functions
source $maintainerPath/maintainer-common.sh

function runAdvert() {
    # Inform and disable chat
    sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "helpop Maintainer advert module executed by user ${username}" ENTER
    sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "upc RemoveGroupPermission default essentials.chat.local" ENTER

    # Print logo
    i=0
    sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "broadcast &6&lPlease click advert link to support us!" ENTER
    sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "broadcast ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄" ENTER
    while read -r line; do
        if [[ "$i" -lt "29" ]]; then
            i=$((i+1))
            if [[ -n "$line" ]]; then
                if ! [[ "${line}" =~ "[m(\ )*" ]]; then
                    visibleLine=${line}
                    # visibleLine="$(echo "$visibleLine" | awk '{gsub(/\x1b\[[0-9;]*m/, "", $0); print}')"
                    visibleLine="$(echo "$visibleLine" | awk '{gsub(/ /, "\\&f ", $0); print}')"
                    visibleLine="$(echo "$visibleLine" | awk '{gsub(/\x1b(\[|\[0)(3|4)1(m|;([0-9]{2}m))*/, "\\&4", $0); print}')" # Red
                    visibleLine="$(echo "$visibleLine" | awk '{gsub(/\x1b(\[|\[0)(3|4)2(m|;([0-9]{2}m))*/, "\\&2", $0); print}')" # Green
                    visibleLine="$(echo "$visibleLine" | awk '{gsub(/\x1b(\[|\[0)(3|4)3(m|;([0-9]{2}m))*/, "\\&e", $0); print}')" # Yellow
                    visibleLine="$(echo "$visibleLine" | awk '{gsub(/\x1b(\[|\[0)(3|4)4(m|;([0-9]{2}m))*/, "\\&9", $0); print}')" # Blue
                    visibleLine="$(echo "$visibleLine" | awk '{gsub(/\x1b(\[|\[0)(3|4)5(m|;([0-9]{2}m))*/, "\\&5", $0); print}')" # Purple
                    visibleLine="$(echo "$visibleLine" | awk '{gsub(/\x1b(\[|\[0)(3|4)6(m|;([0-9]{2}m))*/, "\\&3", $0); print}')" # Cyan
                    visibleLine="$(echo "$visibleLine" | awk '{gsub(/\x1b(\[|\[0)(3|4)7(m|;([0-9]{2}m))*/, "\\&7", $0); print}')" # White
                    visibleLine="$(echo "$visibleLine" | awk '{gsub(/\x1b(\[|\[0)(3|4)8(m|;([0-9]{2}m))*/, "\\&8", $0); print}')" # Gray
                    visibleLine="$(echo "$visibleLine" | awk '{gsub(/\x1b(\[|\[0|\[04)0(m|;([0-9]{2}m))*/, "\\&f", $0); print}')" # Reset
                    visibleLine="$(echo "$visibleLine" | awk '{gsub(/Co/, "\\&Co.", $0); print}')" # Preprate
                    visibleLine="$(echo "$visibleLine" | awk '{gsub(/\x1b\[[0-9;]*m/, "", $0); print}')" # Clean up
                    visibleLine="${visibleLine:19}"

                    if ! [[ "${visibleLine}" == "f" ]]; then
                        if [[ -n "$visibleLine" ]]; then
                            # sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "tellraw @a {"text":"${visibleLine}","clickEvent":{"action":"open_url","value":"https://discord.gg/SrCJffMVXp"}}" ENTER
                            sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "broadcast &a${visibleLine}" ENTER
                        fi
                    fi
                fi
            fi
        fi
    done <<< `printLogo 1 57`
    sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "broadcast ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀" ENTER
    sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "broadcast &eBrought to you by &6VicKetchup &eof &4Ketchup&7 & &cCo&e." ENTER
    windowWidth=$(tput cols)

    # Re-enable chat
    sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "upc AddGroupPermission default essentials.chat.local" ENTER

    centerAndPrintString "\e[042;30m> Advert Broadcasted :) <"
    success=true
}

if [ ${getArgs:+1} ]; then
    if [[ "$getArgs" == "true" ]]; then
        echo "format=${defaultFormat} message=\"Text here\" tmuxName=$defaultTmuxName"
    else
        echo -e \\"e[041mBad value provided for parameter \\e[044mgetArgs\\e[041m!\\e[0m"
    fi
else
    # Code
    runAdvert
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