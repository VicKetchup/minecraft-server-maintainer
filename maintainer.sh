#!/bin/bash
resize >/dev/null

# Default arguments
demo=true
logSize=50
clearForFrames=true
run=true
defaultUsername=$USER
timestamp=$(date "+%Y-%m-%d-%H-%M-%S")
defaultIsMaintainerRun="false"
realExit=true
anotherUserRunning=false
defaultNewExecution="true"
endScriptCommand=false
updateTmuxOwnership=false
defaultMaintainerPath=/home/ubuntu
maintainerMainUser=ubuntu

# Get passed arguments
for ARGUMENT in "$@"
do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)

    KEY_LENGTH=${#KEY}
    VALUE="${ARGUMENT:$KEY_LENGTH+1}"
    if [[ "${VALUE}" =~ " " ]] && [[ "${VALUE}" != "\""*"\"" ]]; then
        VALUE="\"$VALUE\""
    fi
    if [[ "$KEY" == "module" ]]; then
        passedModule=$VALUE
    elif [[ "$KEY" != "newExecution" ]] && [[ "$KEY" != "exitOnEnd" ]]; then
        argsToPass+=("$KEY"="$VALUE")
    fi
    allArgs+=("$KEY"="$VALUE")

    export "$KEY"="$VALUE"
done

if ! [ ${maintainerPath:+1} ]; then
    maintainerPath=$defaultMaintainerPath
fi
maintainerModulesPath=$maintainerPath/maintainer-modules
if ! [ ${isMaintainerRun:+1} ]; then
    isMaintainerRun=$defaultIsMaintainerRun
fi
if ! [ ${newExecution:+1} ]; then
    newExecution=$defaultNewExecution
fi

# Functions
function runOtherModules() {
    unset passedModule
    echo Do you need to run other modules? [y/n]:
    read runstring
    if [[ "${runstring,,}" == "n" ]]; then
        run=false
        realExit=true
        printFrame1 0.2
    elif [[ "${runstring,,}" != "y" ]]; then
        centerAndPrintString "\e[041mInvalid input, please type 'y' or 'n'"
        runOtherModules
    fi
}

function login() {
    if [ ${shas:+1} ] && [[ "${shas[*]}" == *"$connectionsha"* ]]; then
        shasAmount=${#shas[*]}
        for (( i=0; i<${shasAmount}; i++ ));
        do
            if [[ "${shas[$i]}" == *"$connectionsha"* ]]; then
                username="${usernames[$i]}"
            fi
        done
    else
        if $getUser; then
            PS3="Select username:"

            if [ -n $selectedusername ]; then
                unset shaToCheckAgainstArray
                unset shaToCheckAgainst
                select selectedusername in ${usernames[*]}
                do
                    case $selectedusername in
                        "Free-type")
                            freeTypeUsername
                            break
                        ;;
                        *) 
                            usernameIndex=$(($REPLY - 1))
                            shaToCheckAgainstString="${shas[$usernameIndex]}"
                            if [[ "${shaToCheckAgainstString}" == *"_"* ]]; then
                                IFS='_' read -r -a shaToCheckAgainstArray <<< "$shaToCheckAgainstString"
                            else
                                shaToCheckAgainstArray+=($shaToCheckAgainstString)
                            fi
                            if [[ "${shaToCheckAgainstArray[0]}" == "NULL" ]]; then
                                echo -e \\"e[041m> This username is reserved but not yet setup. Please select another username.\\e[0m\\n"
                                login
                            else
                                shaIndex=0
                                for shaToCheckAgainst in "${shaToCheckAgainstArray[*]}"
                                do
                                    shaIndex+=1
                                    if [[ "$shaToCheckAgainst" == "$connectionsha" ]]; then
                                        username=$selectedusername
                                        getUser=false
                                        break;
                                    else
                                        if [[ "${shaIndex}" == "${#sha[*]}" ]]; then
                                            echo -e \\"e[041m> Sha didn't match! Please select another username.\\e[0m\\n"
                                            login
                                        fi
                                    fi
                                done
                            fi
                            break
                        ;;
                    esac
                done
            else
                unset selectedusername
                login
            fi
        else
            username=$defaultUsername
        fi
    fi
}

