#!/bin/bash

cat <<_EOF_
This file has the ability to download and compile hosts files from multiple sources. As such, this file should be
used with relative caution as failure to do so could result in pages no longer functioning properly. I'd suggest that
unless you absolutely needed it, using more than the first hosts file and maybe peter lowes adservers list is
kinda redundant or probably not wise. Still if you wish to block most ads, I'd suggest the first four and adaway
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
echo "---------------------Hostsman4linux-------------------" >> adblock

str1=https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hosts%20%26%20sourcelist/MVPShosts
str2=https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hosts%20%26%20sourcelist/Someonewhocares
str3=https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hosts%20%26%20sourcelist/Peteradslist
str4=https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hosts%20%26%20sourcelist/Malwarehosts
str5=https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hosts%20%26%20sourcelist/noCoin
str6=https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hosts%20%26%20sourcelist/AdAway
str7=https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hosts%20%26%20sourcelist/blacklist.txt
str8=https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hosts%20%26%20sourcelist/bjornhosts
str9=https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hosts%20%26%20sourcelist/StevenHosts
str10=https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hosts%20%26%20sourcelist/Badd-Boyz
str11=https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hosts%20%26%20sourcelist/tomslist
str12=https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hosts%20%26%20sourcelist/BadHosts
str13=https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hosts%20%26%20sourcelist/Casino


while getopts :ABCDEFGHIJKLM option; do
	case $option in
		A) wget $str1 && cat MVPShosts >> adblock && rm MVPShosts
		;;
		B) wget $str2 && cat Someonewhocares >> adblock && rm Someonewhocares
		;;
		C) wget $str3 && cat Peteradslist >> adblock && rm Peteradslist
		;;
		D) wget $str4 && cat Malwarehosts >> adblock && rm Malwarehosts
		;;
		E) wget $str5 && cat noCoin >> adblock && rm noCoin
		;;
		F) wget $str6 && cat AdAway >> adblock && rm AdAway
		;;
		G) wget $str7 && cat blacklist.txt >> adblock && rm blacklist.txt
		;;
		H) wget $str8 && cat bjornhosts >> adblock && rm bjornhosts
		;;
		I) wget $str9 && cat StevenBlacks >> adblock && rm StevenBlacks
		;;
		J) wget $str10 && cat Badd-Boyz >> adblock && rm Badd-Boyz
		;;
		K) wget $str11 && cat tomslist >> adblock && rm tomslist
		;;
		L) wget $str12 && cat BadHosts >> adblock && rm BadHosts
		;;
        M) wget $str13 && cat Casino >> adblock && rm Casino
		;;
		*)
	esac
done

echo "---------------------Hostsman4linux-------------------" >> adblock

#This tries to deduplicate if multiple files were used.
if [[ $# -gt 1 ]]; then
	sort adblock | uniq -u | sort -r > adblock.new && mv adblock.new adblock
fi

#This merges adblock with /etc/hosts then removes adblock
echo "" | sudo tee -a /etc/hosts
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
