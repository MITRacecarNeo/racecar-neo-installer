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

# ============================================================================
# Logging setup
# ============================================================================
LOG_DIR="${SCRIPT_DIR}/.logs"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/setup_$(date '+%Y-%m-%d_%H-%M-%S').log"

# Log a message to both the console and the log file
log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg" >> "$LOG_FILE"
    echo "$1"
}

# Log a message to the log file only (for verbose/debug output)
log_silent() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Run a command, logging its output to the log file while showing it on screen
run_cmd() {
    log_silent "RUNNING: $*"
    "$@" 2>&1 | tee -a "$LOG_FILE"
    local exit_code=${PIPESTATUS[0]}
    if [ $exit_code -ne 0 ]; then
        log_silent "WARNING: Command exited with code $exit_code: $*"
    fi
    return $exit_code
}

# Run a piped command string (for commands like "yes | sudo apt install ...")
run_pipe() {
    log_silent "RUNNING: $*"
    eval "$*" 2>&1 | tee -a "$LOG_FILE"
    local exit_code=${PIPESTATUS[0]}
    if [ $exit_code -ne 0 ]; then
        log_silent "WARNING: Command exited with code $exit_code: $*"
    fi
    return $exit_code
}

# Capture start time for duration calculation
SETUP_START_TIME=$(date +%s)

# Log system info for debugging
log_silent "========== SETUP LOG START =========="
log_silent "Date: $(date)"
log_silent "User: $(whoami)"
log_silent "Home: $HOME"
log_silent "Shell: $SHELL"
log_silent "Kernel: $(uname -a)"
log_silent "SCRIPT_DIR: $SCRIPT_DIR"
log_silent "RACECAR_DIR: $RACECAR_DIR"
log_silent "NEO_DIR: $NEO_DIR"
log_silent "======================================"

log 'Welcome to the RACECAR Neo command-line installer for Windows, Mac, and Linux.'
log "Setup log: $LOG_FILE"

# Check if setup has already been run
ALREADY_INSTALLED=false
if [ -f "${SCRIPT_DIR}/.local_bashrc.sh" ] || [ -d "${NEO_DIR}/racecar-venv" ] || [ -d "${NEO_DIR}/RacecarNeo-Simulator" ]; then
    ALREADY_INSTALLED=true
fi

if [ "$ALREADY_INSTALLED" = true ]; then
    echo ""
    echo -e "\e[1;31m=========================================================================="
    echo "[ERROR] A previous installation was detected."
    echo "=========================================================================="
    echo ""
    echo "Running setup again can cause nested or duplicate folders."
    echo "To reinstall, delete the entire racecar-neo-installer folder and start fresh:"
    echo ""
    echo "  rm -rf ${NEO_DIR}"
    echo "  git clone https://github.com/MITRacecarNeo/racecar-neo-installer.git"
    echo "  bash racecar-neo-installer/racecar-student/scripts/setup.sh"
    echo ""
    echo "If you only need to update labs, library, or the simulator, use:"
    echo "  bash ${SCRIPT_DIR}/update.sh"
    echo -e "==========================================================================\e[0m"
    echo ""
    log_silent "ABORTED: previous installation detected"
    log_silent "========== SETUP LOG END (ABORTED) =========="
    exit 1
fi

log '[1/3] Select your operating system: [windows, mac, linux]'
select PLATFORM in windows mac linux

do
    case $PLATFORM in
        windows|mac|linux)
            log_silent "Platform selected: $PLATFORM"
            cd "$SCRIPT_DIR"/..
            cd ..
            # Clone file from github, format dirs
            log "Cloning simulator for ${PLATFORM}..."
            run_cmd git clone -b "${PLATFORM}" --single-branch "${SIM_URL}"

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


log '[2/3] Select your course curriculum: [oneshot, outreach, prereq, mites]'
select CURRICULUM in oneshot outreach prereq mites

