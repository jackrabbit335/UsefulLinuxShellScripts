#!/bin/bash

#This updates the hosts file

echo "WARNING! USE OF THESE HOSTS COULD CAUSE MANY OF YOUR FAVORITE SITES TO CEASE FUNCTIONING. PROCEED WITH CAUTION."

echo "searching for /etc/hosts.bak and then creating hosts file to block tracking"
find /etc/hosts.bak
while [ $? -gt 0 ]
do
	sudo cp /etc/hosts /etc/hosts.bak
break
done

sudo cp /etc/hosts.bak /etc/hosts

cd /tmp
touch adblock && echo "----------------Hostsman4linux--------------" >> adblock

str1=http://winhelp2002.mvps.org/hosts.txt
str2=https://someonewhocares.org/hosts/hosts
str3=https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hosts%20%26%20sourcelist/Peteradslist
str4=http://www.malwaredomainlist.com/hostslist/hosts.txt
str5=http://hostsfile.mine.nu/Hosts.txt
str6=https://hosts-file.net/ad_servers.txt
str7=https://raw.githubusercontent.com/AdAway/adaway.github.io/master/hosts.txt
str8=http://sysctl.org/cameleon/hosts
str9=https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hosts%20%26%20sourcelist/main

while getopts :ABCDEFGH option; do
	case $option in
		A) wget $str1 && cat hosts.txt >> adblock && rm hosts.txt
		;;
		B) wget $str2 && cat hosts >> adblock && rm hosts
		;;
		C) wget $str3 && cat Peteradslist >> adblock && rm Peteradslist
		;;
		D) wget $str4 && cat hosts.txt >> adblock && rm hosts.txt
		;;
		E) wget $str5 && cat Hosts.txt >> adblock && rm Hosts.txt
		;;
		F) wget $str6 && cat ad_servers.txt >> adblock && rm ad_servers.txt
		;;
		G) wget $str7 && cat hosts.txt >> adblock && rm hosts.txt
		;;
		H) wget $str8 && cat hosts >> adblock && rm hosts
		;;
		I) wget $str9 && cat main >> adblock && rm main
		;;
		*)
	esac
done

echo "----------------Hostsman4linux--------------" >> adblock

#This tries to deduplicate if multiple files were used.
if [[ $# -gt 1 ]]; then
	sort adblock | uniq -u | sort -r > adblock.new && mv adblock.new adblock
fi

#This ensures that we are using All 127.x for pointing back to home
sed -i 's/0.0.0.0/127.0.0.1 /g' adblock

#Remove comments
sed -e '/^[[:space:]]*$/d' adblock > adblock.new && mv adblock.new adblock
sed -e 's/[[:blank:]]//g' adblock > adblock.new && mv adblock.new adblock
sed -e 's/127.0.0.1/127.0.0.1 /g' adblock > adblock.new && mv adblock.new adblock
sed -e '/#.*/d' adblock > adblock.new && mv adblock.new adblock
sed -e '/^*$/d' adblock > adblock.new && mv adblock.new adblock

#This merges hosts with /etc/hosts then removes hosts
sudo cat adblock >> /etc/hosts
rm adblock

#Go to /etc/ directory and check for distribution specific directories
find /etc/pacman.d > /dev/null
if [ $? -eq 0 ];
then
	Networkmanager=$(find /usr/bin/wicd)
	if [ $? -eq 0 ];
	then
		sudo systemctl restart wicd
	else
		sudo systemctl restart NetworkManager
	fi
fi

find /etc/apt > /dev/null
if [ $? -eq 0 ];
then
	Networkmanager=$(find /usr/bin/wicd)
	if [ $? -eq 0 ];
	then
		sudo /etc/init.d/wicd restart
	else
		sudo /etc/init.d/network-manager restart
	fi
fi

find /etc/solus-release > /dev/null
if [ $? -eq 0 ];
then
	Networkmanager=$(find /usr/bin/wicd)
	if [ $? -eq 0 ];
	then
		sudo systemctl restart wicd
	else
		sudo systemctl restart NetworkManager
	fi
fi