function freeTypeUsername {
    echo -e \\"e[042;30m> Please enter your username or hit ENTER to use \\e[043m $defaultUsername \\e[0m"
                
    read givenName
    if [[ "$givenName" != "" ]]; then
        if [[ "${givenName}" == *"${usernames[*]}"* ]]; then
            echo -e \\"e[041m> This username is reserved for SSH login! Please select another username.\\e[0m\\n"
            freeTypeUsername
        else
            username=$givenName
        fi
    else
        username=$defaultUsername
    fi
}

function checkAttachedStatus {
    unset currentTmux
    if [ "$TERM_PROGRAM" = tmux ]; then
        while IFS= read -r line; do
            if [[ "${line}" == "maintainer" ]]; then
                currentTmux="${line}"
            fi
        done < <(tmux -S /var/maintainer-tmux/maintainer display-message -p '#S' 2>/dev/null)
    fi
    killedHangingSession=false
    isDetached=false
    reEnter=false
    isDetachedString=`tmux -S /var/maintainer-tmux/maintainer ls -F "#{?session_attached,attached,detached}" 2>/dev/null`
    if [[ $isDetachedString == *"tached" ]]; then
        currentUser=`echo \`tmux -S /var/maintainer-tmux/maintainer capture-pane -pt maintainer\` | grep -o -P '(?<=Welcome )[A-z]+(?= to)|(?<=user )[A-z]+(?= \|)$'`
    fi
    if [[ "${isDetachedString}" == "detached" ]] && ! [ ${currentTmux:+1} ]; then
        if [[  ${username:+1} ]] && [[ "${username}" != "${currentUser}" ]]; then
            echo Maintainer was left hanging, closing previous session...
            tmux -S /var/maintainer-tmux/maintainer kill-session -t maintainer
            killedHangingSession=true
            isDetached=true
        else
            reEnter=true
        fi
    elif [[ "${isDetachedString}" == "attached" ]]; then
        if [[  ${username:+1} ]] && [[ "${username}" == "${currentUser}" ]]; then
            reEnter=true
        fi
    else
        isDetached=true
    fi
}

function updateArgsToPassForNewExecution {
    argsToPass=('newExecution=false' "${argsToPass[@]}")
    if [[ "${argsToPass[*]}" != *"isMaintainerRun"* ]]; then
        argsToPass+=("isMaintainerRun=true")
    fi
    if [[ "${argsToPass[*]}" != *"username"* ]]; then
        argsToPass+=("username=${username}")
    fi
    if [ ${passedModule:+1} ]; then
        argsToPass+=("module=$passedModule")
    fi
}

function updateOwnerships {
    logOwner=`stat -c "%U" ${maintainerPath}/maintainer-log.txt`
    if [[ "${maintainerMainUser}" != "${logOwner}" ]]; then
        sudo chown $maintainerMainUser "${maintainerPath}/maintainer-log.txt"
    fi
    if $updateTmuxOwnership; then
        sudo chmod g+ws /var/maintainer-tmux/maintainer
    fi
}

function runModule {
    echo "$timestamp: $username has started '$module' module with arguments: $arguments" >> $maintainerPath/maintainer-log.txt
    updateOwnerships
    actualFileName=`ls $maintainerModulesPath/maintainer-[0-9]*-${module}.sh`
    if $demo; then
        centerAndPrintString "\e[043m Demo mode enabled, running module-example instead of $module"
        actualFileName=`ls $maintainerModulesPath/maintainer-[0-9]*-module-example.sh`
    fi
    eval $actualFileName $arguments
    
    unset moduleRunSuccessPossibleString
    successWithCommandString='^~[A-z ]*$'
    moduleRunSuccessPossibleString=$(tail -n 1 $maintainerPath/maintainer-log.txt)
    if [[ $moduleRunSuccessPossibleString =~ $successWithCommandString ]]; then
        if [[ "${moduleRunSuccessPossibleString}" != "~" ]]; then
            endScriptCommandString="${moduleRunSuccessPossibleString:1}"
            endScriptCommand=true
            run=false
        fi
        head -n -1 $maintainerPath/maintainer-log.txt > $maintainerPath/temp-maintainer-log.txt; mv $maintainerPath/temp-maintainer-log.txt ${maintainerPath}/maintainer-log.txt
        moduleRunSuccess="true"
    else
        moduleRunSuccess="false"
    fi
    timestamp=$(date "+%Y-%m-%d-%H-%M-%S")
    echo "$timestamp: Was module run successful: ${moduleRunSuccess}" >> $maintainerPath/maintainer-log.txt

    if ([ ${exitOnEnd:+1} ] && [[ "${exitOnEnd}" == "true" ]]); then
        if [[ "${moduleRunSuccess}" == "true" ]]; then
            echo -e \\"e[042;30m> Module run was successful!\\e[0;37m"
        else
            echo -e \\"e[041m> Module run was NOT successful!"
        fi
        echo -e \\"e[042;30m> Exiting...\\e[0;37m"
        run=false
    fi
}

