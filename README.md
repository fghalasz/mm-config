#  mm configure script
i@raspberrypi:~ $ sudo apt-get install git
Reading package lists... Done
Building dependency tree       
Reading state information... Done
git is already the newest version (1:2.20.1-2+deb10u3).
0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
pi@raspberrypi:~ $ git config --global user.name "Frank Halasz"
pi@raspberrypi:~ $ git config --global user.email "frank@halasz.org"
pi@raspberrypi:~ $ ls ~/.gitconfig 
/home/pi/.gitconfig
pi@raspberrypi:~ $ mkdir mm
pi@raspberrypi:~ $ cd mm
pi@raspberrypi:~/mm $ git clone https://github.com/fghalasz/mm-config.git configure
Cloning into 'configure'...
remote: Enumerating objects: 42, done.
remote: Counting objects: 100% (42/42), done.
remote: Compressing objects: 100% (21/21), done.
remote: Total 42 (delta 11), reused 42 (delta 11), pack-reused 0
Unpacking objects: 100% (42/42), done.
pi@raspberrypi:~/mm $ cd configure
pi@raspberrypi:~/mm/configure $ ./mm-configure.sh gui

