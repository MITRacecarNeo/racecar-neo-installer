#!/usr/bin/env bash

# static variables
SIM_URL="https://github.com/MITRacecarNeo/RacecarNeo-Simulator.git"
LIB_URL="https://github.com/MITRacecarNeo/racecar-neo-library.git"
CURR_URL="https://github.com/MITRacecarNeo/racecar-neo-"

# Get the full path of the current script
SCRIPT_PATH=$(readlink -f "$0" 2>/dev/null || echo "$(cd "$(dirname "$0")"; pwd)/$(basename "$0")")

# Extract the directory from the full path
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")

# Extract the racecar-student directory
RACECAR_DIR=$(dirname "$SCRIPT_DIR")

# Extract the racecar-neo-installer directory
NEO_DIR=$(dirname "$RACECAR_DIR")

echo 'Welcome to the RACECAR Neo command-line installer for Windows, Mac, and Linux.'


echo '[1/3] Select your operating system: [windows, mac, linux]'
select PLATFORM in windows mac linux

do
    case $PLATFORM in
        windows|mac|linux)
            cd "$SCRIPT_DIR"/..
            cd ..
            # Clone file from github, format dirs
            git clone -b "${PLATFORM}" --single-branch "${SIM_URL}"

            # Allow permissions
            if [ "$PLATFORM" == 'mac' ]; then
                chmod -R 777 RacecarNeo-Simulator
            fi

            break
            ;;
        *)
            ;;
    esac
done


echo '[2/3] Select your course curriculum: [oneshot, outreach, prereq, mites]'
select CURRICULUM in oneshot outreach prereq mites

do
    case $CURRICULUM in
        oneshot|outreach|prereq|mites)
            # Go one folder back from scripts directory
            cd "$SCRIPT_DIR"/..
            # Set up library and labs folder w/ correct formatting
            git clone "${LIB_URL}" 
            mv racecar-neo-library/library library
            rm -rf racecar-neo-library

            git clone "${CURR_URL}${CURRICULUM}-labs"
            mv "racecar-neo-${CURRICULUM}-labs"/labs labs
            rm -rf "racecar-neo-${CURRICULUM}-labs"
            cd "$SCRIPT_DIR"
            break
            ;;
        *)
            ;;
    esac
done

echo '[3/3] Installing all RACECAR libraries and dependencies...'
# Install RACECAR libraries and dependencies
if [ "$PLATFORM" == 'windows' ]; then
    yes | sudo apt update
    yes | sudo apt upgrade
    yes | sudo apt install python-is-python3
    yes | sudo apt install python3-pip

    # Setting up venv for Python 3.9
    yes | sudo add-apt-repository ppa:deadsnakes/ppa
    yes | sudo apt update
    yes | sudo apt install python3.9
    yes | sudo apt install python3.9-venv

    cd "$SCRIPT_DIR"/../..
    python3.9 -m venv racecar-venv
    # sed to prevent idempotency
    # sed -i "/^source ${NEO_DIR}\/racecar-venv\/bin\/activate$/!a source ${NEO_DIR}/racecar-venv/bin/activate" ~/.bashrc
    echo "source ${NEO_DIR}/racecar-venv/bin/activate" >> ~/.bashrc # temp command

    # continue with regular setup
    # yes | pip install -r "${SCRIPT_DIR}"/requirements.txt # old pip install command - not needed anymore (speed up install)
    yes | sudo apt install jupyter-notebook
    yes | sudo apt install ffmpeg libsm6 libxext6 -y
    busybox dos2unix "${SCRIPT_DIR}"/racecar_tool.sh

    echo "[DEBUG] Running config and tool commands..."

    # Windows config command
    echo "RACECAR_ABSOLUTE_PATH=${RACECAR_DIR}
RACECAR_IP=127.0.0.1
RACECAR_TEAM=student
RACECAR_CONFIG_LOADED=TRUE
export DISPLAY=localhost:42.0" > "${SCRIPT_DIR}/.config"

    # Windows tool command
    sed '/# RACECAR_ALIASES$/d' -i ~/.bashrc
    echo "# Source RACECAR tool # RACECAR_ALIASES
