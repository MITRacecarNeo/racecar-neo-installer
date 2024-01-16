"""
MIT BWSI Autonomous RACECAR
MIT License
RACECAR Neo - January 2024

File Name: setup.py

Title: RACECAR Setup Python File

Author: Christopher Lai (MITLL)

Purpose: To streamline setup process for native RACECAR version.
Asks user for information about system (absolute path, IP address,
operating system), then creates configuration file, downlaods
libraries, and sets up RACECAR command in environment.
"""

import os
import subprocess

# [VARIABLES]
op_sys = 0 # Operating system for user
valid_op_sys = ["Windows", "Mac", "Linux"]
abs_path = "" # Absolute path for user
ip_addr = "" # IP Address used (127.0.0.1 default)
curr = 0 # Curriculum used (0: oneshot, 1: outreach, 2: prereq, 3: full, 4: postlabs)
valid_curr = ["oneshot", "outreach", "prereq", "full", "postlabs"]
curr_links = ["https://github.com/MITRacecarNeo/racecar-neo-oneshot-labs.git", "https://github.com/MITRacecarNeo/racecar-neo-outreach-labs.git"]

config_command = ""
tool_command = ""
lib_command = ""

while True:
    try:
        # User input validation for operating system
        op_sys = int(input("Enter operating system ID (0: Windows, 1: Mac, 2: Linux): "))
        if op_sys < 0 or op_sys > 2:
            print("Input out of bounds. Try again.")
        else:
            break
    except ValueError:
        print("Input invalid. Try again.")


ip_addr = input("Enter IP Address (leave blank if using sim): ")

# [CHECK IP]
if not ip_addr:
    ip_addr = "127.0.0.1"

print("\nCurrent RACECAR Course Listing: ")
print("0 || racecar-neo-oneshot")
print("1 || racecar-neo-outreach")
print()

# User input validation for course int listing
while True:
    try:
        curr = int(input("Enter Course ID (0-1): "))
        if curr < 0 or curr > 1:
            print("Input out of bounds. Try again.")
        else:
            break
    except ValueError:
        print("Input invalid. Try again.")

# [GENERATE ABSOLUTE PATH]
abs_path = os.path.dirname(os.path.abspath(__file__))
linux_path = os.path.dirname(abs_path)

# [USER CONFIRMATION]
print("\nIs this information correct?\n=============================")
print(f"Operating System: {valid_op_sys[op_sys]}")
print(f"IP Address: {ip_addr}")
print(f"Curriculum: racecar-neo-{valid_curr[curr]}\n")
confirm = input("Confirm (Y/N): ")
print()

