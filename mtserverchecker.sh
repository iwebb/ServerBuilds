#!/bin/bash
OPT="/tmp/mtserverchecker.txt"

#This script was partly developed by Ian Webb, with most of the functions being established by Kyle Fox.
clear
#Update locate database
updatedb &

#Create serverchecker file
touch /tmp/mtserverchecker.txt
#hostname Check
echo $'\n'
echo "Server Hostname"
hostname |tee -a $OPT

#Check and print kernel version to a file
echo $'\n'
echo "KERNEL VERSION and OS"
echo -e "kernel version: $(uname -r)" |tee -a $OPT

#Check OS and print to file
cat /etc/*-release | uniq | tee -a $OPT 

#Check uptime 
echo $'\n'
echo "Uptime"
uptime | tee -a $OPT

#Check if Plesk exists and verify it's version installed in both MySQL and in it's installation directory
if [ ! -f "/usr/local/psa/version" ]; then
    echo -e "\e[5mNo Plesk Installed\e[25m"
else
    cat /usr/local/psa/version | tee -a /tmp/mtserverchecker.txt 
    echo $'\n'
    echo "Plesk Domains, Document Roots, and PHP engine" 
    echo $'\n'
    mysql -u admin -p$(cat /etc/psa/.psa.shadow) psa -e "select * from misc where param = 'version';" |mysql -u'admin' -p`cat /etc/psa/.psa.shadow` psa -e"select domains.id,domains.name,domains.htype,hosting.www_root,hosting.php_handler_id,sys_users.login,domains.webspace_id from domains join hosting on hosting.dom_id=domains.id join sys_users on sys_users.id=hosting.sys_user_id;" |tee -a $OPT 
fi
echo $'\n'
echo "Is cPanel installed?"
if [ ! -f "/usr/local/cpanel/cpanel" ]; then
    echo -e "\e[5mNo cPanel Installed\e[25m"
else
/usr/local/cpanel/cpanel -V
fi

#Check MySQL version
echo $'\n'
echo -e "MySQL Version"
mysql -V | tee -a $OPT

#Check PHP version
echo $'\n'
php -v | tee -a $OPT

#Check if Drupal/Joomla/WordPress exist, which versions they use
#echo $'\n'
#echo "Drupal Check"
#head -3 $(locate CHANGELOG.txt) | tee -a /tmp/mtserverchecker.txt 

#Check for Joomla
echo $'\n'
echo -e "Joomla Check" 
grep -e 'public \$RELEASE =' / $(locate version.php) | tee -a $OPT 

#Check for WordPress
echo $'\n'
echo -e "WordPress Check" 
grep '\$wp_version =' / $(locate version.php) | tee -a $OPT

#Check currently open ports, sort only the "CONNECTED" column
echo $'\n'
echo "Port Check"
netstat -plant | awk '{print $4,$7}' |  sed 's/.*://' | sort -n |uniq  | tee -a $OPT
#Grab iptables rules
echo $'\n'
echo -e "iptables Rules:"
iptables --line-numbers -nvL | tee -a /tmp/mtserverchecker.txt

#Disk space check
echo $'\n'
echo "DISK USAGE"
df -h | awk '{print $2,$3,$4,$5}' | uniq | tee -a $OPT 
echo $'\n'
df -i | awk '{print $2,$3,$4,$5}' | uniq | tee -a $OPT

#Check for New Relic/memcached/Tomcat
echo $'\n'
echo -e "VARNISH/TOMCAT/NEW RELIC/MEMCACHED?"
which tomcat | tee -a $OPT
which newrelic-daemon | tee -a $OPT
which memcached | tee -a $OPT
which varnishadm | tee -a $OPT

#Check current Plesk password
echo $'\n'
echo "PLESK PASSWORD"
/usr/local/psa/bin/admin --show-password

#Check for crashed databases
echo $'\n'
echo "Any crashed databases in MySQL log?"
#grep -i "crashed" /var/log/mysqld.log | tee -a $OPT
grep -i "crashed" /var/log/mysqld.log | awk '{$1=$2=""; print $0}'|sort| uniq -c| sort| tee -a $OPT
if grep -Fxq "crashed" /var/log/mysqld.log
then 
    tail -50 /var/log/mysqld.log | tail -50 /var/lib/mysql/*.err | tee -a $OPT
else
echo -e "NO CRASHES - LOOKIN' GOOD!" | tee -a $OPT
fi

#Check for failed root logins
echo $'\n'
echo "Failed root logins and origin IP"
grep -oE '((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])' /var/log/secure | uniq | sort -n | uniq -c | sort -n | tee -a $OPT
echo $'\n'
grep -oE '((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])' /var/log/secure | uniq | sort -n | uniq -c | sort -n | tee -a $OPT >> domains.txt   

for domain in `awk '{print $2}' domains.txt`
do
        whois $domain | grep -iE ^country: |sed 's/\S*\(country\|Country\)\S*//g' |uniq >> domains2.txt
done

for country in domains2.txt
do
 cat domains2.txt | sort -n | uniq -c | sort -n | tee -a $OPT
done 
rm domains.txt && rm domains2.txt
echo $'\n'
#grep -oE '((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])' /var/log/secure | uniq | sort -n | uniq -c | sort -n | tee -a $OPT

#Default Port 22
echo $'\n'
echo "Which port is sshd listening upon?"
if grep -iq "#Port 22" /etc/ssh/sshd_config; then
   echo -e "\e[5mDEFAULT PORT FOR SSH - SUGGEST CHANGING\e[25m" 
else 
   echo "Custom SSH Port"
fi | tee -a $OPT
