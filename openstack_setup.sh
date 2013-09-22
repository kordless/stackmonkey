#!/bin/bash

# just so we're all clear
clear 

if [ -f ./setuprc ]
then
	echo "########################################################################################################################"
	echo;
	echo "Setup has already been run.  Edit or delete the ./setuprc file in this directory to reconfigure setup."
	echo;
	echo "########################################################################################################################"
	echo;
	exit
fi

# grab our IP 
read -p "Enter the device name for the primary NIC connected to the Internets (eth0, etc.) : " internetnic
CHEF_SERVER_IP=$(/sbin/ifconfig $internetnic| sed -n 's/.*inet *addr:\([0-9\.]*\).*/\1/p')
if [ -z "$CHEF_SERVER_IP" ]; then
  echo "No IP found on that interface!  Edit the 'openstack_setup.sh' file and add it.";
  exit;
fi
# uncomment this if you run into issues
# CHEF_SERVER_IP=10.0.1.100
echo "export CHEF_SERVER_IP="$CHEF_SERVER_IP > setuprc

# single or multi?
echo;
read -p "How many total nodes in this install? " -r
if [ $REPLY -eq $REPLY 2>/dev/null ]
then
  num_nodes=$REPLY
  echo "export NUMBER_NODES="$REPLY >> setuprc
else
  echo;
  echo "You need to enter an integer value."
  exit;
fi

# prompt for a few things we'll need for setup
for (( x=1; x<=$num_nodes; x++ ))
  do
    read -p "Enter a short hostname for node #"$x": "
    echo "export NODE_"$x"_HOSTNAME="$REPLY >> setuprc
    read -p "Enter the IP address for node #"$x" ($REPLY): "
    echo "export NODE_"$x"_IP="$REPLY >> setuprc
  done

# making a unique token for this install
if [ -a "/sbin/md5" ]
then
  token=`cat /dev/urandom | head -c2048 | md5 | cut -d' ' -f1`
else
  token=`cat /dev/urandom | head -c2048 | md5sum | cut -d' ' -f1`
fi
echo "export ROOT_PASSWD="$token >> setuprc

# source that sucker
. ./setuprc

# tack on our other variables
public_network=`echo $NODE_1_IP | cut -d"." -f1-3`
echo "export PUBLIC_NETWORK="$public_network".0" >> setuprc
echo "export PRIVATE_NETWORK=10.0.55.0" >> setuprc
echo "export BRIDGE_INTERFACE=eth0" >> setuprc

# source that sucker, again
. ./setuprc

echo;
echo "#############################################################################################################"
echo;
echo "Using the following for setup.  Edit 'setuprc' if you don't like what you see."
echo;
echo "#############################################################################################################"
echo;
cat setuprc
echo;
echo "#############################################################################################################"
echo;
echo "Setup configuration complete.  Continue the setup by doing a 'vagrant up'."
echo;
echo "#############################################################################################################"
echo;


