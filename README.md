Instructions for configuring the 3 RPis for the MM

1.  Gui RPi

Use the NOOBs app or the RPi Imager to install "Raspberry Pi OS Desktop" (the plain Desktop version, not the
"Full" one that includes the recommended apps) on the SD Card.

The RPi will reboot, automatically login, and start a "new install" script.  Complete this script including
going ahead with updating the software.  If you have the RPi connected to wired ethernet, you can click 
"skip" on the WiFi setup.  Restart (reboot) the RPi once the new install script finishes.

After the reboot finishes, open a terminal window as execute the following commands in the terminal:

	git config --global user.name "<Your Name>"
    git config --global user.email "<Your email>"
    mkdir mm
    cd mm
    git clone https://github.com/fghalasz/mm-config.git configure
    cd configure
    ./mm-config.sh gui

The mm-config script will run.  It will take about 10-15 minutes and produce lots of output.
When its done, select "Y" to reboot the Rpi.

The RPi will reboot and automatically login under the "gui" user account.

The GUI machine is ready to go.   All passwords have been set to ".Spectra70".


2.   The Core and Dac RPis

Use the NOOBs app or the RPi Imager to install "Raspberry Pi OS Lite" (ie, the No-Desktop version) on the SD Card.  

When the Rpi comes up, it will boot into the console.  Login (user:pi, password: raspberry).
Note that the keyboard might be a little funky until the config script is finished.  On my keyboard,
the '@' key was swapped with the '"' (double quote) key.  Makes typing in some of the commands below a
little weird.

Execute the following commands in the console:

	sudo apt-get update
    sudo apt-get -y install git
	git config --global user.name "<Your Name>"
    git config --global user.email "<Your email>"
    mkdir mm
    cd mm
    git clone https://github.com/fghalasz/mm-config.git configure
    cd configure
    ./mm-config.sh <dac|core>  -- depending on which machine you are setting up

The mm-config script will run.  It will take about 10-15 minutes and produce lots of output.
When its done, select "Y" to reboot the Rpi.
  
The RPi will reboot back to the console.  The machine is now ready to go.  No need to login
since you'll be accessing these RPis via ssh from the gui RPi.  But if you want to login, the
"main" user account will be dac (or core) with password ".Spectra70".  The pi user also exists but
its password will also be ".Spectra70".

To access the dac/core RPis, open a terminal window on the gui machine and type: "ssh dac@dac.local" or
"ssh core@core.local".  This should log you into the dac/core RPi automatically. 




