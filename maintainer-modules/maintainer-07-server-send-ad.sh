#!/bin/bash
success=false
defaultTmuxName="server"
defaultMaintainerPath=/home/ubuntu
defaulltAdToRun="selfPromo"

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
if ! [ ${maintainerPath:+1} ]; then
    maintainerPath=$defaultMaintainerPath
fi
if ! [ ${adToRun:+1} ]; then
    adToRun=$defaulltAdToRun
fi

# Functions
if ! [ ${getArgs:+1} ]; then
    source $maintainerPath/maintainer-common.sh skipConfig=false
fi
function runAdvert() {
    # Inform and disable chat
    sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "helpop Maintainer advert module executed by user ${username}" ENTER
    sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "upc RemoveGroupPermission default essentials.chat.local" ENTER

    # Print logo
    i=0
    sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "broadcast &6&lPlease click advert link to support us!" ENTER
    sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "broadcast ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄" ENTER
    while read -r line; do
        # if [[ "$firstLineChars" == "" ]]; then
        #     echo Removing first 5 chars
        #     line="${line:5}"
        # fi
        if [[ "$i" -lt "29" ]]; then # Limit advert size
            i=$((i+1))
            if [[ -n "$line" && "$i" -ne "1" ]]; then
                # Adjust output for minecraft
                visibleLine=${line}

                visibleLine="$(echo "$visibleLine" | awk '{gsub(/Co/, "\\&Co.", $0); print}')" # Preprate

                visibleLine="$(echo "$visibleLine" | awk '{gsub(/▀/, "⎺", $0); print}')" # Image Border_top
                visibleLine="$(echo "$visibleLine" | awk '{gsub(/▄/, "⎽", $0); print}')" # Image Border_bottom
                visibleLine="$(echo "$visibleLine" | awk '{gsub(/█/, "▍", $0); print}')" # Image Border_full
                visibleLine="$(echo "$visibleLine" | awk '{gsub(/ /, "⃙", $0); print}')" # Blank spaces
                visibleLine="$(echo "$visibleLine" | awk '{gsub(/ /, "\\u00a78‑\\u00a7r", $0); print}')" # Spaces
                visibleLine="$(echo "$visibleLine" | awk '{gsub(/Ketchup&&Co../, "⋆⋆⋆⋆⋆⋆⋆⋆⋆⋆⋆⋆⋆⋆", $0); print}')" # TODO: Fix this
                visibleLine="$(echo "$visibleLine" | awk '{gsub(/▒/, "⇶", $0); print}')" # Opaque spaces
                visibleLine="$(echo "$visibleLine" | awk '{gsub(/▓/, "⬱", $0); print}')" # Opaque spaces2

                # Replace colours with tellraw syntax for minecraft
                visibleLine="$(echo "$visibleLine" | awk '{gsub(/\x1b(\[|\[0)(3|4)1(m|;([0-9]{2}m))*/, "\\u00a74", $0); print}')" # Red
                visibleLine="$(echo "$visibleLine" | awk '{gsub(/\x1b(\[|\[0)(3|4)2(m|;([0-9]{2}m))*/, "\\u00a72", $0); print}')" # Green
                visibleLine="$(echo "$visibleLine" | awk '{gsub(/\x1b(\[|\[0)(3|4)3(m|;([0-9]{2}m))*/, "\\u00a7e", $0); print}')" # Yellow
                visibleLine="$(echo "$visibleLine" | awk '{gsub(/\x1b(\[|\[0)(3|4)4(m|;([0-9]{2}m))*/, "\\u00a79", $0); print}')" # Blue
                visibleLine="$(echo "$visibleLine" | awk '{gsub(/\x1b(\[|\[0)(3|4)5(m|;([0-9]{2}m))*/, "\\u00a75", $0); print}')" # Purple
                visibleLine="$(echo "$visibleLine" | awk '{gsub(/\x1b(\[|\[0)(3|4)6(m|;([0-9]{2}m))*/, "\\u00a73", $0); print}')" # Cyan
                visibleLine="$(echo "$visibleLine" | awk '{gsub(/\x1b(\[|\[0)(3|4)7(m|;([0-9]{2}m))*/, "\\u00a77", $0); print}')" # White
                visibleLine="$(echo "$visibleLine" | awk '{gsub(/\x1b(\[|\[0)(3|4)8(m|;([0-9]{2}m))*/, "\\u00a78", $0); print}')" # Gray
                visibleLine="$(echo "$visibleLine" | awk '{gsub(/\x1b(\[|\[)(0|30|40|030|040)(m|;([0-9]{2}m))*/, "\\u00a7r", $0); print}')" # Reset

                # Clean up in case of leftover escape codes
                visibleLine="$(echo "$visibleLine" | awk '{gsub(/\x1bM[ ]*/, "", $0); print}')" # Image Border_top
                visibleLine="$(echo "$visibleLine" | awk '{gsub(/\x1b\[[0-9;]*m/, "", $0); print}')" # Left over escape codes

                # Broadcast advert line
                sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "tellraw @a {\"text\":\"${visibleLine}\",\"hoverEvent\":{\"action\":\"show_text\",\"value\":\"https://discord.gg/SrCJffMVXp\"},\"clickEvent\":{\"action\":\"open_url\",\"value\":\"https://discord.gg/SrCJffMVXp\"}}" ENTER
            fi
        fi
    done <<< `$1 1 58`
    sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "broadcast ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀" ENTER
    sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "broadcast &eBrought to you by &6VicKetchup &eof &4Ketchup&7 & &cCo&e." ENTER
    windowWidth=$(tput cols)

    # Re-enable chat
    sudo tmux -S /var/$tmuxName-tmux/$tmuxName send-keys -t $tmuxName:0.0 "upc AddGroupPermission default essentials.chat.local" ENTER

    centerAndPrintString "\e[042;30m Advert Broadcasted \$\$\$"
    success=true
}

if [ ${getArgs:+1} ]; then
    if [[ "$getArgs" == "true" ]]; then
        echo "tmuxName=$defaultTmuxName maintainerPath=$defaultMaintainerPath"
    else
        echo -e \\"e[041mBad value provided for parameter \\e[044mgetArgs\\e[041m!\\e[0m"
    fi
else
    # Code
    if [ -f $maintainerPath/maintainer-ads.sh ]; then
        source $maintainerPath/maintainer-ads.sh
        centerAndPrintString "\e[042;30m Broadcasting Advert... "
        runAdvert $adToRun
    else
        centerAndPrintString "\e[041;30m Please ensure to create maintainer-ads.sh in your maintainerPath!"
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