function cleanUpLogs() {
    fileLines=`wc -l ${maintainerPath}/maintainer-log.txt | awk '{print $1}'`
    logSizeWithLines=`echo "$logSize + 3" | bc`
    if [[ "$fileLines" -gt "$logSize" ]]; then
        centerAndPrintString "\e[47m30mCleaning up maintainer-log.txt..."
        touch ${maintainerPath}/temp-maintainer-log.txt
        head -n 3 ${maintainerPath}/maintainer-log.txt >> ${maintainerPath}/temp-maintainer-log.txt
        echo "<<<--- TRUNCATED LOGS --->>>" >> $maintainerPath/temp-maintainer-log.txt
        tail -n -$logSize ${maintainerPath}/maintainer-log.txt >> ${maintainerPath}/temp-maintainer-log.txt
        mv ${maintainerPath}/temp-maintainer-log.txt ${maintainerPath}/maintainer-log.txt
    fi
}

trap 'echo; centerAndPrintString "\e[41m ⛔ Please exit the script properly ⛔ "' 2 15 20

if [ ${getArgs:+1} ]; then # If getArgs is passed, print out default arguments
    if [[ "$getArgs" == "true" ]]; then
        echo "username=$defaultUsername maintainerPath=$defaultMaintainerPath statusTmuxName=prison easyMode=false module=module-example modulearg=true modulearg2=false"
    else
        echo -e \\"e[041mBad value provided for parameter \\e[044mgetArgs\\e[041m!\\e[0m"
    fi