do
    case $CURRICULUM in
        oneshot|outreach|prereq|mites)
            log_silent "Curriculum selected: $CURRICULUM"
            # Go one folder back from scripts directory
            cd "$SCRIPT_DIR"/..
            # Set up library and labs folder w/ correct formatting
            log "Cloning library..."
            run_cmd git clone "${LIB_URL}"
            mv racecar-neo-library/library library
            rm -rf racecar-neo-library

            log "Cloning ${CURRICULUM} labs..."
            run_cmd git clone "${CURR_URL}${CURRICULUM}-labs"
            mv "racecar-neo-${CURRICULUM}-labs"/labs labs
            rm -rf "racecar-neo-${CURRICULUM}-labs"
            cd "$SCRIPT_DIR"
            break
            ;;
        *)
            ;;
    esac
done

log '[3/3] Installing all RACECAR libraries and dependencies...'
# Install RACECAR libraries and dependencies
if [ "$PLATFORM" == 'windows' ]; then
    log_silent "Starting Windows (WSL2) setup..."
    run_pipe "yes | sudo apt update"
    run_pipe "yes | sudo apt upgrade"
    run_pipe "yes | sudo apt install python-is-python3"
    run_pipe "yes | sudo apt install python3-pip"

    # Setting up venv for Python 3.9
    run_pipe "yes | sudo add-apt-repository ppa:deadsnakes/ppa"
    run_pipe "yes | sudo apt update"
    run_pipe "yes | sudo apt install python3.9"
    run_pipe "yes | sudo apt install python3.9-venv"

    if ! command -v python3.9 &> /dev/null; then
        log ""
        echo -e "\e[1;31m[ERROR] Python 3.9 installation failed. Cannot continue setup.\e[0m"
        log "Check that your Ubuntu version is supported by the deadsnakes PPA."
        log "See https://launchpad.net/~deadsnakes/+archive/ubuntu/ppa for supported versions."
        log_silent "========== SETUP LOG END (ABORTED) =========="
        exit 1
    fi

    cd "$SCRIPT_DIR"/../..
    log "Creating Python 3.9 virtual environment..."
    run_cmd python3.9 -m venv racecar-venv

    # Activate venv, upgrade pip, and install requirements
    if [ -f "${NEO_DIR}/racecar-venv/bin/activate" ]; then
        log "Installing Python dependencies..."
        source "${NEO_DIR}/racecar-venv/bin/activate"
        run_cmd pip install --upgrade pip
        run_cmd pip install -r "${SCRIPT_DIR}/requirements.txt"
    else
        log ""
        echo -e "\e[1;31m[ERROR] Virtual environment creation failed. Cannot continue setup.\e[0m"
        log "Try running: python3.9 -m venv racecar-venv manually to see the error."
        log_silent "========== SETUP LOG END (ABORTED) =========="
        exit 1
    fi

    # continue with regular setup
    run_pipe "yes | sudo apt install jupyter-notebook"
    run_pipe "yes | sudo apt install ffmpeg libsm6 libxext6 -y"
    run_cmd busybox dos2unix "${SCRIPT_DIR}"/racecar_tool.sh

    log_silent "Writing .config file..."

    # Windows config command
    echo "RACECAR_ABSOLUTE_PATH=${RACECAR_DIR}
RACECAR_IP=127.0.0.1
RACECAR_TEAM=student
RACECAR_CONFIG_LOADED=TRUE
export DISPLAY=localhost:42.0" > "${SCRIPT_DIR}/.config"

    log_silent "Writing .local_bashrc.sh..."

    # Write the local bashrc file that sources all racecar-related config
    cat > "${SCRIPT_DIR}/.local_bashrc.sh" << BASHEOF
# RACECAR Neo environment — auto-generated by setup.sh
# Do not edit manually; re-run setup.sh to regenerate.

# Activate the racecar virtual environment
if [ -f "${NEO_DIR}/racecar-venv/bin/activate" ]; then
    source "${NEO_DIR}/racecar-venv/bin/activate"
fi

# Load racecar configuration
if [ -f "${SCRIPT_DIR}/.config" ]; then
    . "${SCRIPT_DIR}/.config"
fi

# Load the racecar tool and aliases
if [ -f "${SCRIPT_DIR}/racecar_tool.sh" ]; then
    . "${SCRIPT_DIR}/racecar_tool.sh"
