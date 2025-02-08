#!/usr/bin/env bash

# update.sh
# one update file to rule them all
# assists with updating labs, libraries, and simulator

echo 'Welcome to the RACECAR Neo command-line updating tool.'

# Github locations of simulator, library, and curriculum (labs)
SIM_URL="https://github.com/MITRacecarNeo/RacecarNeo-Simulator.git"
LIB_URL="https://github.com/MITRacecarNeo/racecar-neo-library.git"
CURR_URL="https://github.com/MITRacecarNeo/racecar-neo-"

# Get the full path of the current script
SCRIPT_PATH=$(readlink -f "$0" 2>/dev/null || echo "$(cd "$(dirname "$0")"; pwd)/$(basename "$0")")

# Extract the directory from the full path
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")

# Extract the racecar-student directory
RACECAR_DIR=$(dirname "$SCRIPT_DIR")

echo '[1/3] Select the folder that you would lke to update: [labs, library, sim]'
select FOLDER in labs library sim
do
    case $FOLDER in
        labs|library|sim)
            echo "Folder '$FOLDER' selected. Continuing..."
            break  # Exit the loop after a valid selection
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
done

if [ "$FOLDER" == 'labs' ]; then
    echo '[1/3] Now updating the labs folder...'
    echo '[WARNING] Rename delete your previous lab folder before continuing! This command will erase your existing work! Ctrl+C to exit if needed.'
    echo 'Select your course curriculum: [oneshot, outreach, prereq, mites]'
    select CURRICULUM in oneshot outreach prereq mites
    do
        case $CURRICULUM in
            oneshot|outreach|prereq|mites)
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
elif [ "$FOLDER" == 'library' ]; then
    echo '[2/3] Now updating the library folder...'
    #Remove the existing library directory
    # Go one folder back from scripts directory
    cd "$SCRIPT_DIR"/..
    #remove the library folder
    rm -rf library
    # Set up library and labs folder w/ correct formatting
    git clone "${LIB_URL}"
    mv racecar-neo-library/library library
    rm -rf racecar-neo-library
elif [ "$FOLDER" == 'sim' ]; then
    echo '[2/3] Now updating the simulation folder...'
    echo 'Select your operating system: [windows, mac, linux]'
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
fi

echo '[3/3] Update complete.'