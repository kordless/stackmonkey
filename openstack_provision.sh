#!/bin/bash 

# disable that stupid locale error
sed '/SendEnv LANG LC_*/d' /etc/ssh/ssh_config > /tmp/ssh_config.tmp
cp /tmp/ssh_config.tmp /etc/ssh/ssh_config

# install git and curl
apt-get -y install git;
apt-get -y install curl;

# checkout scripts again to the chef server and copy config file over 
git clone https://github.com/kordless/stackmonkey.git /root/bluechipstack/;
cp /vagrant/setuprc /root/bluechipstack/;

# install chef server 
cat /root/bluechipstack/openstack_chef_server.sh | bash;

# generate a key for pushing to nodes
ssh-keygen -N "" -f /root/.ssh/id_rsa

# add path for knife
echo "export PATH=$PATH:/opt/chef-server/bin/" >> /root/.bashrc

# patch up the /etc/hosts file that chef chews all over 
sed '1,2d' /etc/hosts > /tmp/hosts
echo '10.0.2.15       chef-server precise64' >> /tmp/hosts
echo '127.0.0.1       localhost' >> /tmp/hosts
cp /tmp/hosts /etc/hosts

# now install rackspace cookbooks  (requires changes to /etc/hosts above)
curl -s -L https://raw.github.com/rcbops/support-tools/master/chef-install/install-cookbooks.sh | bash;

# shout out to the user
echo "=========================================================="
echo "Vagrant Chef server provisioning is complete."
echo;
echo "Type the following to continue:"
echo "1. 'vagrant ssh' to connect to the Chef server."
echo "2. 'sudo su' to become root on the Chef server."
echo "3. 'cd /root/bluechipstack/' to change directories."
echo "4. './openstack_install.sh' to resume install."
echo "=========================================================="
echo;
