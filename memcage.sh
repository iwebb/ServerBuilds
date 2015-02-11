#!/bin/bash

#Set IP Variable to place in memcached config
IP=$(/sbin/ifconfig venet0:0 | grep ‘inet addr’ | cut -d: -f2 | awk ‘{print $1}’)

#install perl/python/php
yum install python-memcached
yum install php-pecl-memcache
yum install perl-Cache-Memcached

#install memcached
yum install memcached.x86_64 php-pecl-memcache.x86_64

sed -i “s/OPTIONS=\”\”/OPTIONS=\”$IP\”/g” /etc/sysconfig/memcached;

/etc/init.d/memcached start

#Check if memcached is installed.
read -p “Would you like to check if Memcached is listening on 11211? (y/n)” REPLY
if [ “$REPLY” == “y” ]; then
netstat -tulpn | grep :11211;
else
echo “Skipping.”
fi

#Confirm if they want to install pagespeed
read -p “Would you like to install mod_pagespeed? (y/n)” RESPONSE
if [ “$RESPONSE” == “y” ]; then

#Add repo for pagespeed
echo “[mod-pagespeed]
name=mod-pagespeed
baseurl=http://dl.google.com/linux/mod-pagespeed/rpm/stable/x86_64
enabled=1
gpgcheck=0″ > /etc/yum.repos.d/mod-pagespeed.repo

#install mod_pagespeed
yum –enablerepo=mod-pagespeed install mod-pagespeed
echo “Pagespeed successfully installed.”
else
echo “Exiting.”
fi
