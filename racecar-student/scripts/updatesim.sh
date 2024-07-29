#!/usr/bin/env bash

# static variables
SIM_URL="https://github.com/MITRacecarNeo/RacecarNeo-Simulator.git"

# Get the full path of the current script
SCRIPT_PATH=$(realpath "$0")

# Extract the directory from the full path
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")

# Extract the racecar-student directory
RACECAR_DIR=$(dirname "$SCRIPT_DIR")

echo 'Welcome to the RACECAR Neo command-line simualtor updater for Windows, Mac, and Linux.'

echo '[1/1] Select your operating system: [windows, mac, linux]'
select PLATFORM in windows mac linux

do
    case $PLATFORM in
        windows|mac|linux)
            cd "$SCRIPT_DIR"/..
            cd ..

            # Remove current sim files
            rm -rf RacecarNeo-Simulator

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

echo 'Simulator Update Complete'