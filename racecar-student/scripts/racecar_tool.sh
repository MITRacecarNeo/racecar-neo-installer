#!/bin/bash
# Creates the racecar tool for easily using and communicating with a RACECAR

# Raise the UDP buffer once per shell session, only when actually needed.
# Called from 'racecar sim'. No-op on WSL (Windows handles buffers itself) and
# no-op if the kernel already has the desired value, so sudo only prompts when
# the value really needs changing.
_racecar_tune_udp() {
  [ "$RACECAR_UDP_TUNED" = "1" ] && return 0

  if grep -qi "microsoft" /proc/version 2>/dev/null; then
    export RACECAR_UDP_TUNED=1
    return 0
  fi

  if ! command -v sysctl >/dev/null 2>&1; then
    export RACECAR_UDP_TUNED=1
    return 0
  fi

  local key want
  case "$(uname)" in
    Linux)  key="net.ipv4.udp_mem";      want="65535 131071 262142" ;;
    Darwin) key="net.inet.udp.maxdgram"; want="65535" ;;
    *)      export RACECAR_UDP_TUNED=1; return 0 ;;
  esac

  local current
  current=$(sysctl -n "$key" 2>/dev/null | tr -s '[:space:]' ' ' | sed 's/^ //;s/ $//')
  if [ "$current" = "$want" ]; then
    export RACECAR_UDP_TUNED=1
    return 0
  fi

  echo "Tuning UDP buffer (${key}) — sudo password may be required (one time per session)..."
  if sudo sysctl -w "${key}=\"${want}\"" >/dev/null; then
    export RACECAR_UDP_TUNED=1
  else
    echo "Warning: could not raise UDP buffer. Simulator may drop packets under load."
  fi
}

# On WSL2 in NAT mode, RacecarSim runs on Windows while Python runs in WSL, and large camera
# datagrams are lost crossing the WSL-Windows network (the lab freezes a few frames in). The sim
# relay carries the traffic over a WSL interop pipe instead: Python talks to the relay on
# 127.0.0.1 inside WSL, and its Windows half talks to RacecarSim on Windows' 127.0.0.1. No
# firewall rule is needed.
#
# The relay is used ONLY on WSL2 in NAT mode. WSL1 and mirrored mode share localhost with
# Windows, so the relay's ports would collide with the simulator's; those setups (and macOS /
# Linux) keep the direct path unchanged. RACECAR_SIM_RELAY=0 disables the relay, and an
# explicitly set RACECAR_SIM_IP is always respected.
_racecar_relay_wanted() {
  [ "${RACECAR_SIM_RELAY:-1}" != "0" ] || return 1
  [ -z "$RACECAR_SIM_IP" ] || return 1
  # WSL2 only: its kernel release contains "WSL2"; WSL1 and native Linux do not.
  grep -qi "WSL2" /proc/sys/kernel/osrelease 2>/dev/null || return 1
  # Not mirrored mode. Older WSL builds without wslinfo only support NAT.
  local mode
  mode=$(wslinfo --networking-mode 2>/dev/null | tr -d '\r')
  [ "$mode" != "mirrored" ]
}

# Stop relays left behind by an earlier run (for example, a terminal closed mid-lab). They hold
# ports 5064/5065 and would block the new relay.
_racecar_relay_clear_stale() {
  pkill -u "$(id -u)" -f "[s]im_relay/relay_wsl.py" 2>/dev/null || return 0
  local i
  for i in $(seq 1 30); do
    pgrep -u "$(id -u)" -f "[s]im_relay/relay_wsl.py" >/dev/null 2>&1 || return 0
    sleep 0.1
  done
  pkill -9 -u "$(id -u)" -f "[s]im_relay/relay_wsl.py" 2>/dev/null
  return 0
}

_racecar_relay_start() {
  local dir="${RACECAR_ABSOLUTE_PATH}/scripts/sim_relay"
  if [ ! -f "$dir/relay_wsl.py" ] || [ ! -f "$dir/relay_win.ps1" ]; then
    echo "Warning: simulator relay files not found in ${dir}."
    return 1
  fi
  _racecar_relay_clear_stale
  local log
  log=$(mktemp)
  python3 "$dir/relay_wsl.py" "$(wslpath -w "$dir/relay_win.ps1")" >"$log" 2>&1 &
  RACECAR_RELAY_PID=$!
  disown "$RACECAR_RELAY_PID" 2>/dev/null
  local i
  for i in $(seq 1 40); do
    if grep -q "relay ready" "$log"; then
      rm -f "$log"
      return 0
    fi
    kill -0 "$RACECAR_RELAY_PID" 2>/dev/null || break
    sleep 0.25
  done
  echo "Warning: could not start the simulator relay:"
  sed 's/^/  /' "$log"
  rm -f "$log"
  _racecar_relay_stop
  return 1
}