else
    # Code
    source $maintainerPath/maintainer-common.sh
    # Ensure we are in correct directory
    cd $maintainerPath

    # Prepare sessionId for logging and session management
    if ! [ ${sessionId:+1} ]; then
        sessionId=`uuidgen`
        allArgs+=("sessionId=${sessionId}")
        argsToPass+=("sessionId=${sessionId}")
    fi

    # Username/Login Handler
    if ! [ ${username:+1} ]; then
        if [ ${passedModule:+1} ]; then # If module is passed, don't ask user for username
            getUser=false
        else
            getUser=true
        fi
        unset usernames
        if compgen -G "${maintainerPath}/maintainer-usernames.txt" > /dev/null; then
            read -r usernamesfirstline<"${maintainerPath}/maintainer-usernames.txt"
            usernames=($usernamesfirstline)
            usernames+=("Free-type")
        fi
        unset connectionsha
        currentsshconnection=(`echo $SSH_CONNECTION`)
        if [[ "$currentsshconnection" != "" ]]; then
            connectioninfo=`sudo grep -F " from ${currentsshconnection[0]} port ${currentsshconnection[1]} " /var/log/auth.log | grep ssh`
            connectionsha=${connectioninfo#*SHA256:}
            shas=(`sed -n '2p;' ${maintainerPath}/maintainer-usernames.txt`)
        fi
        if [ ${connectionsha:+1} ]; then
            login
        else
            echo -e \\"e[041m> Issue getting current connection, please restart your client or Free-Type your username\\e[0m\\n"
            freeTypeUsername
        fi
    fi

    moduleRunSuccess="none ran"
    endScriptCommandString="not set"
    updateOwnerships
    if [ ! -f "${maintainerPath}/maintainer-log.txt" ]; then
        echo "Welcome to Maintainer log!" >> $maintainerPath/maintainer-log.txt
        echo "Here you will find all data on execution of Maintainer script :)" >> $maintainerPath/maintainer-log.txt
    fi
    if [[ "${newExecution}" == "true" ]]; then
        lastLogString=$(tail -n 1 ${maintainerPath}/maintainer-log.txt)
        if ! [ -z "$lastLogString" ]; then
            echo >> $maintainerPath/maintainer-log.txt
        fi
        echo ">> $sessionId" >> $maintainerPath/maintainer-log.txt
        echo "$timestamp: ### Started new maintainer execution ###" >> $maintainerPath/maintainer-log.txt
        echo "Script started by user: $username" >> $maintainerPath/maintainer-log.txt
        echo "Script was started with following Args: ${allArgs[*]}" >> $maintainerPath/maintainer-log.txt
        realExit=false
    fi

    # Session managment
    if [ ${exitOnEnd:+1} ] && [[ "${exitOnEnd}" == "true" ]] && [[ "${newExecution}" == "true" ]]; then
        if ! $killedHangingSession; then
            echo "$timestamp: exitOnEnd was set to true, checking for other sessions" >> $maintainerPath/maintainer-log.txt
        fi
        otherSessionsRunning=true
        printBlankLine=false
        while $otherSessionsRunning;
        do
            checkAttachedStatus
            if $isDetached; then
                if $printBlankLine; then
                    echo >> $maintainerPath/maintainer-log.txt
                fi
                otherSessionsRunning=false
            else
                printBlankLine=true

                unset scriptJustStartedPossibleString
                scriptJustStarted="Script was started with following Args"*
                scriptJustStartedPossibleString=$(tail -n 1 ${maintainerPath}/maintainer-log.txt)
                if [ -z "$scriptJustStartedPossibleString" ]; then
                    head -n -1 ${maintainerPath}/maintainer-log.txt > ${maintainerPath}/temp-maintainer-log.txt; mv ${maintainerPath}/temp-maintainer-log.txt ${maintainerPath}/maintainer-log.txt
                elif [[ $scriptJustStartedPossibleString != $scriptJustStarted ]]; then
                    echo >> $maintainerPath/maintainer-log.txt
                fi

                timestamp=$(date "+%Y-%m-%d-%H-%M-%S")
                echo "Another session is running, waiting 60 seconds to try again..."
                echo "$timestamp: Another session is running, waiting 60 seconds to try again for session: $sessionId" >> $maintainerPath/maintainer-log.txt
                echo >> $maintainerPath/maintainer-log.txt
                updateOwnerships
                sleep 60
            fi
        done
    else
        checkAttachedStatus
    fi
    updateOwnerships
    if [[ "${newExecution}" == "true" ]]; then
        tmux -S /var/maintainer-tmux/maintainer has-session -t maintainer 2>/dev/null
        if [ $? != 0 ] && [ -n $currentTmux ]; then
            if ! $killedHangingSession; then
                echo No maintainer sessions detected...
            fi
            tmux -S /var/maintainer-tmux/maintainer new-session -s maintainer -d
            updateArgsToPassForNewExecution
            tmux -S /var/maintainer-tmux/maintainer send-keys -t maintainer:0.0 "./maintainer.sh ${argsToPass[*]}" ENTER
            echo Attaching to new tmux session...
            tmux -S /var/maintainer-tmux/maintainer attach -t maintainer
            
            realExit=false
            run=false
        else
            if [ ${currentTmux:+1} ]; then
                previousSessionId=`echo \`tmux -S /var/maintainer-tmux/maintainer capture-pane -pt maintainer\` | grep -o -P '(?<=> Session ID: ).{36}'`
                # tmux -S /var/maintainer-tmux/maintainer send-keys -t maintainer:0.0 "clear 2&>/dev/null" ENTER
                echo -e \\"n<< $previousSessionId\\n" >> $maintainerPath/maintainer-log.txt
                echo -e \\"e[044mYou are already in a maintainer tmux session!\\e[0m\\n"
            elif ! $isDetached && ! $reEnter; then
                currentUser=`echo \`tmux -S /var/maintainer-tmux/maintainer capture-pane -pt maintainer\` | grep -o -P '(?<=Welcome )[A-z]+(?= to)|(?<=user )[A-z]+(?= \|)$'`
                if [[  ${username:+1} ]] && [[ "${username}" != "${currentUser}" ]]; then
                    echo -e \\"e[041m> Cannot start maintainer as it is currently in use by \\e[044m $currentUser \\e[041m!\\e[0m\\n"
                    anotherUserRunning=true
                    echo "User $username has tried to run Maintainer script, however it was already in use by $currentUser" >> $maintainerPath/maintainer-log.txt
                fi
                run=false
            else
                echo Re-attaching to running session...
                previousSessionId=`echo \`tmux -S /var/maintainer-tmux/maintainer capture-pane -pt maintainer\` | grep -o -P '(?<=> Session ID: ).{36}'`
                realExit=false
                run=false
                runningScripts=(`pgrep -u $USER maintainer.sh 2>/dev/null`)
                if [[ ${#runningScripts[*]} == 0 ]] &&  [ -n $currentTmux ]; then
                    echo -e \\"n<< $previousSessionId\\n" >> $maintainerPath/maintainer-log.txt
                    echo "No script running, launching maintainer script"
                    updateArgsToPassForNewExecution
                    tmux -S /var/maintainer-tmux/maintainer send-keys -t maintainer:0.0 "./maintainer.sh ${argsToPass[*]}" ENTER
                    # tmux -S /var/maintainer-tmux/maintainer send-keys -t maintainer:0.0 "clear 2&>/dev/null" ENTER
                    
                else
                    echo "Rejoining running script"
                    echo "$timestamp: Rejoining running script" >> $maintainerPath/maintainer-log.txt
                    echo -e "<< $sessionId\\n" >> $maintainerPath/maintainer-log.txt
                fi
                echo "$timestamp: Rejoining maintainer session '$previousSessionId'" >> $maintainerPath/maintainer-log.txt
                tmux -S /var/maintainer-tmux/maintainer attach -t maintainer 2>/dev/null
            fi
        fi
    else
        if [ ${currentTmux:+1} ] && [[ "${newExecution}" == "true" ]]; then
            previousSessionId=`echo \`tmux -S /var/maintainer-tmux/maintainer capture-pane -pt maintainer\` | grep -o -P '(?<=> Session ID: ).{36}'`
            echo -e \\"n<< $previousSessionId\\n" >> $maintainerPath/maintainer-log.txt
            echo -e \\"e[044mYou are already in a maintainer tmux session!\\e[0m\\n"
            echo Re-starting the script
            echo "$timestamp: Re-starting maintainer session" >> $maintainerPath/maintainer-log.txt
            updateArgsToPassForNewExecution
            tmux -S /var/maintainer-tmux/maintainer send-keys -t maintainer:0.0 "./maintainer.sh ${argsToPass[*]}" ENTER
            
        fi
    fi

    if [[ "${newExecution}" == "true" ]]; then
        argsToPass+=("newExecution=false")
    fi

    # Main - module handler
    firstExecutionRun=true
    while ${run}; 
    do
        resize >/dev/null
        if $demo; then 
            printLogoArg=true
            clearArg=true
            printFrames $printLogoArg $clearArg
        else
            printLogoArg=false
            if $firstExecutionRun; then
                printLogoArg=true
            fi
            printFrames $printLogoArg $clearForFrames
        fi
        windowWidth=`tput cols`
        windowHeight=`tput lines`
        if ! [ ${passedModule:+1} ]; then
            linesPrinted=0
            while [[ "$linesPrinted" -lt "18" ]];
            do
                echo
                linesPrinted=$((linesPrinted + 1))
            done
            usernameWidth=${#username}
            dynamicParams="$username"
            dynamicWidth=$usernameWidth

            if $firstExecutionRun; then
                eval "printf \"\\e[044m%0.s-\" {1..$windowWidth}\\n; echo"
                centerAndPrintStringShort="\e[044m| Welcome \e[041m $username \e[044m to \e[043;30m Server-Maintainer \e[044;37m script |"
                centerAndPrintString "\e[044m© \e[047m\e[30mKetchup&Co.\e[044m \e[30m|\e[37m Welcome \e[041;33m $username \e[044;33m to \e[043;30m Server\e[31m-\e[30mMaintainer \e[044;37m script \e[30m|\e[37m © \e[047m\e[30mKetchup&Co."
                eval "printf \"\\e[044m%0.s-\" {1..$windowWidth}\\n; echo"
            else
                eval "printf \"%0.s-\" {1..$windowWidth}\\n; echo"
                centerAndPrintString "\e[044;37m| \e[043;30m Server\e[31m-\e[30mMaintainer \e[044;37m script \e[042;30m Restarted \e[044;37m for user \e[041;33m $username \e[044;37m |"
            fi
            
            dynamicParams="$sessionId"
            dynamicWidth=${#sessionId}
            centerAndPrintString "\e[044m Session ID: $sessionId "; echo

            echo -e \\"e[044mAdd modules to maintainer-modules folder in the script directory with name:\\e[040m\\n\\e[041mmaintainer-<menu-order-number>-<module-role>.sh\\e[0m\\n"
        fi

        if compgen -G "${maintainerModulesPath}/maintainer-*.sh" > /dev/null; then
            cd $maintainerModulesPath
            unset yourfilenames
            yourfilenames=`ls ./maintainer-[0-9]*.sh`

            longestModuleNameLength=15
            for eachfile in $yourfilenames
            do
                chmod +x $eachfile
                filenamenoext=${eachfile%.*}
                niceModuleName="${filenamenoext#*-[0-9]*-}"
                if [ ${#niceModuleName} -gt $longestModuleNameLength ]; then
                    longestModuleNameLength=$((${#niceModuleName}+2))
                    foundHeader="🔍 Found following modules:"
                    foundHeaderLength=$((longestModuleNameLength+2))
                fi
            done

            if ! [ ${passedModule:+1} ]; then
                if compgen -G "${maintainerModulesPath}/maintainer-[0-9]*-server-status.sh" > /dev/null; then
                    actualFileName=`ls ./maintainer-[0-9]*-server-status.sh`
                    serverStatusArgs="colour=true"
                    if  [ ${statusTmuxName:+1} ]; then
                        serverStatusArgs+=" tmuxName=$statusTmuxName"
                    fi
                    updateOwnerships
                    if $demo; then
                        centerAndPrintString "\e[043m Demo mode enabled, running module-example instead of $actualFileName"
                        /bin/bash ${maintainerModulesPath}/maintainer-[0-9]*-module-example.sh
                    else
                        /bin/bash ${maintainerModulesPath}/${actualFileName} $serverStatusArgs
                    fi
                    cd $maintainerPath
                    head -n -1 ${maintainerPath}/maintainer-log.txt > ${maintainerPath}/temp-maintainer-log.txt; mv ${maintainerPath}/temp-maintainer-log.txt ${maintainerPath}/maintainer-log.txt
                    cd $maintainerModulesPath
                fi
            fi
            if  [ ${easyMode:+1} ] && [[ "$easyMode" == "true" ]]; then # Run easyMode with default configs through selection
                eval "printf \"\\e[042;30m%-$foundHeaderLength"s"\\e[0;37m\\n\" \"$foundHeader\""

                unset modules
                modules=()
                yourfilenames=`ls ./maintainer-*.sh`
                for eachfile in $yourfilenames
                do
                    filenamenoext=${eachfile%.*}
                    modules+=(${filenamenoext#*-[0-9]*-})
                done
                modules+=(exit)
                
                PS3="Select module to run:"
                select module in ${modules[*]}
                do
                    case $module in
                        "exit")
                            run=false
                            printFrame1 0.2
                            break;
                        ;;
                        *)
                            if compgen -G "${maintainerModulesPath}/maintainer-[0-9]*-${module}.sh" > /dev/null; then
                                arguments="isMaintainerRun=true username=$username"
                                
                                timestamp=$(date "+%Y-%m-%d-%H-%M-%S")
                                runModule
                                break;
                            fi
                        ;;
                    esac
                done
            else # Use default Maintainer interface with ability to type out the module and specify Args
                if ! [ ${passedModule:+1} ]; then
                    eval "printf \"\\e[042;30m%-$foundHeaderLength"s"\\e[0;37m\\n\" \"$foundHeader\""
                    moduleCenteringSpacesAmount=$(((longestModuleNameLength-15)/2))
                    moduleCenteringSpaces=`eval "printf \"%0.s \" {1..$moduleCenteringSpacesAmount}"`
                    remainingSpaceForArgs=$((windowWidth-longestModuleNameLength-1))
                    argsCenteringSpacesAmount=$(((remainingSpaceForArgs-16)/2))
                    argsCenteringSpaces=`eval "printf \"%0.s \" {1..$argsCenteringSpacesAmount}"`
                    eval "printf \"\\e[046;30m%-$longestModuleNameLength"s"\\e[0;37m|\\e[046;30m%$remainingSpaceForArgs"s"\\e[0;37m\\n\" \"$moduleCenteringSpaces <module-name> \" \" <default args> $argsCenteringSpaces\""

                    niceModuleNames=()
                    for eachfile in $yourfilenames
                    do
                        filenamenoext=${eachfile%.*}
                        niceModuleName="${filenamenoext#*-[0-9]*-}"
                        niceModuleNames+=($niceModuleName)
                        moduleArgs="`$filenamenoext.sh getArgs=true`"
                        moduleArgsLength=$((${#moduleArgs}+2))
                        if [ "$moduleArgsLength" -le "$remainingSpaceForArgs" ]; then
                            eval "printf \"\\e[044m%-$longestModuleNameLength"s"\\e[0m|\\e[044m%-$remainingSpaceForArgs"s"\\e[0m\\n\" \" $niceModuleName \" ' $moduleArgs '"
                            eval "printf \"\\e[044m%0.s-\\e[0m\" {1..$longestModuleNameLength}"
                            printf "|"
                            eval "printf \"\\e[044m%0.s-\\e[0m\" {1..$remainingSpaceForArgs}"
                            echo
                        else
                            moduleNamePrinted=false
                            moduleArgsToAdd=(${moduleArgs[*]})
                            moduleArgsProcessing=true
                            print=false
                            linePrinted=false
                            while ${moduleArgsProcessing};
                            do
                                for ((i = 0 ; i < ${#moduleArgsToAdd[*]} ; i++ ))
                                do
                                    moduleToAdd="${moduleArgsToAdd[$i]}"
                                    moduleArgsToPrint=($moduleToAdd)
                                    argsFit=true
                                    while ${argsFit};
                                    do
                                        nextArgIndex=$((i+1))
                                        nextModule=${moduleArgsToAdd[$nextArgIndex]}
                                        moduleArgsToPrintString="${moduleArgsToPrint[*]}"
                                        newModuleArgsToPrintString="$moduleArgsToPrintString ${nextModule}"
                                        newModuleArgsToPrintStringLength=$((${#newModuleArgsToPrintString}+2))
                                        if [ "$newModuleArgsToPrintStringLength" -lt "$remainingSpaceForArgs" ] && ! [[ "${nextModule}" == "" ]]; then
                                            moduleArgsToPrint+=($nextModule)
                                            i=$((i+1))
                                        else
                                            argsFit=false
                                            print=true
                                        fi
                                    done
                                    if ${print}; then
                                        moduleArgsToPrintString="${moduleArgsToPrint[*]}"
                                        moduleArgsToPrintStringLength=${#moduleArgsToPrintString}

                                        multiLineArg=true
                                        while $multiLineArg;
                                        do
                                            remainingSpaceForArgsWithPadding=$((remainingSpaceForArgs-2))
                                            remainingModuleArgsToPrint=${moduleArgsToPrintString:$remainingSpaceForArgsWithPadding}
                                            moduleArgsToPrintString=${moduleArgsToPrintString:0:$remainingSpaceForArgsWithPadding}
                                            if [[ "${moduleNamePrinted}" == "false" ]]; then
                                                moduleNamePrinted=true
                                                eval "printf \"\\e[044m%-$longestModuleNameLength"s"\\e[0m|\\e[044m%-$remainingSpaceForArgs"s"\\e[0m\\n\" \" $niceModuleName \" ' $moduleArgsToPrintString '"
                                            else
                                                eval "printf \"\\e[044m%-$longestModuleNameLength"s"\\e[0m|\\e[044m%-$remainingSpaceForArgs"s"\\e[0m\\n\" \"\" ' $moduleArgsToPrintString '"
                                            fi
                                            moduleArgsToPrintString=$remainingModuleArgsToPrint
                                            moduleArgsToPrintStringLength=${#moduleArgsToPrintString}
                                            if [ "$moduleArgsToPrintStringLength" -le "0" ]; then
                                                multiLineArg=false
                                            fi
                                        done
                                    fi
                                    moduleArgNumber=$((i+1))
                                    if [[ "${#moduleArgsToAdd[*]}" == "${moduleArgNumber}" ]]; then
                                        moduleArgsProcessing=false
                                        moduleArgsToPrint=()
                                    fi
                                done
                            done
                            eval "printf \"\\e[044m%0.s-\\e[0m\" {1..$longestModuleNameLength}"
                            printf "|"
                            eval "printf \"\\e[044m%0.s-\\e[0m\" {1..$remainingSpaceForArgs}"
                            echo
                        fi
                    done
                    cd $maintainerPath
                    
                    centerAndPrintString "\e[046;30m Type 'exit' to exit the script "
                    
                    centerAndPrintString "\e[046;30m To execute module type it's name and optional args (e.g. module arg=test) "
                    
                    niceModuleNamesString=${niceModuleNames[*]}
                    niceModuleNamesString="${niceModuleNamesString// / \\e[0m|\\e[044m }"
                    centerAndPrintString "\e[44m\e[0m|\e[44m ${niceModuleNamesString} \e[0m|\e[44m"
                    
                    read moduleAndArguments
                    moduleAndArgumentsArr=($moduleAndArguments)
                    if [[ "$moduleAndArguments" == "exit" ]]; then
                        run=false
                    else
                        module=${moduleAndArgumentsArr[0]}
                        arguments="${argsToPass[*]} ${moduleAndArgumentsArr[*]:1}"
                    fi
                else
                    module=$passedModule
                    arguments="${argsToPass[*]}"
                fi
                if [[ "$moduleAndArguments" != "exit" ]]; then
                    moduleExists=`compgen -G "${maintainerModulesPath}/maintainer-[0-9]*-${module}.sh" 2> /dev/null`
                    if [[ "${moduleExists}" != "" ]]; then
                        if ! [[ "$arguments" == *"isMaintainerRun="* ]]; then
                            arguments+=" isMaintainerRun=true"
                        fi
                        if ! [[ "$arguments" == *"username="* ]]; then
                            arguments+=" username=$username"
                        fi

                        timestamp=$(date "+%Y-%m-%d-%H-%M-%S")
                        runModule
                    else
                        if [ -z "$module" ]; then
                            centerAndPrintString "\e[041m ❌ Module name is required! Nothing was executed ❌ "
                        else
                            centerAndPrintString "\e[041m ❌ No modules with name \e[044m' ${module} '\e[041m were found, check your spelling ❌ "
                        fi
                    fi
                    echo
                fi
            fi
        else
            echo -e \\"e[041mNo modules found, please add them to the script directory in following format:\\e[040m\\n\\e[041mmaintainer-<module-role>.sh\\e[0m"
        fi
        cd $maintainerPath
        if $run && [ $endScriptCommand == false ]; then
            runOtherModules
        fi
        firstExecutionRun=false
    done
    sleep 0.1 # To ensure all execution has finished before closing tmux
    if [ $realExit == true ] || [ $anotherUserRunning == true ]; then
        echo "$timestamp: $username has exited the script" >> $maintainerPath/maintainer-log.txt
        echo "Args were: ${allArgs[*]/"newExecution=false"}" >> $maintainerPath/maintainer-log.txt
        echo -e "<< $sessionId" >> $maintainerPath/maintainer-log.txt
        cleanUpLogs
        if [ $endScriptCommand == true ]; then
            eval $endScriptCommandString
        fi
        if [ $realExit == true ]; then
            tmux -S /var/maintainer-tmux/maintainer has-session -t maintainer 2>/dev/null
            if [ $? == 0 ] ||  [ ${currentTmux:+1} ]; then
                tmux -S /var/maintainer-tmux/maintainer kill-session -t maintainer
            fi
        else
            echo >> $maintainerPath/maintainer-log.txt
        fi
    fi
    updateTmuxOwnership=true
    updateOwnerships
    skipSuccessLog=false
fi