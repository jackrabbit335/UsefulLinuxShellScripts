#!/bin/bash

cat <<_EOF_
This file has the ability to download and compile hosts files from multiple sources. As such, this file should be
used with relative caution as failure to do so could result in pages no longer functioning properly. I'd suggest that
unless you absolutely needed it, using more than the first hosts file and maybe peter lowe's adservers list is
kinda redundant or probably not wise. Still if you wish to block most ads, I'd suggest the first four and adaway
to be sure.
_EOF_

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
str5=https://hosts-file.net/ad_servers.txt
str6=https://raw.githubusercontent.com/AdAway/adaway.github.io/master/hosts.txt
str7=http://sysctl.org/cameleon/hosts
str8=https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hosts%20%26%20sourcelist/StevenBlackhosts

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
		E) wget $str5 && cat ad_servers.txt >> adblock && rm ad_servers.txt
		;;
		F) wget $str6 && cat hosts.txt >> adblock && rm hosts.txt
		;;
		G) wget $str7 && cat hosts >> adblock && rm hosts
		;;
		H) wget $str8 && cat StevenBlackhosts >> adblock && rm StevenBlackhosts
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

#Remove comments and spaces
sed -e '/^[[:space:]]*$/d' adblock > adblock.new && mv adblock.new adblock
sed -e 's/[[:blank:]]//g' adblock > adblock.new && mv adblock.new adblock
sed -e 's/127.0.0.1/127.0.0.1 /g' adblock > adblock.new && mv adblock.new adblock
sed -e '/#.*/d' adblock > adblock.new && mv adblock.new adblock
sed -e '/^*$/d' adblock > adblock.new && mv adblock.new adblock

#This merges adblock with /etc/hosts then removes hosts
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
