# racecar-neo-installer

Instructions for RACECAR Neo installation found [here](https://docs.google.com/document/d/1WnaPee1AA4GwqgW9r1K-RrU2VonvI3ZcDkW5oSuaSaY/edit#heading=h.uxbegx6o23ro)

Template repository for native RACECAR installation (Entry Point)

For Windows 10/11 (through WSL2), macOS, and Linux (Ubuntu 20.04+)

## Prerequisites

- **Windows:** WSL2 with an Ubuntu distribution. Run every command below in the **WSL (Ubuntu) terminal**, not PowerShell or Command Prompt.
- **macOS:** an administrator account (setup installs Homebrew and the Xcode Command Line Tools if they are missing).
- **Linux:** Ubuntu with `sudo` access (setup installs Python 3.9 from the deadsnakes PPA).
- `git`, to clone this repository.

You do **not** need to install Python yourself. `setup.sh` installs Python 3.9 and creates a dedicated virtual environment (`racecar-venv`) with all of the RACECAR Python dependencies from `racecar-student/scripts/requirements.txt`.

## How to install Racecar Neo

1. `cd` into the folder that you want to install your project files in (on Windows, a folder in your WSL home directory, such as `~`)
2. run the command `git clone https://github.com/MITRacecarNeo/racecar-neo-installer.git`
3. run the command `bash racecar-neo-installer/racecar-student/scripts/setup.sh`
    - Follow the prompts to select your operating system (`windows`, `mac`, or `linux`) and your course curriculum (`oneshot`, `outreach`, `prereq`, or `mites`)
    - Wait ~15 minutes as the libraries and dependencies install. You may be asked for your password.
    - Review the post-setup checks at the end. A setup log is saved in `racecar-student/scripts/.logs/`.
4. Close and re-open your terminal (or run `source ~/.bashrc`, or `source ~/.zshrc` on macOS). This activates `racecar-venv` and loads the `racecar` command.
5. Verify the installation:
    - run `racecar test` to check that the racecar tool is set up
    - run `racecar open_sim` to launch the simulator, then run `racecar cd` and `racecar sim demo.py` to run a program in it

Run `racecar help` for the full list of commands.

> **Do not re-run `setup.sh` on an existing installation.** It will stop if it detects one. To reinstall, delete the entire `racecar-neo-installer` folder and start again from step 2.

## Updating an existing installation

Run `bash racecar-neo-installer/racecar-student/scripts/update.sh` and choose what to update:

- `labs`: replaces your labs folder with a fresh copy for your curriculum (back up your work first!)
- `library`: replaces the RACECAR library and reinstalls the Python dependencies
- `sim`: replaces the simulator
- `scripts`: updates the installer scripts (including the `racecar` tool) while keeping your configuration

If your copy of `update.sh` does not offer `scripts` yet, update the scripts folder once with git from the `racecar-neo-installer` folder:

```bash
git fetch origin main
git checkout origin/main -- racecar-student/scripts
```

After updating the scripts, close and re-open your terminal to load the new `racecar` tool.

## Windows (WSL) notes

- The simulator is installed on the Windows drive at `%USERPROFILE%\RacecarNeo-Simulator` (Windows cannot load the simulator's DLLs from a WSL path). `racecar-neo-installer/RacecarNeo-Simulator` is a link to that folder.
- **No Windows Firewall rule is needed.** In WSL2's default (NAT) networking mode, `racecar sim` automatically starts a small relay that carries simulator traffic between WSL and Windows. Set `RACECAR_SIM_RELAY=0` to turn the relay off.
- Run simulator programs with `racecar sim`. Running a lab directly with `python3 lab.py -s` (or VS Code's Run button) skips the relay, and camera labs may freeze.
- If the simulator will not connect, run `python3 racecar-neo-installer/racecar-student/scripts/diagnose.py` and share its output with your instructor.

## What does the racecar-neo-installer do?

racecar-neo-installer is a flexible and efficient way of installing the RACECAR Neo software onto your computer. The repository only contains a `scripts` folder inside a template `racecar-student` folder. Upon cloning the folder into your computer and running the `setup.sh` script, the installer will ask you to input your computer's **operating system and curriculum type**.

Then, it will **clone the simulator, library, and labs** for your platform and curriculum, **install Python 3.9 and the RACECAR Python dependencies** into a virtual environment (`racecar-venv`), and **add the `racecar` command** to your shell, setting up the Racecar Neo installation to your unique specifications.

Since the installation process slightly varies between operating systems and types of RACECAR curriculum, the installer strives to simplify the setup process (making it less painful to go through), and make the course more accessible to those with less technical experience.

## Legacy Information

RACECAR Neo is based on RACECAR-MN (Model Neo), the course version supported between the years of 2019-2022. RACECAR-MN development is no longer ongoing and is considered to be deprecated. More on RACECAR-MN and the outdated installation process can be found here: [RACECAR-MN Installation](https://mitll-racecar-mn.readthedocs.io/en/latest/gettingStarted/computerSetup.html#)