# [CONFIRMATION VALID]
if confirm.lower() == "y":
    
    # Generate library command (universal)
    lib_command = f"""yes | apt-get update
yes | apt-get upgrade
yes | apt install python3-pip
yes | pip install -r {linux_path}/scripts/requirements.txt
yes | apt install jupyter-notebook
yes | apt-get install ffmpeg libsm6 libxext6 -y
yes | apt-get install dos2unix
"""
    
    # OS specific config and tool commands
    if op_sys == 0: # WINDOWS
        
        # Windows config command
        config_command = f"""echo "RACECAR_ABSOLUTE_PATH=\\"{linux_path}\\"
RACECAR_IP=\\"{ip_addr}\\"
RACECAR_TEAM=\\"student\\"
RACECAR_CONFIG_LOADED=\\"TRUE\\"
export DISPLAY=localhost:42.0" > {linux_path}/scripts/.config"""
        
        # Windows tool command
        tool_command = f"""sed '/# RACECAR_ALIASES$/d' -i ~/.bashrc
echo "# Source RACECAR tool # RACECAR_ALIASES
if [ -f {linux_path}/scripts/.config ]; then # RACECAR_ALIASES
. {linux_path}/scripts/.config # RACECAR_ALIASES
fi # RACECAR_ALIASES
if [ -f {linux_path}/scripts/racecar_tool.sh ]; then # RACECAR_ALIASES
. {linux_path}/scripts/racecar_tool.sh # RACECAR_ALIASES
fi # RACECAR_ALIASES" >> ~/.bashrc"""

    elif op_sys == 1: # MAC
        
        # Mac config command
        config_command = f"""echo "RACECAR_ABSOLUTE_PATH=\\"{linux_path}\\"
RACECAR_IP=\\"{ip_addr}\\"
RACECAR_TEAM=\\"student\\"
RACECAR_CONFIG_LOADED=\\"TRUE\\"
sudo sysctl -w net.inet.udp.maxdgram=65535" > {linux_path}/scripts/.config"""

        # Mac tool command
        tool_command = f"""sed '/# RACECAR_ALIASES$/d' -i ~/.bashrc
echo "# Source RACECAR tool # RACECAR_ALIASES
if [ -f {linux_path}/scripts/.config ]; then # RACECAR_ALIASES
. {linux_path}/scripts/.config # RACECAR_ALIASES
fi # RACECAR_ALIASES
if [ -f {linux_path}/scripts/racecar_tool.sh ]; then # RACECAR_ALIASES
. {linux_path}/scripts/racecar_tool.sh # RACECAR_ALIASES
fi # RACECAR_ALIASES" >> ~/.bashrc


sed '/# RACECAR_ALIASES$/d' -i ~/.zshrc
echo "# Source RACECAR tool # RACECAR_ALIASES
if [ -f {linux_path}/scripts/.config ]; then # RACECAR_ALIASES
. {linux_path}/scripts/.config # RACECAR_ALIASES
fi # RACECAR_ALIASES
if [ -f {linux_path}/scripts/racecar_tool.sh ]; then # RACECAR_ALIASES
. {linux_path}/scripts/racecar_tool.sh # RACECAR_ALIASES
fi # RACECAR_ALIASES" >> ~/.zshrc

$SHELL
"""

    elif op_sys == 2: # LINUX
        # Linux config command
        config_command = f"""echo "RACECAR_ABSOLUTE_PATH=\\"{linux_path}\\"
RACECAR_IP=\\"{ip_addr}\\"
RACECAR_TEAM=\\"student\\"
RACECAR_CONFIG_LOADED=\\"TRUE\\"
sudo sysctl -w net.ipv4.udp_mem=\\"65535 131071 262142\\"" > {linux_path}/scripts/.config"""

        # Linux tool command
        tool_command = f"""sed '/# RACECAR_ALIASES$/d' -i ~/.bashrc
echo "# Source RACECAR tool # RACECAR_ALIASES
if [ -f {linux_path}/scripts/.config ]; then # RACECAR_ALIASES
. {linux_path}/scripts/.config # RACECAR_ALIASES
fi # RACECAR_ALIASES
if [ -f {linux_path}/scripts/racecar_tool.sh ]; then # RACECAR_ALIASES
. {linux_path}/scripts/racecar_tool.sh # RACECAR_ALIASES
fi # RACECAR_ALIASES" >> ~/.bashrc


sed '/# RACECAR_ALIASES$/d' -i ~/.zshrc
echo "# Source RACECAR tool # RACECAR_ALIASES
if [ -f {linux_path}/scripts/.config ]; then # RACECAR_ALIASES
. {linux_path}/scripts/.config # RACECAR_ALIASES
fi # RACECAR_ALIASES
if [ -f {linux_path}/scripts/racecar_tool.sh ]; then # RACECAR_ALIASES
. {linux_path}/scripts/racecar_tool.sh # RACECAR_ALIASES
fi # RACECAR_ALIASES" >> ~/.zshrc

$SHELL
"""
   
    print("\nCreating Setup Script File...")

    script_file = f"""#!/bin/sh

{lib_command}
"""

    with open('racecar-neo-installer/racecar-student/scripts/libinstall.sh', 'w') as w:
        w.write(script_file)

    script_file = f"""#!/bin/sh
    
{config_command}

{tool_command}

dos2unix {linux_path}/scripts/racecar_tool.sh

"""

    with open('racecar-neo-installer/racecar-student/scripts/setup.sh', "w") as w:
        w.write(script_file)

    script_file = f"""#!/bin/sh

cd racecar-neo-installer/racecar-student
git clone https://github.com/MITRacecarNeo/racecar-neo-library.git
mv racecar-neo-library library
git clone {curr_links[curr]}
mv racecar-neo-{valid_curr[curr]}-labs labs
cd ..
git clone https://github.com/MITRacecarNeo/RacecarSim-{valid_op_sys[op_sys].lower()}.git
mv RacecarSim-{valid_op_sys[op_sys].lower()} RacecarSim
cd ..
mv racecar-neo-installer racecar-neo
cd racecar-neo

    """

    with open('racecar-neo-installer/racecar-student/scripts/currinstall.sh', "w") as w:
        w.write(script_file)

    print()
    confirm2 = input("[0/3] Script generation finished. Run RACECAR Library Installation Script? (Y/N): ")
    print()

    if confirm2.lower() == "y":
        subprocess.run(["sh", 'libinstall.sh'])
    else:
        print("\nAuto script running denied. To run the setup script, cd into the scripts folder using:")
        print(f"cd {linux_path}/scripts")
        print("Then run [sh libinstall.sh] in the terminal.\n")

    print()
    confirm3 = input("[1/3] Run RACECAR Setup Script? (Y/N): ")
    print()

    if confirm3.lower() == "y":
        subprocess.run(["sh", 'setup.sh'])
    else:
        print("\nAuto script running denied. To run the setup script, cd into the scripts folder using:")
        print(f"cd {linux_path}/scripts")
        print("Then run [sh setup.sh] in the terminal.\n")

    print()
    confirm4 = input("[2/3] Run RACECAR Curriculum Installation Script? (Y/N): ")
    print()

    if confirm4.lower() == "y":
        subprocess.run(["sh", 'currinstall.sh'])
    else:
        print("\nAuto script running denied. To run the setup script, cd into the scripts folder using:")
        print(f"cd {linux_path}/scripts")
        print("Then run [sh currinstall.sh] in the terminal. Goodbye.\n")

    print()
    print("[3/3] All setup menus passed. Thank you for using the RACECAR Neo installer. Goodbye.")
    print()
    
else:
    print("Setup aborted. Goodbye.")