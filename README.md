# racecar-neo-installer

Instructions for RACECAR Neo installation found [here](https://docs.google.com/document/d/1WnaPee1AA4GwqgW9r1K-RrU2VonvI3ZcDkW5oSuaSaY/edit#heading=h.uxbegx6o23ro)

Template repository for native RACECAR installation (Entry Point)

For Windows 10/11, macOS 10.15+ (Catalina+, >2020), and Linux (tested distros include Ubuntu 20+ & Debian 10+)

## Prerequisites

Python 3.9.7 installation

## How to install Racecar Neo

1. `cd` into the folder that you want to install your project files in
2. run the command `git clone https://github.com/MITRacecarNeo/racecar-neo-installer.git`
3. run the command `bash racecar-neo-installer/racecar-student/scripts/setup.sh`
    - Follow the prompts to enter your operating system and curriculum type per your course
    - Wait ~15 minutes as the libraries and dependencies install.
    - Close and re-open your terminal window after the installation is complete
4. run the command `pip3 install -r racecar-neo-installer/racecar-student/scripts/requirements.txt` to install dependencies.
5. run `racecar test` and `racecar sim demo.py` to verify installation is successful

## What does the racecar-neo-installer do?

racecar-neo-installer is a flexible and efficient way of installing the RACECAR Neo software onto your computer. The repository only contains a `scripts` folder inside a template `racecar-student` folder. Upon cloning the folder into your computer and running the `setup.sh` script, the compiler will ask you to input your computer's **operating system and curriculum type**.

Then, it will run through a series of **python library dependency installations**, **bash alias scripts**, and **git clone commands** to set up the Racecar Neo installation to your unique specifications.

Since the installation process slightly varies between operating systems and types of RACECAR curriculum, the installer strives to simplify the setup process (making it less painful to go through), and make the course more accessible to those with less technical experience.

## Legacy Information

RACECAR Neo is based on RACECAR-MN (Model Neo), the course version supported between the years of 2019-2022. RACECAR-MN development is no longer ongoing and is considered to be deprecated. More on RACECAR-MN and the outdated installation process can be found here: [RACECAR-MN Installation](https://mitll-racecar-mn.readthedocs.io/en/latest/gettingStarted/computerSetup.html#)