fi
BASHEOF

    # Add a single source line to ~/.bashrc (remove any old RACECAR_ALIASES lines first)
    sed '/# RACECAR_ALIASES$/d' -i ~/.bashrc
    # Remove any old venv activate lines from previous setup runs
    sed "\|source ${NEO_DIR}/racecar-venv/bin/activate|d" -i ~/.bashrc
    echo "source \"${SCRIPT_DIR}/.local_bashrc.sh\" # RACECAR_ALIASES" >> ~/.bashrc

    log_silent "Shell configuration complete."

    # WSL2 firewall notice (orange text for visibility)
    echo ""
    echo -e "\e[33m=========================================================================="
    log "[IMPORTANT] Windows Firewall Configuration Required"
    echo "=========================================================================="
    echo "WSL2 requires a Windows Firewall rule to allow the RacecarNeo Simulator to"
    echo "communicate with your Python scripts. Without this rule, the simulator"
    echo "may fail to connect when your computer is connected to the internet."
    echo ""
    echo "Please open PowerShell as Administrator on Windows and run:"
    echo ""
    echo "  New-NetFirewallRule -DisplayName \"WSL2 RacecarNeo Simulator\" -Direction Inbound -InterfaceAlias (Get-NetAdapter -IncludeHidden | Where-Object { \$_.Name -like '*WSL*' } | Select-Object -First 1 -ExpandProperty Name) -Action Allow -Protocol UDP -LocalPort 5064-5065"
    echo ""
    echo "If that command fails, first find your WSL adapter name:"
    echo "  Get-NetAdapter -IncludeHidden | Where-Object { \$_.Name -like '*WSL*' }"
    echo "Then use the Name from the output in place of the -InterfaceAlias parameter."
    echo ""
    echo "You only need to run this command once."
    echo -e "==========================================================================\e[0m"
    echo ""

elif [ "$PLATFORM" == 'linux' ]; then
    log_silent "Starting Linux setup..."
    run_pipe "yes | sudo apt update"
    run_pipe "yes | sudo apt upgrade"
    run_pipe "yes | sudo apt install python-is-python3"
    run_pipe "yes | sudo apt install python3-pip"

    # Setting up venv for Python 3.9
    run_pipe "yes | sudo add-apt-repository ppa:deadsnakes/ppa"
    run_pipe "yes | sudo apt update"
    run_pipe "yes | sudo apt install python3.9"
    run_pipe "yes | sudo apt install python3.9-venv"

    if ! command -v python3.9 &> /dev/null; then
        log ""
        echo -e "\e[1;31m[ERROR] Python 3.9 installation failed. Cannot continue setup.\e[0m"
        log "Check that your Ubuntu version is supported by the deadsnakes PPA."
        log "See https://launchpad.net/~deadsnakes/+archive/ubuntu/ppa for supported versions."
        log_silent "========== SETUP LOG END (ABORTED) =========="
        exit 1
    fi

    cd "$SCRIPT_DIR"/../..
    log "Creating Python 3.9 virtual environment..."
    run_cmd python3.9 -m venv racecar-venv

    # Activate venv, upgrade pip, and install requirements
    if [ -f "${NEO_DIR}/racecar-venv/bin/activate" ]; then
        log "Installing Python dependencies..."
        source "${NEO_DIR}/racecar-venv/bin/activate"
        run_cmd pip install --upgrade pip
        run_cmd pip install -r "${SCRIPT_DIR}/requirements.txt"
    else
        log ""
        echo -e "\e[1;31m[ERROR] Virtual environment creation failed. Cannot continue setup.\e[0m"
        log "Try running: python3.9 -m venv racecar-venv manually to see the error."
        log_silent "========== SETUP LOG END (ABORTED) =========="
        exit 1
    fi

    run_pipe "yes | sudo apt install jupyter-notebook"
    run_pipe "yes | sudo apt install ffmpeg libsm6 libxext6 -y"
    run_cmd busybox dos2unix "${SCRIPT_DIR}"/racecar_tool.sh

    log_silent "Writing .config file..."

    # Linux config command
    echo "RACECAR_ABSOLUTE_PATH=${RACECAR_DIR}
