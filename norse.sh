#!/bin/bash

function isPortBinded {
    STATUS=$(nc -z 127.0.0.1 $1 && echo "USE" || echo "FREE")

    if [[ $STATUS == "USE" ]]; then
        true
        return
    else
        false
        return
    fi
}

function isSessionRunning {
    tmux has-session -t $1 2>/dev/null

    if [[ $? = 0 ]]; then
        true
        return
    else
        false
        return
    fi
}

function isServerRunning {
    if doesFileExist "$DIR/.offline"; then
        false
        return
    else
        true
        return
    fi
}

doesFileExist(){
    file=$1
    if test -f "$file"; then
        true
        return
    else
        false
        return
    fi
}

doesFolderExist(){
    folder=$1
    if test -d "$folder"; then
        true
        return
    else
        false
        return
    fi
}

function setServerState {
    source norse.config

    if [ $1 = "offline" ]; then
        touch $DIR/.offline 2>/dev/null
    elif [ $1 = "online" ]; then
        rm -rf $DIR/.offline 2>/dev/null
    else 
        echo "Unknown argument!"
    fi
}

function logGood {
    echo "[ $(tput setaf 2)SUCCESS$(tput sgr 0) ] $1"
}

function logNeutral {
    echo "[  $(tput setaf 3).....$(tput sgr 0)  ] $1"
}

function logBad {
    echo "[  $(tput setaf 1)ERROR$(tput sgr 0)  ] $1 "
}

function haltServer {
    tmux send-keys -t valheim-$ID C-c
}

function killServer {
    tmux kill-session -t $1 2>/dev/null
}

function bootServer {
    tmux new -d -s $1 ./norse.sh bootServerLoop
}

function bootServerLoop {
    source norse.config

    cd $DIR/serverfiles/valheim_server || exit

    i=0
    while [ $i -lt 4 ] 
    do
            echo "Server started"
            rm -rf $DIR/.offline
                export templdpath=$LD_LIBRARY_PATH
                export LD_LIBRARY_PATH=./linux64:$LD_LIBRARY_PATH
                export SteamAppId=892970

                # Tip: Make a local copy of this script to avoid it being overwritten by steam.
                # NOTE: Minimum password length is 5 characters & Password cant be in the server name.
                # NOTE: You need to make sure the ports 2456-2458 is being forwarded to your server through your local router & firewal>
                ./valheim_server.x86_64 -name "$NAME" -port 2456 -world "$WORLD" -password "$PASS" -public "$PUBLIC" -savedir "$DIR/serverfiles"

                export LD_LIBRARY_PATH=$templdpath
            touch $DIR/.offline
            echo "Server stopped"
            sleep 120;
            i=$[$i+1]
    done
}

# Functions for controlling the server

textclear(){
    tput rc
    tput ed
}

setup() {
    #!/bin/bash
    
    clear

    DIR=$PWD
    

    clear

    rm -rf $DIR/norse.config 2>/dev/null
    touch $DIR/norse.config

    mkdir $DIR/serverfiles 2>/dev/null
    mkdir $DIR/backups 2>/dev/null
    mkdir $DIR/bin 2>/dev/null
    mkdir $DIR/serverfiles/valheim_server 2>/dev/null
    mkdir $DIR/assets 2>/dev/null

    cd $DIR/serverfiles/assets && curl -L -o logo.txt "https://raw.githubusercontent.com/z3orc/norse/main/logo.txt" --progress-bar 2>/dev/null
    
    cd $DIR/serverfiles 2>/dev/null

    clear && cat $DIR/assets/logo.txt && echo -e "\n"

    IFS= read -r -p "Server name: " NAME
    
    IFS= read -r -p "World name: " WORLD

    IFS= read -r -p "Password: " PASS

    IFS= read -r -p "Show server in community server browser (y/n): " PUBLIC

    tput sc

    ID=$RANDOM
    PORT=2456

    tput sc

    #Writings settings to settingsfile

    echo DIR="${DIR// /}" >> $DIR/norse.config | xargs
    echo NAME="${NAME// /}" >> $DIR/norse.config | xargs
    echo WORLD="${WORLD// /}" >> $DIR/norse.config | xargs
    echo PASS="${PASS// /}" >> $DIR/norse.config | xargs
    echo ID="${ID// /}" >> $DIR/norse.config | xargs
    
    if [[ $PUBLIC == "y" || $PUBLIC == "Y" ]]; then
        echo PUBLIC="1" >> $DIR/norse.config | xargs
    else
        echo PUBLIC="0" >> $DIR/norse.config | xargs
    fi

    textclear

    clear && cat $DIR/assets/logo.txt && echo -e "\n"

    echo "            [Downloading dependencies]"
    echo "----------------------------------------------------"
    sleep 2

    cd $DIR/bin && mkdir ./steamcmd && cd ./steamcmd

    echo "[  $(tput setaf 3).....$(tput sgr 0)  ] Downloading SteamCMD"

    tput sc

    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" --progress-bar | tar zxvf -

    rm -rf steamcmd_linux.tar.gz

    textclear

    ./steamcmd.sh +quit

    echo "[ $(tput setaf 2)SUCCESS$(tput sgr 0) ] SteamCMD downloaded"


    sleep 2


    echo "[  $(tput setaf 3).....$(tput sgr 0)  ] Downloading Valheim server"

    tput sc

    ./steamcmd.sh +@sSteamCmdForcePlatformType linux +force_install_dir $DIR/serverfiles/valheim_server +login anonymous  +app_update 896660 validate +quit

    textclear

    echo "[ $(tput setaf 2)SUCCESS$(tput sgr 0) ] Valheim server downloaded."

    sleep 2


    echo "[  $(tput setaf 3).....$(tput sgr 0)  ] Validating server integrity"
    
    cd $DIR

    tput sc

    ./norse.sh start

    sleep 15

    textclear
    
    STATUS=$(nc -z 127.0.0.1 2456 && echo "USE" || echo "FREE")
    tmux has-session -t valheim-$ID 2>/dev/null

    if [[ $? = 0 ]]; then
        echo "[ $(tput setaf 2)SUCCESS$(tput sgr 0) ] Server integrity validated"
        exit
    else
        echo "[  $(tput setaf 1)ERROR$(tput sgr 0)  ] Could not validate server integrity, server did not boot."
        exit

    fi
}

