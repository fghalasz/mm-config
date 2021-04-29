#!/bin/bash
#
#    Configuration script for MusicMachine Raspberry Pis
#
#    FGH 2021-04-28
#
#

#
#    Defines
#
SUDO=/usr/bin/sudo


#
#    Check args
#
if [ $# -ne 1 ]; then
    echo "Usage: $0 <ROLE>"
    echo "Where <ROLE> is one of gui, core, or dac"
    exit 1
fi
case $1 in
    gui|core|dac)
    ;;
    *)
        echo "Unknown role: " $1
	echo "Usage: $0 <ROLE>"
        echo "Where <ROLE> is one of gui, core, or dac"
        exit 1
    ;;
esac
ROLE=$1


#
#   Check for files
#
pushd $(dirname ${BASH_SOURCE}) >/dev/null
DIR=$(pwd)
popd >/dev/null
FILES=${DIR}/files
if [ -e ${FILES} ]; then
    echo "Files directory found"
else
    echo "Error: cannot find files subdirectory"
    echo "Exiting"
    exit 1
fi

#CUT
if false; then
#
#    Update all installed software
#
echo "Updating system software"
${SUDO} apt-get -q -y update
${SUDO} apt-get -q -y dist-upgrade

#
#    Add additonal debian packages
#
echo "Installing additional Debian packages"
${SUDO} apt-get  -q -y install build-essential automake autoconf libtool gettext
${SUDO} apt-get  -q -y install libasound2-dev

#
#   Disable WiFi at startup
#
if [ -e /tmp/bazzle ]; then
    ${SUDO} rm -rf /tmp/bazzle
fi
${SUDO} crontab -l >/tmp/bazzle
${SUDO} grep wlan0 /tmp/bazzle
if [ $? -ne 0 ]; then
    echo "@reboot sleep 15s && /usr/sbin/ifconfig wlan0 down" | ${SUDO} cat >>/tmp/bazzle
    ${SUDO} crontab /tmp/bazzle
fi
${SUDO} rm -rf /tmp/bazzle
echo "WiFi disabled at startup"


#
#    Change pi user passwd
#
echo -e ".Spectra70\n.Spectra70\n" | ${SUDO} passwd pi 2>/dev/null
echo "User pi password changed."

#
#    Add users as per ROLE
#
case ${ROLE} in
    gui )
        echo -e ".Spectra70\n.Spectra70\nPure Data Gui\n\n\n\n\n\n\n" \
      	        | ${SUDO} adduser -q --uid 1001  gui 2>/dev/null
	${SUDO} adduser -q gui sudo
	${SUDO} su -c "echo \"gui ALL=(ALL) NOPASSWD: ALL\" >>/etc/sudoers.d/010_others-nopasswd"
        echo "Added user gui"
    ;;
esac
case ${ROLE} in
    core | gui )
        echo -e ".Spectra70\n.Spectra70\nPure Data Core\n\n\n\n\n\n\n" \
	    | ${SUDO} adduser -q --uid 1002  core 
	${SUDO} adduser -q core sudo
	${SUDO} su -c "echo \"core ALL=(ALL) NOPASSWD: ALL\" >>/etc/sudoers.d/010_others-nopasswd"
        echo "Added user core"
    ;;
esac
case ${ROLE} in
    dac | gui )
        echo -e ".Spectra70\n.Spectra70\nPure Data Dac\n\n\n\n\n\n\n" \
	    | ${SUDO} adduser -q --uid 1003  dac 
	${SUDO} adduser -q dac sudo
	${SUDO} su -c "echo \"dac ALL=(ALL) NOPASSWD: ALL\" >>/etc/sudoers.d/010_others-nopasswd"
        echo "Added user dac"
    ;;
esac

if [ ${ROLE} = gui ]; then
    ${SUDO} su -l gui -c "${SUDO} raspi-config nonint do_boot_behaviour B4"
    echo "Set auto login to gui user" 
fi

#
#    Enable ssh server and install ssh keys
#
if [ -e /tmp/bazzle ]; then
    ${SUDO} rm -rf /tmp/bazzle