RACECAR_IP=127.0.0.1
RACECAR_TEAM=student
RACECAR_CONFIG_LOADED=TRUE
sudo sysctl -w net.ipv4.udp_mem=\"65535 131071 262142\"" > "${SCRIPT_DIR}/.config"

    log_silent "Writing .local_bashrc.sh..."

    # Write the local bashrc file that sources all racecar-related config
    cat > "${SCRIPT_DIR}/.local_bashrc.sh" << BASHEOF
# RACECAR Neo environment — auto-generated by setup.sh
# Do not edit manually; re-run setup.sh to regenerate.

# Activate the racecar virtual environment
if [ -f "${NEO_DIR}/racecar-venv/bin/activate" ]; then
    source "${NEO_DIR}/racecar-venv/bin/activate"
fi

# Load racecar configuration
if [ -f "${SCRIPT_DIR}/.config" ]; then
    . "${SCRIPT_DIR}/.config"
fi

# Load the racecar tool and aliases
if [ -f "${SCRIPT_DIR}/racecar_tool.sh" ]; then
    . "${SCRIPT_DIR}/racecar_tool.sh"
fi
BASHEOF

    # Add a single source line to ~/.bashrc (remove any old RACECAR_ALIASES lines first)
    sed '/# RACECAR_ALIASES$/d' -i ~/.bashrc
    sed "\|source ${NEO_DIR}/racecar-venv/bin/activate|d" -i ~/.bashrc
    echo "source \"${SCRIPT_DIR}/.local_bashrc.sh\" # RACECAR_ALIASES" >> ~/.bashrc

    log_silent "Shell configuration complete."

elif [ "$PLATFORM" == 'mac' ]; then
    log_silent "Starting Mac setup..."
    run_cmd xcode-select --install

    run_cmd /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.bash_profile

    run_cmd /bin/bash brew install python3

    echo 'export PATH="/usr/local/opt/python/libexec/bin:$PATH"' >> ~/.zprofile
    echo 'export PATH="/usr/local/opt/python/libexec/bin:$PATH"' >> ~/.bash_profile

    echo 'export PATH="/usr/local/opt/python/libexec/bin:$PATH"'

    run_cmd python3 -m pip install --upgrade pip

    # Set up venv on mac
    run_cmd brew install python@3.9

    if ! command -v python3.9 &> /dev/null; then
        log ""
        echo -e "\e[1;31m[ERROR] Python 3.9 installation failed. Cannot continue setup.\e[0m"
        log "Try running: brew install python@3.9 manually to see the error."
        log_silent "========== SETUP LOG END (ABORTED) =========="
        exit 1
    fi

    cd "$SCRIPT_DIR"/../..
    log "Creating Python 3.9 virtual environment..."
    run_cmd python3.9 -m venv racecar-venv

    # Activate venv, upgrade pip, and install requirements
    if [ -f "${NEO_DIR}/racecar-venv/bin/activate" ]; then
        log "Installing Python dependencies..."
        source "${NEO_DIR}/racecar-venv/bin/activate"
        run_cmd pip install --upgrade pip
        run_cmd pip install -r "${SCRIPT_DIR}/requirements.txt"
    else
        log ""
        echo -e "\e[1;31m[ERROR] Virtual environment creation failed. Cannot continue setup.\e[0m"
        log "Try running: python3.9 -m venv racecar-venv manually to see the error."
        log_silent "========== SETUP LOG END (ABORTED) =========="
        exit 1
    fi

    log_silent "Writing .config file..."

    # Mac config command
    echo "RACECAR_ABSOLUTE_PATH=${RACECAR_DIR}
RACECAR_IP=127.0.0.1
RACECAR_TEAM=student
RACECAR_CONFIG_LOADED=TRUE
sudo sysctl -w net.inet.udp.maxdgram=65535" > "${SCRIPT_DIR}/.config"

    log_silent "Writing .local_bashrc.sh..."

    # Write the local bashrc file that sources all racecar-related config
    cat > "${SCRIPT_DIR}/.local_bashrc.sh" << BASHEOF