function start {
    #!/bin/bash
    source norse.config

    if [[ $1 = "" ]]; then
        logNeutral "Starting server!"

        bootServer valheim-$ID

        sleep 5

        i=0
        while [ $i -lt 60 ];
        do
            if isSessionRunning valheim-$ID && isServerRunning; then
                logGood "Server booted successfully"
                setServerState online
                exit 0
            else
                echo "..."
                i=$[$i+1]
                sleep 2
            fi
        done

        logBad "Could not boot server."
        setServerState offline
        killServer valheim-$ID
    fi
}

function stop {
    #!/bin/bash

    source norse.config

    logNeutral "Stopping server."

    haltServer valheim-$ID

    i=0
    while [[ $i -lt 60 ]];
    do
        if ! isServerRunning; then
            logGood "Server halted successfully"
            killServer valheim-$ID
            if ! isSessionRunning valheim-$ID; then
                break
            fi
        else
            echo "..."
            i=$[$i+1]
            sleep 2
        fi
    done

    if isSessionRunning valheim-$ID; then
        logBad "Could not halt server."
        setServerState online
    fi
}

function backup {
    #!/bin/bash

    source norse.config

    function save {
        logNeutral "Starting backups process and saving world. This might cause server instability"

        logNeutral "Running rdiff-backup."
        nice -n 10 rdiff-backup ./serverfiles ./backups
        logGood "rdiff-backup complete."

        logNeutral "Removing old backups."
        nice -n 10 rdiff-backup --force --remove-older-than 2W $DIR/backups
        logGood "Old backups removed."

        logGood "Backup process complete."
    }

    if [[ $1 = "list" ]]; then
            nice -n 10 rdiff-backup --list-increments $DIR/backups
    fi

    if [[ $1 = "revert" ]]; then
            rdiff-backup -r now $DIR/backups $DIR/serverfiles
    fi

    if isSessionRunning valheim-$ID; then
        stop && save && start
    else
        save && start
    fi
}

function upgrade {
    #!/bin/bash

    source norse.config

    logNeutral "Updating server"

    stop

    $DIR/bin/steamcmd/steamcmd.sh +@sSteamCmdForcePlatformType linux +force_install_dir $DIR/serverfiles/valheim_server +login anonymous +app_update 896660 +quit 2>/dev/null

    logGood "Update process complete."

    start

}

function console {
    source norse.config
    tmux a -t valheim-$ID
}

case "$1" in
        setup)
                setup
                ;;
        start)
                start "${2}"
                ;;
        bootServerLoop)
                bootServerLoop
                ;;
        stop)
                stop
                ;;
        backup)
                backup "${2}"
                ;;
        upgrade)
                upgrade "${2}"
                ;;
        console)
                console
                ;;
        *)
                echo "Usage: ./norse.sh {start|stop|upgrade|backup|console|setup}"
esac