fi
sed -f ${FILES}/dot-ssh-dir/sedscript <${FILES}/dot-ssh-dir/xyzzy >/tmp/bazzle
${SUDO} systemctl enable ssh
${SUDO} systemctl start ssh
${SUDO} cp -r ${FILES}/dot-ssh-dir /home/${ROLE}/.ssh
${SUDO} rm  /home/${ROLE}/.ssh/xyzzy
${SUDO} cp /tmp/bazzle /home/${ROLE}/.ssh/id_rsa
${SUDO} chmod go-rwx /home/${ROLE}/.ssh/id_rsa
${SUDO} chown -R ${ROLE}:${ROLE} /home/${ROLE}/.ssh
if [ ${ROLE} = gui ]; then
    ${SUDO} cp -r ${FILES}/dot-ssh-dir /home/core/.ssh
    ${SUDO} rm  /home/core/.ssh/xyzzy
    ${SUDO} cp /tmp/bazzle /home/core/.ssh/id_rsa
    ${SUDO} chmod go-rwx /home/core/.ssh/id_rsa
    ${SUDO} chown -R core:core /home/core/.ssh
    ${SUDO} cp -r ${FILES}/dot-ssh-dir /home/dac/.ssh
    ${SUDO} rm  /home/dac/.ssh/xyzzy
    ${SUDO} cp /tmp/bazzle /home/dac/.ssh/id_rsa
    ${SUDO} chmod go-rwx /home/dac/.ssh/id_rsa
    ${SUDO} chown -R dac:dac /home/dac/.ssh
fi
rm -rf /tmp/bazzle
echo "SSH installed"
#CUT
fi

#
#    On gui only, enable x windows access for all users
#
if [ ${ROLE} = gui ]; then
    for U in pi gui core dac
    do
        ${SUDO} su -l ${U} -c "cat < ${FILES}/bashrc-xhost-adds >> /home/${U}/.bashrc"
    done
    echo "xhost permissions modified"
fi

#
#    Configure git
#
if [ -e /home/pi/.gitconfigure ]; then
	${SUDO} cp /home/pi/.gitconfigure /home/${ROLE}/.gitconfigure
	${SUDO} chown ${ROLE}:${ROLE} /home/${ROLE}/.gitconfigure
fi
echo "Git configured"



#
#   Fetch, make and install pure data
#
echo "Fetching, make'ing and installing Pure Data ..."
${SUDO} su -l ${ROLE} <<EOF
cd /home/${ROLE}
mkdir -p pd
cd pd
git clone git@github.com:fghalasz/pure-data.git code
cd code
git remote rename origin github
./autogen.sh
./configure
make
EOF
cd /home/${ROLE}/pd/code
${SUDO} make install
echo "... done"

#
#   Install pure data externals
#
echo "Installing pure data externals"
${SUDO} su -l ${ROLE} <<EOF
cd /home/${ROLE}
mkdir -p pd
cd pd
mkdir -p externals
cd externals
tar -xJf ${FILES}/externals-dir.tar.xz .


#
#   Fetch pure data patches
#
echo "Fetching Pure Data patches ..."
${SUDO} su -l ${ROLE} <<EOF
cd /home/${ROLE}
mkdir -p pd
cd pd
git clone git@github.com:fghalasz/pd-patches.git patches
cd patches
git remote rename origin github
EOF
echo "... done"

#
#   Install pure data configuration file
#
${SUDO} su -l ${ROLE} <<EOF
cp ${FILES}/pd/pdsettings-${ROLE} /home/${ROLE}/.pdsettings
mkdir -p /home/${ROLE}/.config
cp -R ${FILES}/pd/pdconfig-dir-${ROLE} /home/${ROLE}/.config/Pd

#
#   Fetch, make and install mm-tools
#
echo "Fetching mm-tools ..."
${SUDO} su -l ${ROLE} <<END_LEVEL1
cd /home/${ROLE}
mkdir -p mm/tools
cd mm
git clone git@github.com:fghalasz/mmm-tools.git tools
cd tools
git remote rename origin github
cat >>/home/${ROLE}/.bashrc <<END_LEVEL2
#
#   Add mm-tools bin to path
#
PATH=/home/${ROLE}/mm/tools/bin:\$PATH
END_LEVEL2
END_LEVEL1
echo "... done"

echo "-----------------------------------------------------------"
echo "      Done with configuration"
echo "-----------------------------------------------------------"


#
#   Set hostname, locale, etc
#
${SUDO} raspi-config nonint do_wifi_country US
${SUDO} timedatectl set-timezone America/Los_Angeles
locale=en_US.UTF-8
layout=us
${SUDO} raspi-config nonint do_change_locale $locale
${SUDO} raspi-config nonint do_configure_keyboard $layout
${SUDO} raspi-config nonint do_hostname ${ROLE}
echo "Hostname, locale, etc configured."


#
#    Reboot
#

while true
do
  read -p "Type Y to reboot now; N to reboot manually later" reboot
  case $reboot in
   [yY]* ) 
	   sudo reboot
           break;;

   [nN]* ) break;;

   * )     echo "Dude, just enter Y or N, please.";;
  esac
done
