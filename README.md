dnsim
=====

Dynamic Neural Simulator - a modular modeling tool for large ODE models.

------------------------------------
Setup standalone DNSim app on Linux:
1) unzip dnsim-application_vXX.zip
2) download and run MCR Installer (for Matlab 2013a and your operating system)
   - download from http://www.mathworks.com/products/compiler/mcr/index.html
   - see readme.txt for more info
3) copy LD_LIBRARY_PATH and XAPPLRESDIR paths from MCRinstaller into run_dnsim.sh and save

Run DNSim:
./run_dnsim.sh

------------------------------------
Setup DNSim Matlab toolbox on Linux:
1) Download (two options)
  - dnsim-toolbox_vXX.zip at http://infinitebrain.org/setup
  - git clone github.com:/jsherfey/dnsim.git
2) Run DNSim (two options)
  - from shell: matlab -r "dnsim"
  - from Matlab prompt: dnsim;

----------------------------------------------------------------
Setup as Matlab Toolbox (Linux)
----------------------------------------------------------------
Download DNSim
Method 1 (download zip):
web: http://infinitebrain.org/setup
Click "Download DNSim toolbox"
Unzip DNSim (dnsim-toolbox_vXX.zip) in DNSIM=/path/to/dnsim
Method 2 (use Git):
git clone github.com:/jsherfey/dnsim.git

Running DNSim:
matlab -r "dnsim"

Tip: if Server Portal is slow, increase Matlab MAX_JAVA_HEAP (Preferences --> ...).
Tip: create alias to launch DNSim GUI
     e.g. edit ~/.bashrc: alias dnsim='cd ~/dnsim; matlab -r "dnsim"'

----------------------------------------------------------------
Setup as Standalone Application (Linux)
----------------------------------------------------------------
Download DNSim
web: http://infinitebrain.org/setup
Click "Download DNSim application" (save to DNSIM=/path/to/dnsim)
Unzip DNSim (dnsim-application_vXX.zip) in DNSIM
Download MCR Installer
web: http://www.mathworks.com/products/compiler/mcr/index.html
Click the MCR download for Matlab R2013a and your operating system
Install MCR
Unzip MCR Installer (MCR_R2013a_XXX_installer.zip) in DNSIM/MCRinstaller
Run Installer
Run commands -- Unix: ./install. PCs: setup.exe. Mac: InstallForMacOSX
At end of installation, copy paths given for LD_LIBRARY_PATH and XAPPLRESDIR to file: DNSIM/run_dnsim.sh

Running DNSim:
cd DNSIM
./run_dnsim.sh

Note: don't forget to replace DNSIM = /path/to/dnsim with your own directory.

----------------------------------------------------------------
Quick Start Guide
----------------------------------------------------------------
...
