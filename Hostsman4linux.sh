#!/bin/bash

cat <<EOF
This file has the ability to download and compile hosts files from multiple sources. As such, this file should be
used with relative caution as failure to do so could result in pages no longer functioning properly. I would suggest that
unless you absolutely needed it, using more than the first hosts file and maybe peter lowes adservers list is
kinda redundant or probably not wise. Still if you wish to block most ads, I would suggest the first four and adaway
to be sure.
EOF

#This updates the hosts file
echo "searching for /etc/hosts.bak and then creating hosts file to block tracking"
find /etc/hosts.bak
if [ $? -gt 0 ]
then
	sudo cp /etc/hosts /etc/hosts.bak && sudo cp /etc/hosts.bak /etc/hosts
else
	sudo cp /etc/hosts.bak /etc/hosts
fi

cd /tmp

str1=https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
str2=https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling/hosts
str3=https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn/hosts
str4=https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn-social/hosts

while getopts :ABCD option; do
	case $option in
		A) wget $str1 && cat hosts >> adblock && rm hosts
		;;
		B) wget $str2 && cat hosts >> adblock && rm hosts
		;;
		C) wget $str3 && cat hosts >> adblock && rm hosts
		;;
		D) wget $str4 && cat hosts >> adblock && rm hosts
		;;
		*)
	esac
done

#This tries to deduplicate if multiple files were used.
find adblock
if [[ $? -eq 0 ]];
then
	awk '!dup[$0]++' adblock > adblock.txt && rm adblock
fi

#This tries to exclude or whitelist domains from adblock assuming we downloaded anything
find adblock.txt
if [[ $? -eq 0 ]];
then
	read -p "Would you like to exclude domains?(Y/n)" answer
	while [ $answer == Y ];
	do
		read -a domains
		sed -i "/${domains[@]}/d" adblock.txt
	break
	done
fi

#This merges adblock with /etc/hosts then removes adblock
sudo cat adblock.txt >> /etc/hosts && rm adblock.txt

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

#This calculates the number of lines in the finished file
wc -l /etc/hosts