if [ -f \"${SCRIPT_DIR}/.config\" ]; then # RACECAR_ALIASES
    . \"${SCRIPT_DIR}/.config\" # RACECAR_ALIASES
fi # RACECAR_ALIASES
if [ -f \"${SCRIPT_DIR}/racecar_tool.sh\" ]; then # RACECAR_ALIASES
    . \"${SCRIPT_DIR}/racecar_tool.sh\" # RACECAR_ALIASES
fi # RACECAR_ALIASES" >> ~/.bashrc

    echo "[DEBUG] Finished running config and tool commands..."

elif [ "$PLATFORM" == 'linux' ]; then
    yes | sudo apt update
    yes | sudo apt upgrade
    yes | sudo apt install python-is-python3
    yes | sudo apt install python3-pip

    # Setting up venv for Python 3.9
    yes | sudo add-apt-repository ppa:deadsnakes/ppa
    yes | sudo apt update
    yes | sudo apt install python3.9
    yes | sudo apt install python3.9-venv

    cd "$SCRIPT_DIR"/../..
    python3.9 -m venv racecar-venv
    # sed to prevent idempotency
    # sed -i "/^source ${NEO_DIR}\/racecar-venv\/bin\/activate$/!a source ${NEO_DIR}/racecar-venv/bin/activate" ~/.bashrc
    echo "source ${NEO_DIR}/racecar-venv/bin/activate" >> ~/.bashrc # temp command

    # yes | pip install -r "${SCRIPT_DIR}"/requirements.txt # old pip install command not needed anymore
    yes | sudo apt install jupyter-notebook
    yes | sudo apt install ffmpeg libsm6 libxext6 -y
    busybox dos2unix "${SCRIPT_DIR}"/racecar_tool.sh

    echo "[DEBUG] Running config and tool commands..."

    # Linux config command
    echo "RACECAR_ABSOLUTE_PATH=${RACECAR_DIR}
RACECAR_IP=127.0.0.1
RACECAR_TEAM=student
RACECAR_CONFIG_LOADED=TRUE
sudo sysctl -w net.ipv4.udp_mem="65535 131071 262142"" > "${SCRIPT_DIR}/.config"

    # Linux tool command
    sed '/# RACECAR_ALIASES$/d' -i ~/.bashrc
    echo "# Source RACECAR tool # RACECAR_ALIASES
if [ -f \"${SCRIPT_DIR}/.config\" ]; then # RACECAR_ALIASES
    . \"${SCRIPT_DIR}/.config\" # RACECAR_ALIASES
fi # RACECAR_ALIASES
if [ -f \"${SCRIPT_DIR}/racecar_tool.sh\" ]; then # RACECAR_ALIASES
    . \"${SCRIPT_DIR}/racecar_tool.sh\" # RACECAR_ALIASES
fi # RACECAR_ALIASES" >> ~/.bashrc

    echo "[DEBUG] Finished running config and tool commands..."

elif [ "$PLATFORM" == 'mac' ]; then
    xcode-select --install

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.bash_profile

    /bin/bash brew install python3

    echo 'export PATH="/usr/local/opt/python/libexec/bin:$PATH"' >> ~/.zprofile
    echo 'export PATH="/usr/local/opt/python/libexec/bin:$PATH"' >> ~/.bash_profile
                                                                            
    echo 'export PATH="/usr/local/opt/python/libexec/bin:$PATH"'  

    python3 -m pip install --upgrade pip

    # Set up venv on mac
    brew install python@3.9
    cd "$SCRIPT_DIR"/../..
    python3.9 -m venv racecar-venv
    # TODO: replace with correct sed -i command when known
    echo "source ${NEO_DIR}/racecar-venv/bin/activate" >> ~/.bashrc
    echo "source ${NEO_DIR}/racecar-venv/bin/activate" >> ~/.zshrc

    # yes | pip3 install -r "${SCRIPT_DIR}"/requirements.txt #  old pip install command not needed anymore

    echo "[DEBUG] Running config and tool commands..."

    # Mac config command
    echo "RACECAR_ABSOLUTE_PATH=${RACECAR_DIR}
RACECAR_IP=127.0.0.1
RACECAR_TEAM=student
RACECAR_CONFIG_LOADED=TRUE
sudo sysctl -w net.inet.udp.maxdgram=65535" > "${SCRIPT_DIR}/.config"

    # Mac tool command
    sed -i '' '/# RACECAR_ALIASES$/d' ~/.bashrc
    echo "# Source RACECAR tool # RACECAR_ALIASES
if [ -f \"${SCRIPT_DIR}/.config\" ]; then # RACECAR_ALIASES
    . \"${SCRIPT_DIR}/.config\" # RACECAR_ALIASES
fi # RACECAR_ALIASES
if [ -f \"${SCRIPT_DIR}/racecar_tool.sh\" ]; then # RACECAR_ALIASES
    . \"${SCRIPT_DIR}/racecar_tool.sh\" # RACECAR_ALIASES
fi # RACECAR_ALIASES" >> ~/.bashrc

    sed -i '' '/# RACECAR_ALIASES$/d' ~/.zshrc
    echo "# Source RACECAR tool # RACECAR_ALIASES
if [ -f \"${SCRIPT_DIR}/.config\" ]; then # RACECAR_ALIASES
    . \"${SCRIPT_DIR}/.config\" # RACECAR_ALIASES
fi # RACECAR_ALIASES
if [ -f \"${SCRIPT_DIR}/racecar_tool.sh\" ]; then # RACECAR_ALIASES
    . \"${SCRIPT_DIR}/racecar_tool.sh\" # RACECAR_ALIASES
fi # RACECAR_ALIASES" >> ~/.zshrc

    $SHELL

    echo "[DEBUG] Finished running config and tool commands..."
fi

echo 'Racecar Neo Setup Complete.'