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
mm_echo () 
{
    echo "########################################################"
    echo $1
    echo "########################################################"
}

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

#
#    Fix up git remote url for this script
#
pushd ${DIR} >/dev/null
git remote rename origin github
git remote set-url github git@github.com:fghalasz/mm-config.git
popd >/dev/null 
mm_echo "git url for this script fixed up"

#
#    Update all installed software
#
mm_echo "Updating system software"
${SUDO} apt-get -q -y update
${SUDO} apt-get -q -y dist-upgrade

#CUT
if 0

#
#    Add additonal debian packages
#
mm_echo "Installing additional Debian packages"
${SUDO} apt-get -q -y install build-essential automake autoconf libtool gettext
${SUDO} apt-get -q -y install libasound2-dev
if [ ${ROLE} = gui ]; then
    ${SUDO} apt-get -q -y install sshfs
    ${SUDO} apt-get -q -y install tcl tk
fi

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
mm_echo "WiFi disabled at startup"


#
#    Change pi user passwd
#
echo -e ".Spectra70\n.Spectra70\n" | ${SUDO} passwd pi 2>/dev/null
mm_echo "User pi password changed."

#
#    Add users as per ROLE
#
case ${ROLE} in
    gui )
        echo -e ".Spectra70\n.Spectra70\nPure Data Gui\n\n\n\n\n\n\n" \
      	        | ${SUDO} adduser -q --uid 1001  gui 2>/dev/null
	${SUDO} adduser -q gui sudo
	${SUDO} su -c "echo \"gui ALL=(ALL) NOPASSWD: ALL\" >>/etc/sudoers.d/010_others-nopasswd"
        mm_echo "Added user gui"
    ;;
esac
case ${ROLE} in
    core | gui )
        echo -e ".Spectra70\n.Spectra70\nPure Data Core\n\n\n\n\n\n\n" \
	    | ${SUDO} adduser -q --uid 1002  core 2>/dev/null 
	${SUDO} adduser -q core sudo
	${SUDO} su -c "echo \"core ALL=(ALL) NOPASSWD: ALL\" >>/etc/sudoers.d/010_others-nopasswd"
        mm_echo "Added user core"
    ;;
esac
case ${ROLE} in
    dac | gui )
        echo -e ".Spectra70\n.Spectra70\nPure Data Dac\n\n\n\n\n\n\n" \
	    | ${SUDO} adduser -q --uid 1003  dac  2>/dev/null
	${SUDO} adduser -q dac sudo
	${SUDO} su -c "echo \"dac ALL=(ALL) NOPASSWD: ALL\" >>/etc/sudoers.d/010_others-nopasswd"
        mm_echo "Added user dac"
    ;;
esac

if [ ${ROLE} = gui ]; then
    ${SUDO} su -l gui -c "${SUDO} raspi-config nonint do_boot_behaviour B4"
    mm_echo "Set auto login to gui user" 
fi

#
#    Enable ssh server and install ssh keys
#
${SUDO} systemctl enable ssh
${SUDO} systemctl start ssh
if [ -e /tmp/bazzle ]; then
    ${SUDO} rm -rf /tmp/bazzle
fi
sed -f ${FILES}/dot-ssh-utils/sedscript <${FILES}/dot-ssh-dir/xyzzy >/tmp/bazzle
install_ssh () {
    ${SUDO} cp -r ${FILES}/dot-ssh-dir /home/${1}/.ssh
    ${SUDO} rm  /home/${1}/.ssh/xyzzy
    ${SUDO} cp /tmp/bazzle /home/${1}/.ssh/id_rsa
    ${SUDO} chmod go-rwx /home/${1}/.ssh/id_rsa
    ${SUDO} chown -R ${1}:${1} /home/${1}/.ssh
}
install_ssh ${ROLE}
install_ssh pi
if [ ${ROLE} = gui ]; then
    install_ssh core
    install_ssh dac
fi
rm -rf /tmp/bazzle
mm_echo "SSH installed"

