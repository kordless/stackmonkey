## Installing OpenStack Grizzly in 10 Minutes
The [OpenStack](http://www.openstack.org/software/) project provides a way to turn bare metal servers into a private cloud. It's been over a year since I published the first [Install OpenStack in 10 Minutes](http://www.stackgeek.com/guides/gettingstarted.html) guide and now, nearly 10K installs later, I'm pleased to announce the quickest and easiest way yet to get an OpenStack cluster running.

Before we drop into the guide, I'd like to thank [Blue Chip Tek](http://bluechiptek.com) for providing hardware, advice and setup assistance, [Dell Computers](http://dell.com/) for donating the test hardware, and the awesome folks at [Rackspace](http://rackspace.com/) for writing and supporting the [Chef scripts](https://github.com/rcbops/chef-cookbooks) which are used for the bulk of the setup process.

The scripts provided in this guide build a Chef server inside a [Vagrant box](http://vagrantup.com/), which ends up acting as a sort of 'raygun' to blast OpenStack onto the nodes.  Everyone knows [rayguns](https://www.google.com/search?q=raygun&safe=off) are awesome.

### Prerequisites for Install
The new install scripts are [available for download](https://github.com/bluechiptek/bluechipstack) from BlueChip's Github account.  It is recommended you familiarize yourself with the install process by watching the screencast below.

[![ScreenShot](https://raw.github.com/bluechiptek/bluechipstack/master/openstack_movie.png)](http://vimeo.com/73001135)

Before you start, make sure you have a minimum of one bare metal node running [Ubuntu Server 12.04](http://www.ubuntu.com/download/server).  If you are installing on more than one node, make sure all the nodes are on the [same private IP block](http://en.wikipedia.org/wiki/Private_network) and are able to talk to each other before proceeding.  All nodes will need Internet access via NAT provided by a DHCP server/router.


### Download the Install Scripts
Log into the first node of your cluster using *ssh*.  If you are doing a single node deployment of OpenStack, simply log into that node with *ssh*.  

*Note: These instructions also work if you use a dedicated Chef server which will not be part of the OpenStack cluster.*

Start the install by making sure you have *git* installed:

    sudo apt-get -y install git

Now make a directory in your home directory called *openstack*:    

    mkdir openstack; cd openstack
    
Next, clone the scripts from the repo:

    git clone https://github.com/bluechiptek/bluechipstack.git
    
Now move into the scripts directory and take a gander at the scripts:

    cd bluechipstack; ls

### Install VirtualBox + Vagrant
The scripts will build a Vagrant image which will run the Chef server used to provision the nodes for the OpenStack deployment.  Before we can build the image, you need to run a small script which downloads and installs [VirtualBox](https://www.virtualbox.org/) and [Vagrant](http://www.vagrantup.com/).

    ./openstack_vagrant_install.sh
    
If anything goes wrong with the install, you may follow the manual instructions pulled from [Digital Ocean's guide on installing Vagrant on Ubuntu 12.04](https://www.digitalocean.com/community/articles/how-to-install-vagrant-on-a-vps-running-ubuntu-12-04).
    
### Create the Setup File
The setup script provided in the repository will prompt you for a few variables, including the number of nodes for the cluster, the node IPs and names, and the network you'll be using for instances.  Start the setup script by typing the following:

    ./openstack_setup.sh
    
Once the setup script finishes, you will have a *setuprc* file that will look something like this:

    export CHEF_SERVER_IP=10.0.1.73
    export NUMBER_NODES=3
    export NODE_1_HOSTNAME=nero
    export NODE_1_IP=10.0.1.73
    export NODE_2_HOSTNAME=spartacus
    export NODE_2_IP=10.0.1.93
    export NODE_3_HOSTNAME=invictus
    export NODE_3_IP=10.0.1.94
    export ROOT_PASSWD=af5b015ab50472e2368cdef95dfda120
    export PUBLIC_NETWORK=10.0.1.0
    export PRIVATE_NETWORK=10.0.55.0
    export BRIDGE_INTERFACE=eth0
    
Before you continue with the install, double check the network interface names on your nodes:

	kord@nero:~$ ifconfig -a |grep Ethernet
	br100     Link encap:Ethernet  HWaddr d4:3d:7e:33:f7:31  
	eth0      Link encap:Ethernet  HWaddr d4:3d:7e:33:f7:31  
    
If your primary interface name is different than **eth0**, be sure to edit the *setuprc* file and change the **BRIDGE_INTERFACE** value to the correctly named interface.  Things will go horribly wrong later with routing if you don't do this now!
    
### Provision the Chef Server
The Chef server is built and started by the Vagrant manager and should take 5-10 minutes to build on a fast box and connection.  Start the server by typing:

    vagrant up
    
*Note: If you have multiple network interfaces on your node, you will be prompted to choose one for the bridge that is created for the Vagrant server.*

Once the Chef server is provisioned, ssh into it:

    vagrant ssh

Once you are logged into the server, become root and change into the *bluechipstack* directory:

    sudo su
    cd /root/bluechipstack
    
Now run the install script to print out the node configuration commands:

    ./openstack_install.sh
    
### Configuring the Nodes
You will need to do some manual configuration of your nodes now.  The install script you just ran will dump out instructions and commands you can use to cut and paste and save time.

**1. Begin by setting a temporary root password on each node:**

    root@chef-server# ssh user@hostname
    user@hostname$ sudo passwd root	
    [sudo] password for user: 
	Enter new UNIX password: 
	Retype new UNIX password: 
	passwd: password updated successfully
    user@hostname$ exit
    ...
    
You will need to replace the **user** and **hostname** appropriate for your nodes and repeat these steps for each and every node you specified in the setup.  For each node, you will be prompted for your user password twice and the new root password twice.

*Note: The scripts will take care of disabling the temporary root password after the keys are installed.*

**2. Next, push the root key to each node from the Chef server:**

    ssh-copy-id root@hostname
    ... 

As above, you will need to replace **hostname** with the node's actual hostname and then repeat this for each and every node in your cluster.  You will be prompted by the nodes for the root password you set in step 1 above.

### Delopy the Nodes
The deploy script installs the Chef client on all the nodes you specified in the *setuprc* file.  After the deploy script is done, manually running the chef-client command kicks off the install of OpenStack.  Start the install of the client by typing the following from the Chef server:

    ./openstack_deploy.sh

Once the deployment script completes, ssh to each node and manually run the Chef client command:

    root@chef-server# ssh root@hostname
    root@hostname# chef-client
    ...
    
As you did earlier, replace **hostname** here with the actual hostname of each node.  Repeat this for each and every node in your cluster.  **You may run these commands simultaneously on all nodes to speed up the install process.**

The first node in your cluster will be configured as an all-in-one controller.  This node will host the database for OpenStack, provide authentication, host the web UI, and perform network coordination.  The all-in-one node will also serve as a nova-compute node.  If you have more than one node in your cluster, the remainder of the nodes will be deployed as nova-compute nodes.

### Starting Instances
Once the all-in-one node is provisioned, you should be able to log into the web UI for OpenStack.  Enter the IP address of the all-in-one node, which should be the **NODE_1_IP** variable in your Chef server environment:

    http://10.0.1.73
                
The default user for the web UI is **admin** and the default password is **secrete**.

You can refer to the [video guide](http://vimeo.com/41807514) for getting started using the UI.

### Tweaking Configuration
If you have any specific configuration you need to perform on your boxes, for example changing the contents of the nova.conf, then that can be done by modifying the recipes which were downloaded to your machine during setup.

    cd /root/chef-cookbooks/cookbooks

The config options are normally set in the attributes/default.rb file located inside the specific cookbooks. For example, to configure specific options involving nova you would edit the nova cookbook attributes file located at:

    nano /root/chef-cookbooks/cookbooks/nova/attributes/default.rb

From there you can configure specific options, for example if your machines do not support hardware virtualization you would change the virt_type setting:

    default["nova"]["libvirt"]["virt_type"]

Once you are done making changes to the server attributes you must then apply these changes before they will push out to the nodes:

    knife cookbook upload *modified-cookbook-name-here* -o /root/chef-cookbooks/cookbooks

If you edited multiple cookbooks and don't feel like specifying them one-by-one, you can simply re-upload the whole directory:

    knife cookbook upload -a -o /root/chef-cookbooks/cookbooks

Once you have finished applying the changes you can either wait for the servers to phone home and download the changes, or you can run the chef client command on each box via ssh.

    chef-client --once

### Troubleshooting
If anything goes wrong with the install, be sure to ask for help.  The easiest way to get help is to [post in the forums](https://groups.google.com/forum/?fromgroups#!category-topic/stackgeek/openstack/_zbeGoOBg-Q).  Here are a few simple suggestions you can try:

**1. If the Vagrant provisioning of the Chef server fails, re-run the provision script from the Vagrant box:** 
    
    user@nero$ vagrant ssh
    vagrant@chef-server$ sudo su
    root@chef-server# rm -rf /root/chef-cookb
    root@chef-server# cd /root/bluechipstack/
    root@chef-server# ./openstack_provision.sh
    
**2. Check you can ping your nodes by name from the Chef server:**

    root@chef-server# ping nero
	64 bytes from nero (10.0.1.100): icmp_req=1 ttl=64 time=0.463 ms
	^C
	--- nero ping statistics ---
	1 packets transmitted, 1 received, 0% packet loss, time 0ms
	rtt min/avg/max/mdev = 0.463/0.463/0.463/0.000 ms

**3. Check you can ping your Chef server by name from a node:**

	root@chef-server# ssh nero 
	root@nero# ping chef-server
	PING chef-server (10.0.1.57) 56(84) bytes of data.
	64 bytes from chef-server (10.0.1.57): icmp_req=1 ttl=64 time=0.455 ms
	^C
	--- chef-server ping statistics ---
	1 packets transmitted, 1 received, 0% packet loss, time 0ms
	rtt min/avg/max/mdev = 0.455/0.455/0.455/0.000 ms
	
**4. Check you can remotely execute commands on the nodes from the Chef server:**

    root@chef-server# ssh nero uptime
    09:59:04 up 12 days, 15:04,  0 users,  load average: 0.10, 0.14, 0.14

**5. See what nodes Chef knows about:**
	
	root@chef-server# knife node list
	invictus
	nero
	spartacus
 
**6. Run a sync on the environment for the nodes:**

    root@chef-server# knife exec -E 'nodes.transform("chef_environment:_default") { |n| n.chef_environment("grizzly") }'

**7. Re-run the chef-client on each node:**

    root@chef-server# ssh nero
    root@nero# chef-client

**8. Check the OpenStack services are running normally:**

    root@nero:~# nova-manage service list
	Binary           Host                       Zone             Status     State Updated_At
	nova-scheduler   nero                       internal         enabled    :-)   2013-08-23 17:10:45
	nova-conductor   nero                       internal         enabled    :-)   2013-08-23 17:10:49
	nova-cert        nero                       internal         enabled    :-)   2013-08-23 17:10:48
	nova-consoleauth nero                       internal         enabled    :-)   2013-08-23 17:10:48
	nova-network     nero                       internal         enabled    :-)   2013-08-23 17:10:48
	nova-compute     nero                       nova             enabled    :-)   2013-08-23 17:10:49
	nova-network     invictus                   internal         enabled    :-)   2013-08-23 17:10:51
	nova-compute     invictus                   nova             enabled    :-)   2013-08-23 17:10:47
	nova-network     spartacus                  internal         enabled    :-)   2013-08-23 17:10:52
	nova-compute     spartacus                  nova             enabled    :-)   2013-08-23 17:10:49
















                
