#!/usr/bin/env bash

# update.sh
# one update file to rule them all
# assists with updating labs, libraries, and simulator

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

# Extract the racecar-neo-installer directory
NEO_DIR=$(dirname "$RACECAR_DIR")

# ============================================================================
# Logging setup
# ============================================================================
LOG_DIR="${SCRIPT_DIR}/.logs"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/update_$(date '+%Y-%m-%d_%H-%M-%S').log"

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

# Capture start time for duration calculation
UPDATE_START_TIME=$(date +%s)

# Log system info for debugging
log_silent "========== UPDATE LOG START =========="
log_silent "Date: $(date)"
log_silent "User: $(whoami)"
log_silent "Home: $HOME"
log_silent "Shell: $SHELL"
log_silent "Kernel: $(uname -a)"
log_silent "SCRIPT_DIR: $SCRIPT_DIR"
log_silent "RACECAR_DIR: $RACECAR_DIR"
log_silent "NEO_DIR: $NEO_DIR"
log_silent "======================================"

log 'Welcome to the RACECAR Neo command-line updating tool.'
log "Update log: $LOG_FILE"

log '[1/3] Select the folder that you would like to update: [labs, library, sim]'
select FOLDER in labs library sim
do
    case $FOLDER in
        labs|library|sim)
            log_silent "Folder selected: $FOLDER"
            log "Folder '$FOLDER' selected. Continuing..."
            break
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
done

if [ "$FOLDER" == 'labs' ]; then
    log '[2/3] Now updating the labs folder...'
    echo -e "\e[33m[WARNING] This command will replace your existing labs folder!"
    echo -e "Rename or back up your previous lab folder before continuing."
    echo -e "Press Ctrl+C to exit if needed.\e[0m"
    log 'Select your course curriculum: [oneshot, outreach, prereq, mites]'
    select CURRICULUM in oneshot outreach prereq mites
    do
        case $CURRICULUM in
            oneshot|outreach|prereq|mites)
                log_silent "Curriculum selected: $CURRICULUM"
                # Go one folder back from scripts directory
                cd "$SCRIPT_DIR"/..
                # Remove existing labs folder
                rm -rf labs
                # Set up labs folder w/ correct formatting
                log "Cloning ${CURRICULUM} labs..."
                run_cmd git clone --depth 1 "${CURR_URL}${CURRICULUM}-labs"
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
    log '[2/3] Now updating the library folder...'
    # Go one folder back from scripts directory
    cd "$SCRIPT_DIR"/..
    # Remove the existing library folder
    rm -rf library
    # Set up library folder w/ correct formatting
    log "Cloning library..."
    run_cmd git clone --depth 1 "${LIB_URL}"
    mv racecar-neo-library/library library
    rm -rf racecar-neo-library

    # Reinstall Python dependencies in case requirements changed
    if [ -f "${NEO_DIR}/racecar-venv/bin/activate" ]; then
        log "Reinstalling Python dependencies..."
        source "${NEO_DIR}/racecar-venv/bin/activate"
        run_cmd pip install --upgrade pip
        run_cmd pip install -r "${SCRIPT_DIR}/requirements.txt"
    fi
elif [ "$FOLDER" == 'sim' ]; then
    log '[2/3] Now updating the simulation folder...'
    log 'Select your operating system: [windows, mac, linux]'
    select PLATFORM in windows mac linux
    do
        case $PLATFORM in
            windows|mac|linux)
                log_silent "Platform selected: $PLATFORM"
                cd "$SCRIPT_DIR"/..
                cd ..

                # Remove current sim files
                rm -rf RacecarNeo-Simulator

                # Clone file from github, format dirs.
                # --depth 1 implies --single-branch; -b PLATFORM still selects
                # which branch. Drop .git/ after clone — students don't need it.
                log "Cloning simulator for ${PLATFORM}..."
                run_cmd git clone --depth 1 -b "${PLATFORM}" "${SIM_URL}"
                rm -rf RacecarNeo-Simulator/.git

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

# ============================================================================
# Post-update verification
# ============================================================================
log ""
log "[3/3] Running post-update checks..."
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

# Checks specific to what was updated
if [ "$FOLDER" == 'labs' ]; then
    if [ -d "${RACECAR_DIR}/labs" ]; then
        LAB_COUNT=$(find "${RACECAR_DIR}/labs" -maxdepth 1 -type d | wc -l)
        check_pass "Labs folder exists (${LAB_COUNT} items)"
    else
        check_fail "Labs folder not found after update"
    fi