#
#    On gui only, enable x windows access for all users
#
if [ ${ROLE} = gui ]; then
    for U in pi gui core dac
    do
        ${SUDO} su -l ${U} -c "cat < ${FILES}/bashrc-xhost-adds >> /home/${U}/.bashrc"
    done
    mm_echo "xhost permissions modified"
fi

#
#    Configure git
#
if [ -e /home/pi/.gitconfig ]; then
    ${SUDO} cp /home/pi/.gitconfig /home/${ROLE}/.gitconfig
    ${SUDO} chown ${ROLE}:${ROLE} /home/${ROLE}/.gitconfig
else
    ${SUDO} su -l ${ROLE} -c "git config --global user.email \"mm@mm.com\""
    ${SUDO} su -l ${ROLE} -c "git config --global user.name \"MM Developer\""
fi
mm_echo "Git configured"



#
#   Fetch, make and install pure data
#
mm_echo "Fetching, make'ing and installing Pure Data ..."
${SUDO} su -l ${ROLE} <<EOF
cd /home/${ROLE}
mkdir -p pd
cd pd
GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no" git clone git@github.com:fghalasz/pure-data.git code
cd code
git remote rename origin github
./autogen.sh
./configure
make
EOF
cd /home/${ROLE}/pd/code
${SUDO} make install
mm_echo "... done"

#
#   Install pure data externals
#
mm_echo "Installing pure data externals ..."
${SUDO} su -l ${ROLE} <<EOF
cd /home/${ROLE}
mkdir -p pd
cd pd
mkdir -p externals
cd externals
tar -xJf ${FILES}/externals-dir.tar.xz .
EOF
mm_echo "... Done"


#
#   Fetch pure data patches
#
mm_echo "Fetching Pure Data patches ..."
${SUDO} su -l ${ROLE} <<EOF
cd /home/${ROLE}
mkdir -p pd
cd pd
GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no" git clone git@github.com:fghalasz/pd-patches.git patches
cd patches
git remote rename origin github
EOF
mm_echo "... done"

#
#   Install pure data configuration file
#
${SUDO} su -l ${ROLE} <<EOF
cp ${FILES}/pd/pdsettings-${ROLE} /home/${ROLE}/.pdsettings
mkdir -p /home/${ROLE}/.config
cp -R ${FILES}/pd/pdconfig-dir-${ROLE} /home/${ROLE}/.config/Pd
EOF
mm_echo "Pure Data configuration installed"

#
#   Fetch, make and install mm-tools
#
mm_echo "Fetching mm-tools ..."
${SUDO} su -l ${ROLE} <<END_LEVEL1
cd /home/${ROLE}
mkdir -p mm/tools
cd mm
GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no" git clone git@github.com:fghalasz/mm-tools.git tools
cd tools
git remote rename origin github
cat >>/home/${ROLE}/.bashrc <<END_LEVEL2
#
#   Add mm-tools bin to path
#
PATH=/home/${ROLE}/mm/tools/bin:\$PATH
END_LEVEL2
END_LEVEL1
mm_echo "... done"

#CUT
fi



#
#   Set hostname, locale, etc
#
${SUDO} raspi-config nonint do_wifi_country US
${SUDO} timedatectl set-timezone America/Los_Angeles
# Set up locale
${SUDO} su -l <<EOF
sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
dpkg-reconfigure --fontend=noninteractive locales
update-locale LANG=en_US.UTF-8
EOF
${SUDO} raspi-config nonint do_configure_keyboard us
${SUDO} raspi-config nonint do_hostname ${ROLE}
mm_echo "Hostname, locale, etc configured."


mm_echo "      Done with configuration"
echo " "
echo " "
echo " "
echo "???????????????????????????????????????????????????????????"
echo " "

#
#    Reboot
#

while true
do
  read -p  "Type Y<RETURN> to reboot now; N<RETURN> to reboot manually later:  " reboot
  case $reboot in
   [yY]* ) echo "OK.  Rbooting ..."
	   sudo reboot
           break;;

   [nN]* ) echo "OK, bye"
	   break;;

   * )     echo "Dude, just enter Y or N, please.";;
  esac
done
