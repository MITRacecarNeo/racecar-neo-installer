#!/usr/bin/env bash


# static variables
SIM_URL="https://github.com/MITRacecarNeo/RacecarNeo-Simulator.git"
LIB_URL="https://github.com/MITRacecarNeo/racecar-neo-library.git"
CURR_URL="https://github.com/MITRacecarNeo/racecar-neo-"

# Get the full path of the current script
SCRIPT_PATH=$(realpath "$0")

# Extract the directory from the full path
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")

# Extract the racecar-student directory
RACECAR_DIR=$(dirname "$SCRIPT_DIR")

#Remove the existing library directory
# Go one folder back from scripts directory
cd "$SCRIPT_DIR"/..
#remove the library folder
rm -rf library
# Set up library and labs folder w/ correct formatting
git clone "${LIB_URL}"
mv racecar-neo-library/library library
rm -rf racecar-neo-library
