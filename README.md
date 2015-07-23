dnsim
=====

Dynamic Neural Simulator - a modular modeling tool for large ODE models.

-------------------------------
Setup as Matlab Toolbox (Linux)
-------------------------------
1. Download DNSim
    1. Method 1 -- Download zip:
        1. web: http://infinitebrain.org/setup
        2. Click "Download DNSim toolbox"
        3. Unzip DNSim (dnjsim-toolbox_vXX.zip)
    2. Method 2 -- Use Git to download https://github.com/jsherfey/dnsim :
        - enter on the shell: `git clone https://github.com/jsherfey/dnsim.git`
    3. Either way, once done, make an environment variable for where you unzipped it
        - e.g. by entering on the shell `echo "export DNSIM=/path/to/dnsim/here" >> $HOME/.bashrc ; source $HOME/.bashrc`
2. Run DNSim
    - from the shell: `matlab -r "dnsim"`
    - from the MATLAB Command Window: `dnsim`
    - Tips:
        - if Server Portal is slow, increase MATLAB MAX_JAVA_HEAP (Preferences --> ...)
        - create alias to launch DNSim GUI
            - e.g. add to file ~/.bashrc: `alias dnsim='cd ~/dnsim; matlab -r "dnsim;"'`
        - make sure you are in the `$DNSIM` directory to load/run the toolbox in MATLAB

---------------------------------------
Setup as Standalone Application (Linux)
---------------------------------------
1. Download DNSim
    1. web: http://infinitebrain.org/setup
    2. Click "Download DNSim application"
    3. Unzip DNSim (dnsim-application_vXX.zip)
    4. Make an environment variable where you unzipped it
        - e.g. by entering on the shell `echo "export DNSIM=/path/to/dnsim/here" >> $HOME/.bashrc ; source $HOME/.bashrc`
2. Download MCR Installer
    1. web: http://www.mathworks.com/products/compiler/mcr/index.html
    2. Click the MCR download for Matlab R2013a and your operating system
    3. Install MCR
        1. Unzip MCR Installer (MCR_R2013a_XXX_installer.zip) into $DNSIM/MCRinstaller
        2. Run Installer commands:
            - Linux: run `$DNSIM/MCRinstaller/install`
            - PCs: run `$DNSIM/MCRinstaller/setup.exe`
            - Mac: run `$DNSIM/MCRinstaller/InstallForMacOSX`
        3.  See `readme.txt` for more info
3. Copy paths/environment variables given for `$LD_LIBRARY_PATH` and `$XAPPLRESDIR` to file: `$DNSIM/run_dnsim.sh`
    - to see what these environment variables' values are, enter `echo $LD_LIBRARY_PATH` into the shell
4. Run DNSim from the shell via `$DNSIM/run_dnsim.sh` or `cd $DNSIM ; ./run_dnsim.sh`
    - Tip: don't forget to replace `$DNSIM = /path/to/dnsim/here` with your own directory in your ~/.bashrc.
