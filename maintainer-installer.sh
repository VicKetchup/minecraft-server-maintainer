#!/bin/bash
relogRequired=false
echo -e "\e[43;30mInstalling Dependencies...\e[0m"
# Install xterm if not installed
if ! which xterm >/dev/null; then
    echo -e "\e[42mInstalling xterm...\e[0m"
    sudo apt update
    sudo apt install xterm
fi
# Install tmux if not installed
if ! which tmux >/dev/null; then
    echo -e "\e[42mInstalling tmux...\e[0m"
    sudo apt update
    sudo apt install tmux
fi

echo -e "\e[43;30mSetting up maintainer group...\e[0m"
# Create 'maintainer' group if it doesn't exist and add root and current user to it
if ! grep -q "^maintainer:" /etc/group; then
    sudo groupadd maintainer
    sudo usermod -a -G maintainer root
    sudo usermod -a -G maintainer $USER
    relogRequired=true
fi
echo -e "\e[43;30mSetting up maintainer session directory...\e[0m"
# Create the directory if it doesn't exist
if ! [ -d "/var/maintainer-tmux" ]; then
    echo -e "\e[42mCreating directory for Tmux...\e[0m"
    sudo mkdir -p /var/maintainer-tmux
    # Change the ownership of the directory to root:maintainer
    sudo chown root:maintainer /var/maintainer-tmux
    # Set the permissions so that only root and members of 'maintainer' group can access it
    sudo chmod 770 /var/maintainer-tmux
    relogRequired=true
fi

# If maintainer.sh is not available:
if ! [ -f "maintainer.sh" ] || ! [ -f "maintainer-common.sh" ]; then
    # Install git if not installed
    if ! which git >/dev/null; then
        echo -e "\e[42mInstalling git...\e[0m"
        sudo apt update
        sudo apt install git
    fi
    # Clone minecraft-server-maintainer from git
    if git clone https://github.com/VicKetchup/minecraft-server-maintainer minecraft-server-maintainer; then
        # Copy maintainer.sh, easyMaintainer.sh, maintainer-common.sh, Ketchup_and_Co_startup.sh, maintainer-ads.sh and maintainer-modules folder to current directory
        echo -e "\e[43;30mGit clone successful. Copying maintainer scripts...\e[0m"
        cp -r minecraft-server-maintainer/maintainer.sh minecraft-server-maintainer/maintainer-common.sh minecraft-server-maintainer/Ketchup_and_Co_startup.sh minecraft-server-maintainer/easyMaintainer.sh minecraft-server-maintainer/maintainer-ads.sh minecraft-server-maintainer/maintainer-modules .
        # Add executing permission to all of the copied files
        echo -e "\e[43;30mAdding executing permission to maintainer scripts...\e[0m"
        chmod +x maintainer.sh easyMaintainer.sh maintainer-common.sh Ketchup_and_Co_startup.sh maintainer-ads.sh maintainer-modules/*
    fi
else
    echo -e "\e[43;30mMaintainer scripts already exist. Skipping...\e[0m"
fi

# Execute maintainer-common.sh to create the config file
./maintainer-common.sh demo=false clearForFrames=false maintainerMainUser=$USER

# Add Ketchup_and_Co_startup.sh to .bashrc if not already added
if ! grep -q "Ketchup_and_Co_startup.sh" ~/.bashrc; then
    echo -e "\e[42mDo you want to add Ketchup_and_Co_startup.sh to .bashrc? (y/n)\e[0m"
    read answer
    if [ "$answer" != "${answer#[Yy]}" ]; then
        echo -e "\e[42mAdding Ketchup_and_Co_startup.sh to .bashrc...\e[0m"
        echo "bash $PWD/Ketchup_and_Co_startup.sh" >> ~/.bashrc
    fi
fi

# If relogRequired is true, inform the user and force logout
if [ "$relogRequired" = true ]; then
    echo -e "\e[43;30mLogging out to ensure changes take effect...\e[0m"
    echo -e "\e[41mPress any key to continue...\e[0m"
    read -n 1 -s
    exit
fi