# RACECAR Neo environment — auto-generated by setup.sh
# Do not edit manually; re-run setup.sh to regenerate.

# Activate the racecar virtual environment
if [ -f "${NEO_DIR}/racecar-venv/bin/activate" ]; then
    source "${NEO_DIR}/racecar-venv/bin/activate"
fi

# Load racecar configuration
if [ -f "${SCRIPT_DIR}/.config" ]; then
    . "${SCRIPT_DIR}/.config"
fi

# Load the racecar tool and aliases
if [ -f "${SCRIPT_DIR}/racecar_tool.sh" ]; then
    . "${SCRIPT_DIR}/racecar_tool.sh"
fi
BASHEOF

    # Add a single source line to ~/.bashrc and ~/.zshrc
    # Remove any old RACECAR_ALIASES lines and venv lines first
    sed -i '' '/# RACECAR_ALIASES$/d' ~/.bashrc
    sed -i '' "\|source ${NEO_DIR}/racecar-venv/bin/activate|d" ~/.bashrc
    echo "source \"${SCRIPT_DIR}/.local_bashrc.sh\" # RACECAR_ALIASES" >> ~/.bashrc

    sed -i '' '/# RACECAR_ALIASES$/d' ~/.zshrc
    sed -i '' "\|source ${NEO_DIR}/racecar-venv/bin/activate|d" ~/.zshrc
    echo "source \"${SCRIPT_DIR}/.local_bashrc.sh\" # RACECAR_ALIASES" >> ~/.zshrc

    log_silent "Shell configuration complete."
fi

# ============================================================================
# Post-setup verification
# ============================================================================
log ""
log "Running post-setup checks..."
log "=========================================================================="

PASS=0
FAIL=0

check_pass() {
    echo -e "  \e[32m[PASS]\e[0m $1"
    log_silent "[PASS] $1"
    PASS=$((PASS + 1))
}

check_fail() {
    echo -e "  \e[31m[FAIL]\e[0m $1"
    log_silent "[FAIL] $1"
    FAIL=$((FAIL + 1))
}

# 1. Simulator folder
if [ -d "${NEO_DIR}/RacecarNeo-Simulator" ]; then
    check_pass "Simulator folder exists"
else
    check_fail "Simulator folder not found"
fi

# 2. Labs folder
if [ -d "${RACECAR_DIR}/labs" ]; then
    check_pass "Labs folder exists"
else
    check_fail "Labs folder not found"
fi

# 3. Library folder
if [ -d "${RACECAR_DIR}/library" ]; then
    check_pass "Library folder exists"
else
    check_fail "Library folder not found"
fi

# 4. Virtual environment
if [ -f "${NEO_DIR}/racecar-venv/bin/activate" ]; then
    check_pass "Virtual environment exists"
else
    check_fail "Virtual environment not found"
fi

# 5. Shell config
if [ "$PLATFORM" == 'mac' ]; then
    if grep -q "RACECAR_ALIASES" ~/.zshrc 2>/dev/null; then
        check_pass "Shell config added to ~/.zshrc"
    else
        check_fail "Shell config missing from ~/.zshrc"
    fi
else
    if grep -q "RACECAR_ALIASES" ~/.bashrc 2>/dev/null; then
        check_pass "Shell config added to ~/.bashrc"
    else
        check_fail "Shell config missing from ~/.bashrc"
    fi
fi

# 6. .local_bashrc.sh
if [ -f "${SCRIPT_DIR}/.local_bashrc.sh" ]; then
    check_pass ".local_bashrc.sh created"
else
    check_fail ".local_bashrc.sh not found"
fi

# 7. .config file
if [ -f "${SCRIPT_DIR}/.config" ]; then
    check_pass ".config file created"
else
    check_fail ".config file not found"
fi