elif [ "$FOLDER" == 'library' ]; then
    if [ -d "${RACECAR_DIR}/library" ]; then
        check_pass "Library folder exists"
    else
        check_fail "Library folder not found after update"
    fi

    if [ -d "${RACECAR_DIR}/library/simulation" ]; then
        check_pass "Simulation sub-library exists"
    else
        check_fail "Simulation sub-library not found"
    fi

    if [ -d "${RACECAR_DIR}/library/real" ]; then
        check_pass "Real racecar sub-library exists"
    else
        check_fail "Real racecar sub-library not found"
    fi

    # Check Python dependencies
    if [ -f "${NEO_DIR}/racecar-venv/bin/activate" ]; then
        source "${NEO_DIR}/racecar-venv/bin/activate"
        DEP_FAIL=0
        DEP_MISSING=""
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            [[ "$line" =~ ^# ]] && continue
            # Strip version pin (==, >=, <=, ~=, !=) to get the dist name.
            PKG_NAME=$(echo "$line" | sed 's/[=<>~!].*//' | xargs)
            # pip show avoids the import-name-vs-dist-name trap (opencv-python → cv2).
            if ! pip show "$PKG_NAME" > /dev/null 2>&1; then
                DEP_FAIL=$((DEP_FAIL + 1))
                DEP_MISSING="${DEP_MISSING} ${PKG_NAME}"
            fi
        done < "${SCRIPT_DIR}/requirements.txt"

        if [ $DEP_FAIL -eq 0 ]; then
            check_pass "All Python dependencies installed"
        else
            check_fail "Missing Python packages:${DEP_MISSING}"
        fi
    fi
elif [ "$FOLDER" == 'sim' ]; then
    if [ -d "${NEO_DIR}/RacecarNeo-Simulator" ]; then
        check_pass "Simulator folder exists"
    else
        check_fail "Simulator folder not found after update"
    fi
fi

# General checks (always run)
if [ -f "${SCRIPT_DIR}/.config" ]; then
    check_pass ".config file exists"
else
    check_fail ".config file not found"
fi

if [ -f "${SCRIPT_DIR}/.local_bashrc.sh" ]; then
    check_pass ".local_bashrc.sh exists"
else
    check_fail ".local_bashrc.sh not found — re-run setup.sh if needed"
fi

# Racecar tool check
if [ -f "${SCRIPT_DIR}/racecar_tool.sh" ] && [ -f "${SCRIPT_DIR}/.config" ]; then
    . "${SCRIPT_DIR}/.config"
    . "${SCRIPT_DIR}/racecar_tool.sh"
    RACECAR_TEST_OUTPUT=$(racecar test 2>&1)
    if echo "$RACECAR_TEST_OUTPUT" | grep -q "successfully"; then
        check_pass "Racecar tool is working"
    else
        check_fail "Racecar tool loaded but 'racecar test' did not report success"
    fi
else
    check_fail "Racecar tool files missing"
fi

# Log file errors (check for command failures logged by run_cmd)
LOG_ERRORS=$(grep -c "WARNING: Command exited with code" "$LOG_FILE" 2>/dev/null)
LOG_ERRORS=${LOG_ERRORS:-0}
if [ "$LOG_ERRORS" -gt 0 ]; then
    check_fail "Log file contains ${LOG_ERRORS} command failure(s) — review $LOG_FILE"
else
    check_pass "No command failures detected in log file"
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
# Update summary
# ============================================================================
UPDATE_END_TIME=$(date +%s)
UPDATE_DURATION=$((UPDATE_END_TIME - UPDATE_START_TIME))
UPDATE_MINUTES=$((UPDATE_DURATION / 60))
UPDATE_SECONDS=$((UPDATE_DURATION % 60))

log ""
echo -e "\e[1;36m========================== UPDATE SUMMARY ============================\e[0m"
echo -e "  Updated:          \e[1m${FOLDER}\e[0m"
if [ "$FOLDER" == 'labs' ]; then
    echo -e "  Curriculum:       \e[1m${CURRICULUM}\e[0m"
elif [ "$FOLDER" == 'sim' ]; then
    echo -e "  Platform:         \e[1m${PLATFORM}\e[0m"
fi
echo -e "  Install location: \e[1m${NEO_DIR}\e[0m"
echo -e "  Log file:         \e[1m${LOG_FILE}\e[0m"
echo -e "  Duration:         \e[1m${UPDATE_MINUTES}m ${UPDATE_SECONDS}s\e[0m"
echo -e "\e[1;36m======================================================================\e[0m"

log_silent "========================== UPDATE SUMMARY =============================="
log_silent "  Updated:          ${FOLDER}"
if [ "$FOLDER" == 'labs' ]; then
    log_silent "  Curriculum:       ${CURRICULUM}"
elif [ "$FOLDER" == 'sim' ]; then
    log_silent "  Platform:         ${PLATFORM}"
fi
log_silent "  Install location: ${NEO_DIR}"
log_silent "  Log file:         ${LOG_FILE}"
log_silent "  Duration:         ${UPDATE_MINUTES}m ${UPDATE_SECONDS}s"
log_silent "  Checks:           ${PASS}/${TOTAL} passed"
log_silent "======================================================================"

echo ""
echo -e "\e[1;32mRACECAR Neo Update Complete.\e[0m"

log_silent "========== UPDATE LOG END =========="
