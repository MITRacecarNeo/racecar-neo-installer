#!/usr/bin/env bash

SIM_URL="https://github.com/MITRacecarNeo/RacecarNeo-Simulator/archive/refs/tags"

# Get the full path of the current script
SCRIPT_PATH=$(realpath "$0")

# Extract the directory from the full path
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")

echo 'Welcome to the RACECAR Neo command-line simulator update tool for Windows, Mac, and Linux.'


echo '[1/2] Select your operating system: [windows, mac, linux]'
select PLATFORM in windows mac linux

do
    case $PLATFORM in
        windows|mac|linux)
            
            break
            ;;
        *)
            ;;
    esac
done

echo '[2/2] Select the version you would like to download:'
select VERSION in 2.0.0

do
    case $VERSION in
        2.0.0)
            break
            ;;
        *)
            ;;
    esac
done

TARGET="${SIM_URL}/${PLATFORM}_v${VERSION}.zip"
# Go two folders back from scripts directory
cd "$SCRIPT_DIR"/..
cd ..
# Remove current RacecarSim directory
rm -rf "RacecarSim"
# Pull file from github, unzip and place in dir, format dirs
wget -qO- $TARGET | busybox unzip -
SIMNAME="RacecarSim-binary-${PLATFORM}_${RELEASE_DATE}"
mv "$SIMNAME" RacecarSim

# Allow permissions
if [ "$PLATFORM" == 'mac' ]; then
    chmod -R 777 RacecarSim
fi

echo "RacecarSim successfully updated to version v${$VERSION} on ${PLATFORM}"