#!/usr/bin/env bash

# static variables
CURR_URL="https://github.com/MITRacecarNeo/racecar-neo-"

# Get the full path of the current script
SCRIPT_PATH=$(readlink -f "$0" 2>/dev/null || echo "$(cd "$(dirname "$0")"; pwd)/$(basename "$0")")

# Extract the directory from the full path
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")

# Extract the racecar-student directory
RACECAR_DIR=$(dirname "$SCRIPT_DIR")

echo 'Welcome to the RACECAR Neo command-line lab updater. Please remove or rename your old labs folder before continuing.'

echo '[1/1] Select your course curriculum: [oneshot, outreach, prereq]'
select CURRICULUM in oneshot outreach prereq

do
    case $CURRICULUM in
        oneshot|outreach|prereq)
            # Go one folder back from scripts directory
            cd "$SCRIPT_DIR"/..
            # Set up labs folder w/ correct formatting
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
