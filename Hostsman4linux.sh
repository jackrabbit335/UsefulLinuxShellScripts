#!/bin/bash

cat <<_EOF_
This file has the ability to download and compile hosts files from multiple sources. As such, this file should be
used with relative caution as failure to do so could result in pages no longer functioning properly. I would suggest that
unless you absolutely needed it, using more than the first hosts file and maybe peter lowes adservers list is
kinda redundant or probably not wise. Still if you wish to block most ads, I would suggest the first four and adaway
to be sure.
_EOF_

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

str1=https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hosts%20%26%20sourcelist/MVPShosts
str2=https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hosts%20%26%20sourcelist/Someonewhocares
str3=https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hosts%20%26%20sourcelist/Peteradslist
str4=https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hosts%20%26%20sourcelist/Malwarehosts
str5=https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hosts%20%26%20sourcelist/Trackinghosts
str6=https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hosts%20%26%20sourcelist/AdAway
str7=https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hosts%20%26%20sourcelist/blacklist.txt
str8=https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hosts%20%26%20sourcelist/StevenHosts
str9=https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hosts%20%26%20sourcelist/Badd-Boyz
str10=https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hosts%20%26%20sourcelist/Gambling
str11=https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hosts%20%26%20sourcelist/Tomslist


while getopts :ABCDEFGHIJK option; do
	case $option in
		A) wget $str1 && cat MVPShosts >> adblock && rm MVPShosts
		;;
		B) wget $str2 && cat Someonewhocares >> adblock && rm Someonewhocares
		;;
		C) wget $str3 && cat Peteradslist >> adblock && rm Peteradslist
		;;
		D) wget $str4 && cat Malwarehosts >> adblock && rm Malwarehosts
		;;
		E) wget $str5 && cat Trackinghosts >> adblock && rm Trackinghosts
		;;
		F) wget $str6 && cat AdAway >> adblock && rm AdAway
		;;
		G) wget $str7 && cat blacklist.txt >> adblock && rm blacklist.txt
		;;
		H) wget $str8 && cat StevenBlacks >> adblock && rm StevenBlacks
		;;
		I) wget $str9 && cat Badd-Boyz >> adblock && rm Badd-Boyz
		;;
		J) wget $str10 && cat Gambling >> adblock && rm Gambling
		;;
		K) wget $str11 && cat Tomslist >> adblock && rm Tomslist
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
		read -p "Enter the domain you would like to exclude:" domain
		sed -i "s/$domain/ s/^#*/#/" adblock.txt
	break
	done
fi

#This merges adblock with /etc/hosts then removes adblock
echo "" | sudo tee -a /etc/hosts
sudo cat adblock.txt >> /etc/hosts
rm adblock.txt

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