_racecar_relay_stop() {
  if [ -n "$RACECAR_RELAY_PID" ]; then
    kill "$RACECAR_RELAY_PID" 2>/dev/null
    local i
    for i in $(seq 1 20); do
      kill -0 "$RACECAR_RELAY_PID" 2>/dev/null || break
      sleep 0.1
    done
    unset RACECAR_RELAY_PID
  fi
}

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
      echo "Creating a JupyterLab server..."
      jupyter lab --no-browser
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
      _racecar_tune_udp
      shift  # remove "sim" from args
      local script="$1"; shift  # grab the filename
      if _racecar_relay_wanted; then
        if _racecar_relay_start; then
          RACECAR_SIM_IP=127.0.0.1 python3 "$script" -s "$@"
          local status=$?
          _racecar_relay_stop
          return $status
        fi
        echo "Falling back to a direct connection to the simulator (set RACECAR_SIM_RELAY=0 to skip the relay)."
      fi
      # Direct path: unchanged behavior, and the fallback if the relay cannot start.
      python3 "$script" -s "$@"
      ;;

    open_sim)
      # Locate the simulator folder. RACECAR_ABSOLUTE_PATH is the racecar-student
      # dir; the simulator lives one level up alongside it (and on Windows, that
      # path is a symlink into /mnt/c/Users/<user>/RacecarNeo-Simulator).
      local sim_root="$(dirname "$RACECAR_ABSOLUTE_PATH")/RacecarNeo-Simulator"
      if [ ! -d "$sim_root" ]; then
        echo "Error: simulator folder not found at ${sim_root}."
        echo "Run setup.sh or 'bash \$(dirname \"\$RACECAR_ABSOLUTE_PATH\")/racecar-student/scripts/update.sh' to install it."
        return 1
      fi

      # The simulator builds are packaged as RacecarSim_<Platform>_v<version>/.
      # Pick the first match so version bumps don't break this command.
      local sim_build
      sim_build=$(find -L "$sim_root" -maxdepth 1 -mindepth 1 -type d -name 'RacecarSim_*' | head -n1)
      if [ -z "$sim_build" ]; then
        echo "Error: no RacecarSim_* build folder found inside ${sim_root}."
        return 1
      fi

      # Detect host OS and launch the right binary.
      if grep -qi "microsoft" /proc/version 2>/dev/null; then
        # WSL — invoke the .exe through cmd.exe so Windows owns the process and
        # resolves DLLs from a real NTFS path (not a \\wsl.localhost UNC path).
        local exe_path="${sim_build}/RacecarSim.exe"
        if [ ! -f "$exe_path" ]; then
          echo "Error: RacecarSim.exe not found at ${exe_path}."
          return 1
        fi
        local win_path
        win_path=$(wslpath -w "$exe_path" 2>/dev/null)
        if [ -z "$win_path" ]; then
          echo "Error: could not translate ${exe_path} to a Windows path via wslpath."
          return 1
        fi
        echo "Launching simulator: ${win_path}"
        ( cd "$sim_build" && cmd.exe /c start "" "$win_path" ) >/dev/null 2>&1 &
        disown 2>/dev/null
      elif [ "$(uname)" = "Darwin" ]; then
        local app_path
        app_path=$(find -L "$sim_build" -maxdepth 1 -mindepth 1 -name 'RacecarSim*.app' | head -n1)
        if [ -z "$app_path" ]; then
          echo "Error: RacecarSim*.app bundle not found in ${sim_build}."
          return 1
        fi
        echo "Launching simulator: ${app_path}"
        open "$app_path"
      elif [ "$(uname)" = "Linux" ]; then
        local lin_exe
        lin_exe=$(find -L "$sim_build" -maxdepth 1 -mindepth 1 -type f \( -name 'RacecarSim.x86_64' -o -name 'RacecarSim' \) | head -n1)
        if [ -z "$lin_exe" ]; then
          echo "Error: RacecarSim Linux binary not found in ${sim_build}."
          return 1
        fi
        chmod +x "$lin_exe" 2>/dev/null
        echo "Launching simulator: ${lin_exe}"
        ( cd "$sim_build" && "$lin_exe" ) >/dev/null 2>&1 &
        disown 2>/dev/null
      else
        echo "Error: unrecognized OS. 'racecar open_sim' supports Windows (WSL), Mac, and Linux."
        return 1
      fi
      ;;

    open_sim_folder)
      local sim_root="$(dirname "$RACECAR_ABSOLUTE_PATH")/RacecarNeo-Simulator"
      if [ ! -d "$sim_root" ]; then
        echo "Error: simulator folder not found at ${sim_root}."
        return 1
      fi

      if grep -qi "microsoft" /proc/version 2>/dev/null; then
        # Resolve the symlink so Explorer opens the real /mnt/c path, not \\wsl.localhost.
        local real_root
        real_root=$(readlink -f "$sim_root")
        local win_path
        win_path=$(wslpath -w "$real_root" 2>/dev/null)
        if [ -z "$win_path" ]; then
          echo "Error: could not translate ${real_root} to a Windows path."
          return 1
        fi
        echo "Opening folder: ${win_path}"
        explorer.exe "$win_path" >/dev/null 2>&1 &
        disown 2>/dev/null
      elif [ "$(uname)" = "Darwin" ]; then
        echo "Opening folder: ${sim_root}"
        open "$sim_root"
      elif [ "$(uname)" = "Linux" ]; then
        if ! command -v xdg-open >/dev/null 2>&1; then
          echo "Error: xdg-open not found. Install xdg-utils or open manually: ${sim_root}"
          return 1
        fi
        echo "Opening folder: ${sim_root}"
        xdg-open "$sim_root" >/dev/null 2>&1 &
        disown 2>/dev/null
      else
        echo "Error: unrecognized OS. 'racecar open_sim_folder' supports Windows (WSL), Mac, and Linux."
        return 1
      fi
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
      echo "  racecar jupyter             starts a JupyterLab server in the racecar labs directory."
      echo "  racecar remove              removes your team directory from your car."
      echo "  racecar setup               sets up your team directory on your car."
      echo "  racecar sim <file.py>       runs the specified racecar program with the simulator."
      echo "  racecar open_sim            launches the RacecarNeo simulator GUI."
      echo "  racecar open_sim_folder     opens the simulator folder in your file manager."
      echo "  racecar sync [labs|library|all]  copies local files to your car with rsync."
      echo "  racecar backup              downloads RACECAR code to a local backup folder."
      echo "  racecar test                prints config to check if the racecar tool is working."
      ;;

    *)
      echo "That was not a recognized racecar command. Run 'racecar help' for a list of commands."
      ;;
  esac
}
