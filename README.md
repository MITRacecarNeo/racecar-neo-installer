# racecar-neo-installer

Instructions for RACECAR Neo installation found [here](https://docs.google.com/document/d/1WnaPee1AA4GwqgW9r1K-RrU2VonvI3ZcDkW5oSuaSaY/edit#heading=h.uxbegx6o23ro)

Template repository for native RACECAR installation (Entry Point)

For Windows 10/11, macOS 10.15+ (Catalina+), and Linux (tested distros include Ubuntu 20+ & Debian 10+)

## Prerequisites

Python 3.9.7 installation

## How to install Racecar Neo

1. `cd` into the folder that you want to install your project files in
2. run the command `git clone https://github.com/MITRacecarNeo/racecar-neo-installer.git`
3. run the command `sudo python3 racecar-neo-installer/racecar-student/scripts/setup.py`
4. Follow the prompts to enter your operating system, RACECAR IP Address, and curriculum type as needed
5. Type "Y" to accept the automatic installation prompts. There should be 3 prompts. The first one (`libinstall.sh`) may take a while depending on your internet speed. (~15 minutes)
6. Done!

## What does the racecar-neo-installer do?

racecar-neo-installer is a flexible and efficient way of installing the RACECAR Neo software onto your computer. The repository only contains a `scripts` folder inside a template `racecar-student` folder. Upon cloning the folder into your computer and running the `setup.py` script, the compiler will ask you to input your computer's **operating system, RACECAR IP address, and curriculum type**.

Then, it will run through a series of **python library dependency installations**, **bash alias scripts**, and **git clone commands** to set up the Racecar Neo installation to your unique specifications.

Since the installation process slightly varies between operating systems and types of RACECAR curriculum, the installer strives to simplify the setup process (making it less painful to go through), and make the course more accessible to those with less technical experience.

## Legacy Information

RACECAR Neo is based on RACECAR-MN (Model Neo), the course version supported between the years of 2019-2022. RACECAR-MN development is no longer ongoing and is considered to be deprecated. More on RACECAR-MN and the outdated installation process can be found here: [RACECAR-MN Installation](https://mitll-racecar-mn.readthedocs.io/en/latest/gettingStarted/computerSetup.html#)
