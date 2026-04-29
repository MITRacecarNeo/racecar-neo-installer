#!/bin/bash
# Creates the racecar tool for easily using and communicating with a RACECAR

racecar() {
  if [ "$RACECAR_CONFIG_LOADED" != "TRUE" ]; then
    echo "Error: unable to find your local .config file.  Please make sure that you setup the racecar tool correctly."
    echo "Go to \"https://github.com/MITRacecarNeo/racecar-neo-installer\" for setup instructions."
    return 1
  fi

  local RACECAR_DESTINATION_PATH="/home/racecar/jupyter_ws/${RACECAR_TEAM}"

  case "$1" in
    cd)
      cd "$RACECAR_ABSOLUTE_PATH"/labs || return
      ;;

    connect)
      echo "Attempting to connect to RACECAR (${RACECAR_IP})..."
      ssh -t racecar@"$RACECAR_IP" "cd ${RACECAR_DESTINATION_PATH} && export DISPLAY=:0 && bash"
      ;;

    jupyter)
      local prev_dir="$PWD"
      cd "$RACECAR_ABSOLUTE_PATH"/labs || return
      echo "Creating a Jupyter server..."
      jupyter-notebook --no-browser
      cd "$prev_dir" || return
      ;;

    remove)
      echo "This will permanently delete your team directory (${RACECAR_DESTINATION_PATH}) on the RACECAR."
      read -r -p "Are you sure? [y/N] " confirm
      if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        echo "Removing your team directory from your RACECAR..."
        ssh racecar@"$RACECAR_IP" "cd /home/racecar/jupyter_ws/ && rm -rf ${RACECAR_TEAM}"
      else
        echo "Cancelled."
      fi
      ;;

    setup)
      echo "Creating your team directory (${RACECAR_DESTINATION_PATH}) on your RACECAR..."
      ssh racecar@"$RACECAR_IP" mkdir -p "$RACECAR_DESTINATION_PATH"
      racecar sync all
      ;;

    sim)
      if [ $# -lt 2 ]; then
        echo "Usage: racecar sim <filename.py> [additional arguments...]"
        return 1
      fi
      shift  # remove "sim" from args
      local script="$1"; shift  # grab the filename
      python3 "$script" -s "$@"
      ;;

    backup)
      local prev_dir="$PWD"
      cd "$RACECAR_ABSOLUTE_PATH" || return

      if [ ! -d ".backup" ]; then
        echo "Backup folder not found, creating one now..."
        mkdir ./.backup
      fi

      local timestamp
      timestamp="$(date '+%Y%m%d_%H%M%S')"
      local backup_dir=".backup/${timestamp}"

      mkdir "$backup_dir"
      echo "Current date: $(date)" > "$backup_dir/info.txt"
      echo "Racecar ip: $RACECAR_IP" >> "$backup_dir/info.txt"
      echo "Racecar team: $RACECAR_TEAM" >> "$backup_dir/info.txt"

      echo "Backup location: $RACECAR_ABSOLUTE_PATH/$backup_dir"
      echo "Downloading files now..."
      rsync -avP racecar@"$RACECAR_IP":/home/racecar/jupyter_ws "$RACECAR_ABSOLUTE_PATH/$backup_dir"

      cd "$prev_dir" || return
      ;;

    sync)
      if [ $# -lt 2 ]; then
        echo "Usage: racecar sync [labs|library|all]"
        return 1
      fi
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
        echo "'${2}' is not a recognized sync target. Options: labs, library, all"
      fi
      ;;

    test)
      echo "racecar tool set up successfully!"
      echo "  RACECAR_ABSOLUTE_PATH: ${RACECAR_ABSOLUTE_PATH}"
      echo "  RACECAR_IP: ${RACECAR_IP}"
      echo "  RACECAR_TEAM: ${RACECAR_TEAM}"
      ;;

    help)
      echo "The racecar tool helps your computer communicate with your RACECAR."
      echo ""
      echo "Supported commands:"
      echo "  racecar cd                  move to the racecar labs directory on your computer."
      echo "  racecar connect             connects to your car with ssh."
      echo "  racecar help                prints this help message."
      echo "  racecar jupyter             starts a jupyter server in the racecar labs directory."
      echo "  racecar remove              removes your team directory from your car."
      echo "  racecar setup               sets up your team directory on your car."
      echo "  racecar sim <file.py>       runs the specified racecar program with the simulator."
      echo "  racecar sync [labs|library|all]  copies local files to your car with rsync."
      echo "  racecar backup              downloads RACECAR code to a local backup folder."
      echo "  racecar test                prints config to check if the racecar tool is working."
      ;;

    *)
      echo "That was not a recognized racecar command. Run 'racecar help' for a list of commands."
      ;;
  esac
}
