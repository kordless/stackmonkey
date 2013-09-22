#!/bin/bash

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "You need to be 'root' dude." 1>&2
   exit 1
fi

# just so we're all clear
clear 

# install vagrant + virtualbox
sudo apt-get -y update 
sudo apt-get -y install dpkg-dev virtualbox-dkms
wget http://files.vagrantup.com/packages/db8e7a9c79b23264da129f55cf8569167fc22415/vagrant_1.3.3_x86_64.deb
sudo dpkg -i vagrant_1.3.3_x86_64.deb
sudo apt-get -y install linux-headers-$(uname -r)
sudo dpkg-reconfigure virtualbox-dkms

echo "##########################################################################################################################"
echo;
echo "Vagrant and VirtualBox install complete.  Now run './openstack_setup.sh'."
echo;
echo "##########################################################################################################################"
