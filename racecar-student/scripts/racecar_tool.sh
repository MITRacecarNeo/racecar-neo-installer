#!/bin/sh
# Creates the racecar tool for easily using and communicating with a RACECAR

racecar() {
  if [ "$RACECAR_CONFIG_LOADED" != "TRUE" ]; then
    echo "Error: unable to find your local .config file.  Please make sure that you setup the racecar tool correctly."
    echo "Go to \"https://mitll-racecar-mn.readthedocs.io/en/latest/gettingStarted/computerSetup.html\" for setup instructions."
  else
    local RACECAR_DESTINATION_PATH="/home/racecar/jupyter_ws/${RACECAR_TEAM}"
    if [ $# -eq 1 ] && [ "$1" = "cd" ]; then
      cd "$RACECAR_ABSOLUTE_PATH"/labs || return
    elif [ $# -eq 1 ] && [ "$1" = "connect" ]; then
      echo "Attempting to connect to RACECAR (${RACECAR_IP})..."
      ssh -t racecar@"$RACECAR_IP" "cd ${RACECAR_DESTINATION_PATH} && export DISPLAY=:0 && bash"
    elif [ $# -eq 1 ] && [ "$1" = "jupyter" ]; then
      racecar cd
      echo "Creating a Jupyter server..."
      jupyter-notebook --no-browser
    elif [ $# -eq 1 ] && [ "$1" = "remove" ]; then
      echo "Removing your team directory from your RACECAR..."
      ssh racecar@"$RACECAR_IP" "cd /home/racecar/jupyter_ws/ && rm -rf ${RACECAR_TEAM}"
    elif [ $# -eq 1 ] && [ "$1" = "setup" ]; then
      echo "Creating your team directory (${RACECAR_DESTINATION_PATH}) on your RACECAR..."
      ssh racecar@"$RACECAR_IP" mkdir -p "$RACECAR_DESTINATION_PATH"
      racecar sync all
    elif [ $# -ge 2 ] && [ "$1" = "sim" ]; then
      python3 "$2" -s "$3" "$4" "$5" "$6"
    elif [ $# -eq 1 ] && [ "$1" = "backup" ]; then
      cd "$RACECAR_ABSOLUTE_PATH"
      now="$(date)"
      if [ ! -d "backup" ]
      then
        echo "Backup folder not found, creating one now..."
        mkdir ./backup
        echo "Backup folder created, continuing..."
      else
        echo "Backup folder found, continuing..."
      fi
      shopt -s nullglob
      numfiles=(./backup/*)
      numfiles=${#numfiles[@]}
      mkdir ./backup/version_"$numfiles"
      echo "Current date: $now" > ./backup/version_"$numfiles"/info.txt
      echo "Racecar ip: $RACECAR_IP" >> ./backup/version_"$numfiles"/info.txt
      echo "Racecar team: $RACECAR_TEAM" >> ./backup/version_"$numfiles"/info.txt
      echo "Backup number: $numfiles"
      echo "Backup location: $RACECAR_ABSOLUTE_PATH"/backup/version_"$numfiles"
      echo "Downloading files now..."
      scp -rp racecar@$RACECAR_IP:/home/racecar/jupyter_ws $RACECAR_ABSOLUTE_PATH/backup/version_$numfiles
    elif [ $# -eq 2 ] && [ "$1" = "sync" ]; then
      local valid_command=false
      if [ "$2" = "library" ] || [ "$2" = "all" ]; then
        echo "Copying your local copy of the RACECAR library to your car (${RACECAR_IP})..."
        rsync -azP --delete "$RACECAR_ABSOLUTE_PATH"/library racecar@"$RACECAR_IP":"$RACECAR_DESTINATION_PATH"
        valid_command=true
      fi
      if [ "$2" = "labs" ] || [ "$2" = "all" ]; then
        echo "Copying your local copy of the RACECAR labs to your car (${RACECAR_IP})..."
        rsync -azP --delete "$RACECAR_ABSOLUTE_PATH"/labs racecar@"$RACECAR_IP":"$RACECAR_DESTINATION_PATH"
        valid_command=true
      fi
      if [ "$valid_command" = false ]; then
        echo "'${2}' is not a recognized sync command.  Please enter one of the following:"
        echo "racecar sync labs"
        echo "racecar sync library"
        echo "racecar sync all"
      fi
    elif [ $# -eq 1 ] && [ "$1" = "test" ]; then
      echo "racecar tool set up successfully!"
      echo "  RACECAR_ABSOLUTE_PATH: ${RACECAR_ABSOLUTE_PATH}"
      echo "  RACECAR_IP: ${RACECAR_IP}"
      echo "  RACECAR_TEAM: ${RACECAR_TEAM}"
    else
      if [ $# -eq 1 ] && [ "$1" = "help" ]; then
        echo "The racecar tool helps your computer communicate with your RACECAR."
      else
        echo "That was not a recognized racecar command."
      fi
      echo ""
      echo "Supported commands:"
      echo "  racecar cd: move to the racecar labs directory on your computer."
      echo "  racecar connect: connects to your car with ssh."
      echo "  racecar help: prints this help message."
      echo "  racecar jupyter: starts a jupyter server in the racecar labs directory."
      echo "  racecar remove: removes your team directory from your car."
      echo "  racecar setup: sets up your team directory on your car."
      echo "  racecar sim <filename.py>: runs the specified racecar program for use with RacecarSim."
      echo "  racecar sync library: copies your local RACECAR library folder to your car with scp."
      echo "  racecar sync labs: copies your local RACECAR labs folder to your car with scp."
      echo "  racecar sync all: copies all local RACECAR files to you car with scp."
      echo "  racecar backup: Creates a backup of the physical RACECAR code on a local computer."
      echo "  racecar test: prints a message to check if the RACECAR tool was set up successfully."
    fi
  fi
}