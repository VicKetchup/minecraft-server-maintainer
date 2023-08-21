#!/bin/bash
success=false
run=true
defaultLtsOnly=true
defaultMaintainerPath=/home/ubuntu

for ARGUMENT in "$@"
do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)

    KEY_LENGTH=${#KEY}
    VALUE="${ARGUMENT:$KEY_LENGTH+1}"

    export "$KEY"="$VALUE"
done

if ! [ ${ltsOnly:+1} ]; then
    ltsOnly=$defaultLtsOnly
fi
if ! [ ${maintainerPath:+1} ]; then
    maintainerPath=$defaultMaintainerPath
fi

# Functions
source $maintainerPath/maintainer-common.sh

function reboot() {
    centerAndPrintString "\e[042> Reboot is required, do you want to reboot now? [y/n]?"
    read rebootNow
    if [[ "${rebootNow,,}" == "n" ]]; then
        run=false
    elif [[ "${rebootNow,,}" != "y" ]]; then
        centerAndPrintString "\e[041mInvalid input, please type 'y' or 'n'"
        reboot
    else
        if [ ${isMaintainerRun:+1} ] && [[ "${isMaintainerRun}" == "true" ]]; then
            centerAndPrintString "\e[043;30m> Exiting module and Rebooting..."
            echo "~sudo reboot" >> $maintainerPath/maintainer-log.txt
        else
            sudo reboot
        fi
    fi
}

function updateJava() {
    centerAndPrintString "\e[043;30m> Updating Java to \e[0m\e[044mJava-$versionToUpdateTo"
    for e in "${packageNames[@]}" ; do
        if [[ $e == *"-$versionToUpdateTo-"* ]] ; then
            packageName=$e
            break
        fi
    done
    sudo nala install $packageName
    success=true
}

if [ ${getArgs:+1} ]; then
    if [[ "$getArgs" == "true" ]]; then
        echo "ltsOnly=true latest=false"
    else
        echo -e \\"e[041mBad value provided for parameter \\e[044mgetArgs\\e[041m!\\e[0m"
    fi
else
    # Code
    java --version 2>/dev/null
    if [ $? != 0 ]; then
        centerAndPrintString "\e[043;30m> No Java installation found, installing Java..."
        sudo apt install default-jre
        sudo apt install JDK default-jdk
    fi
    nala --version 2>/dev/null
    if [ $? != 0 ]; then
        sudo apt install nala
        if [ ${isMaintainerRun:+1} ] && [[ "${isMaintainerRun}" == "true" ]]; then
            echo -e \\"e[043;30m> Exiting module and Rebooting...\\e[040;37m"
            echo "~sudo reboot" >> $maintainerPath/maintainer-log.txt
        else
            sudo reboot
        fi
    fi
    if $run; then
        currentJavaVersion=`java -version 2>&1 | head -1 | cut -d'"' -f2 | sed '/^1\./s///' | cut -d'.' -f1`

        while IFS= read -r line; do
            if [[ $line == *"jdk-headless"* ]]; then
                packageNames+=(`cut -c 0-23 <<< $line`)
                version=`cut -c 9-10 <<< $line`
                versionInfo=`curl -i -H "Accept: application/json" -H "Content-Type: application/json" -X GET https://endoflife.date/api/java/$version.json`
                if [[ "$versionInfo" == *"\"lts\":true"* ]]; then
                    if [[ "$currentJavaVersion" != "$version" ]]; then
                        availableVersions+=("$version")
                    fi
                    latestVersion=$version
                else
                    nonLtsVersions+=("$version")
                fi
            fi
        done < <(nala list "openjdk-(?:[1-9][0-9]{2,}|[2-9][0-9]|1[${currentJavaVersion:1:1}-9])-jdk")

        centerAndPrintString "\e[044mCurrent version: $currentJavaVersion"
        centerAndPrintString "\e[044mAvailable updates: ${availableVersions[@]}"
        centerAndPrintString "\e[044mLatest LTS version: $latestVersion"
        centerAndPrintString "\e[046;30mNon-LTS versions (can be installed with ltsOnly=false arg): ${nonLtsVersions[@]}"

        if [ ${latest:+1} ] && [[ "$latest" == "true" ]] && [[ "$currentJavaVersion" != "$latestVersion" ]]; then
            versionToUpdateTo=$latestVersion
            updateJava
        else
            select opt in "${availableVersions[@]}"
            do
                case $opt in
                    *)
                    if [[ " ${availableVersions[*]} " == *" $opt "* ]]; then
                        versionToUpdateTo=$opt
                        break
                    else
                        centerAndPrintString "\e[041m> Invalid option, please select one of the available choices!"
                    fi
                    ;;
                esac
            done
            if [[ " ${availableVersions[*]/$currentJavaVersion} " == *[a-Z]* ]]; then
                updateJava
            else
                centerAndPrintString "\e[042;30m> No updates :)"
                centerAndPrintString "\e[042;30m> Exiting..."
                success=true
            fi
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
# This file is part of Minecraft Server-Maintainer.
#
# Minecraft Server-Maintainer is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Minecraft Server-Maintainer is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Minecraft Server-Maintainer.  If not, see <https://www.gnu.org/licenses/>.