# 8. Racecar tool
if [ -f "${SCRIPT_DIR}/racecar_tool.sh" ]; then
    # Source the tool and test it
    . "${SCRIPT_DIR}/.config"
    . "${SCRIPT_DIR}/racecar_tool.sh"
    RACECAR_TEST_OUTPUT=$(racecar test 2>&1)
    if echo "$RACECAR_TEST_OUTPUT" | grep -q "successfully"; then
        check_pass "Racecar tool is working"
    else
        check_fail "Racecar tool loaded but 'racecar test' did not report success"
    fi
else
    check_fail "racecar_tool.sh not found"
fi

# 9. Log file errors (check for command failures logged by run_cmd/run_pipe)
LOG_ERRORS=$(grep -c "WARNING: Command exited with code" "$LOG_FILE" 2>/dev/null)
LOG_ERRORS=${LOG_ERRORS:-0}
if [ "$LOG_ERRORS" -gt 0 ]; then
    check_fail "Log file contains ${LOG_ERRORS} command failure(s) — review $LOG_FILE"
else
    check_pass "No command failures detected in log file"
fi

# 10. Python dependencies
if [ -f "${NEO_DIR}/racecar-venv/bin/activate" ]; then
    source "${NEO_DIR}/racecar-venv/bin/activate"
    DEP_FAIL=0
    DEP_MISSING=""
    while IFS= read -r line; do
        # Skip empty lines and comments
        [ -z "$line" ] && continue
        [[ "$line" =~ ^# ]] && continue
        # Extract package name (before ==, >=, <=, ~=, or whitespace)
        PKG_NAME=$(echo "$line" | sed 's/[=<>~!].*//' | xargs)
        # Normalize: replace hyphens with underscores for pip check
        if python3 -c "import importlib; importlib.import_module('${PKG_NAME//-/_}')" 2>/dev/null || \
           pip show "$PKG_NAME" > /dev/null 2>&1; then
            :
        else
            DEP_FAIL=$((DEP_FAIL + 1))
            DEP_MISSING="${DEP_MISSING} ${PKG_NAME}"
        fi
    done < "${SCRIPT_DIR}/requirements.txt"

    if [ $DEP_FAIL -eq 0 ]; then
        check_pass "All Python dependencies installed"
    else
        check_fail "Missing Python packages:${DEP_MISSING}"
    fi
else
    check_fail "Cannot verify dependencies — virtual environment not found"
fi

# 11. WSL networking mode (Windows only)
if [ "$PLATFORM" == 'windows' ]; then
    WSL_VERSION="unknown"
    WSL_NET_MODE="unknown"
    SIM_IP="unknown"

    # Detect WSL version
    if grep -qi "microsoft" /proc/version 2>/dev/null; then
        if grep -qi "WSL2" /proc/version 2>/dev/null; then
            WSL_VERSION="WSL2"
        else
            # Could be WSL1 or WSL2 without "WSL2" in version string
            # Check for Hyper-V features that only exist in WSL2
            if [ -d "/sys/class/dmi" ] 2>/dev/null; then
                WSL_VERSION="WSL2"
            else
                WSL_VERSION="WSL1"
            fi
        fi
    fi

    # Detect networking mode and resolve simulator IP
    if [ "$WSL_VERSION" == "WSL1" ]; then
        WSL_NET_MODE="shared (WSL1)"
        SIM_IP="127.0.0.1"
    elif [ "$WSL_VERSION" == "WSL2" ]; then
        # Read default gateway
        GW_IP=$(awk '$2 == "00000000" { hex=$3; \
            printf "%d.%d.%d.%d", \
            strtonum("0x"substr(hex,7,2)), strtonum("0x"substr(hex,5,2)), \
            strtonum("0x"substr(hex,3,2)), strtonum("0x"substr(hex,1,2)) }' /proc/net/route 2>/dev/null)
        FIRST_OCTET=$(echo "$GW_IP" | cut -d. -f1)
        SECOND_OCTET=$(echo "$GW_IP" | cut -d. -f2)

        if [ "$FIRST_OCTET" == "172" ] && [ "$SECOND_OCTET" -ge 16 ] && [ "$SECOND_OCTET" -le 31 ] 2>/dev/null; then
            WSL_NET_MODE="NAT (Hyper-V gateway: ${GW_IP})"
            SIM_IP="$GW_IP"
        else
            WSL_NET_MODE="mirrored (gateway: ${GW_IP})"
            SIM_IP="127.0.0.1"
        fi
    fi

    check_pass "WSL environment: ${WSL_VERSION}, networking: ${WSL_NET_MODE}"
    log_silent "  Simulator IP will resolve to: ${SIM_IP}"

    # Test UDP connectivity to simulator ports
    if [ -f "${NEO_DIR}/racecar-venv/bin/activate" ]; then
        source "${NEO_DIR}/racecar-venv/bin/activate"
        UDP_RESULT=$(python3 -c "
import socket
ip = '${SIM_IP}'
ok = True
for port in [5064, 5065]:
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.settimeout(1)
        s.sendto(b'\\x01\\x01', (ip, port))
        s.close()
    except Exception as e:
        ok = False
        print(f'FAIL:{port}:{e}')
if ok:
    print('OK')
" 2>&1)
        if echo "$UDP_RESULT" | grep -q "OK"; then
            check_pass "UDP send to simulator (${SIM_IP}:5064-5065) — reachable"
        else
            check_fail "UDP send to simulator (${SIM_IP}) — ${UDP_RESULT}"
        fi
    fi
fi

# Results summary
log ""
log "=========================================================================="
TOTAL=$((PASS + FAIL))
if [ $FAIL -eq 0 ]; then
    echo -e "  \e[1;32mAll ${TOTAL} checks passed!\e[0m"
    log_silent "All ${TOTAL} checks passed!"
else
    echo -e "  \e[1;31m${FAIL} of ${TOTAL} checks failed.\e[0m Review the log: $LOG_FILE"
    log_silent "${FAIL} of ${TOTAL} checks failed."
fi
log "=========================================================================="

# ============================================================================
# Installation summary
# ============================================================================
SETUP_END_TIME=$(date +%s)
SETUP_DURATION=$((SETUP_END_TIME - SETUP_START_TIME))
SETUP_MINUTES=$((SETUP_DURATION / 60))
SETUP_SECONDS=$((SETUP_DURATION % 60))

log ""
echo -e "\e[1;36m======================== INSTALLATION SUMMARY ========================\e[0m"
echo -e "  Platform:         \e[1m${PLATFORM}\e[0m"
echo -e "  Curriculum:       \e[1m${CURRICULUM}\e[0m"
echo -e "  Install location: \e[1m${NEO_DIR}\e[0m"
echo -e "  Log file:         \e[1m${LOG_FILE}\e[0m"
echo -e "  Duration:         \e[1m${SETUP_MINUTES}m ${SETUP_SECONDS}s\e[0m"
echo -e "\e[1;36m======================================================================\e[0m"

log_silent "======================== INSTALLATION SUMMARY ========================"
log_silent "  Platform:         ${PLATFORM}"
log_silent "  Curriculum:       ${CURRICULUM}"
log_silent "  Install location: ${NEO_DIR}"
log_silent "  Log file:         ${LOG_FILE}"
log_silent "  Duration:         ${SETUP_MINUTES}m ${SETUP_SECONDS}s"
log_silent "  Checks:           ${PASS}/${TOTAL} passed"
log_silent "======================================================================"

# Remind user to reload their shell
echo ""
if [ "$PLATFORM" == 'mac' ]; then
    echo -e "\e[1;31m##########################################################################"
    echo "##                                                                      ##"
    echo "##   Run  source ~/.zshrc  or open a new terminal to finish setup.      ##"
    echo "##                                                                      ##"
    echo -e "##########################################################################\e[0m"
else
    echo -e "\e[1;31m##########################################################################"
    echo "##                                                                      ##"
    echo "##   Run  source ~/.bashrc  or open a new terminal to finish setup.     ##"
    echo "##                                                                      ##"
    echo -e "##########################################################################\e[0m"
fi
echo ""

echo -e "\e[1;32mRACECAR Neo Setup Complete.\e[0m"

log_silent "========== SETUP LOG END =========="
