#!/bin/bash
apt-get -y install rinetd
echo "10.0.1.99 443 127.0.0.1 4443" >> /etc/rinetd.conf
service rinetd restart
