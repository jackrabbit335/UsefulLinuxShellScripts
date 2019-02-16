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

echo "Please enter your username."
read username
house=/home/$username
cd $house

echo "Select your package 1 2 3 4 5 6"
read package

if [[ $package == 1 ]];
then
	echo "##############################################################"
	echo "BASIC PROTECTION!"
	echo "##############################################################"
	wget http://winhelp2002.mvps.org/hosts.txt -O hosts
elif [[ $package == 2 ]];
then
	echo "##############################################################"
	echo "INTERMEDIATE PROTECTION!"
	echo "##############################################################"
	wget http://winhelp2002.mvps.org/hosts.txt -O MVPShosts
	wget https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hosts%20%26%20sourcelist/Peteradslist
	wget http://www.malwaredomainlist.com/hostslist/hosts.txt -O Malwarehosts
	wget https://someonewhocares.org/hosts/zero/hosts
	wget https://zerodot1.gitlab.io/CoinBlockerLists/hosts_browser -O nocoin
	cat Malwarehosts >> hosts
	cat MVPShosts >> hosts
	cat Peteradslist >> hosts
	cat nocoin >> hosts
	rm Malwarehosts nocoin Peteradslist MVPShosts
	sort hosts | uniq -u | sort -r > /tmp/hosts.new && mv /tmp/hosts.new hosts
elif [[ $package == 3 ]];
then
	echo "##############################################################"
	echo "Full PROTECTION!"
	echo "##############################################################"
	wget http://winhelp2002.mvps.org/hosts.txt -O MVPShosts
	wget http://www.malwaredomainlist.com/hostslist/hosts.txt -O Malwarehosts
	wget https://someonewhocares.org/hosts/zero/hosts
	wget https://hosts-file.net/ad_servers.txt
	wget http://hostsfile.mine.nu/Hosts.txt
	wget https://raw.githubusercontent.com/Clefspeare13/pornhosts/master/0.0.0.0/hosts -O Pron
	wget https://zerodot1.gitlab.io/CoinBlockerLists/hosts_browser -O nocoin
	wget https://raw.githubusercontent.com/AdAway/adaway.github.io/master/hosts.txt -O Adaway
	wget https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hosts%20%26%20sourcelist/Peteradslist
	cat MVPShosts >> hosts
	cat Malwarehosts >> hosts
	cat Pron >> hosts
	cat nocoin >> hosts
	cat Hosts.txt >> hosts
	cat ad_servers.txt >> hosts
	cat Adaway >> hosts
	cat Peteradslist >> hosts
	rm Malwarehosts MVPShosts Peteradslist Adaway nocoin ad_servers.txt Hosts.txt Pron
	sort hosts | uniq -u | sort -r > /tmp/hosts.new && mv /tmp/hosts.new hosts
elif [[ $package == 4 ]];
then
	echo "##############################################################" 
	echo "ULTIMATE PROTECTION!"
	echo "##############################################################"
	wget http://winhelp2002.mvps.org/hosts.txt -O MVPShosts
	wget https://someonewhocares.org/hosts/zero/hosts
	wget http://www.malwaredomainlist.com/hostslist/hosts.txt -O Malwarehosts
	wget https://hosts-file.net/ad_servers.txt
	wget https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hosts%20%26%20sourcelist/hosts -O tyzbit
	wget https://raw.githubusercontent.com/Sinfonietta/hostfiles/master/gambling-hosts -O Gamblinglist
	wget https://raw.githubusercontent.com/mitchellkrogza/Badd-Boyz-Hosts/master/hosts -O Badd-Boyz
	wget https://raw.githubusercontent.com/AdAway/adaway.github.io/master/hosts.txt -O Adaway
	wget https://raw.githubusercontent.com/Clefspeare13/pornhosts/master/0.0.0.0/hosts -O Pron
	wget https://raw.githubusercontent.com/azet12/KADhosts/master/KADhosts.txt
	wget https://raw.githubusercontent.com/lightswitch05/hosts/master/ads-and-tracking-extended.txt -O lightswitch05
	wget https://zerodot1.gitlab.io/CoinBlockerLists/hosts_browser -O nocoin
	wget http://sysctl.org/cameleon/hosts -O cameleonhosts
	wget http://hostsfile.mine.nu/Hosts.txt 
	cat MVPShosts >> hosts
	cat Malwarehosts >> hosts
	cat ad_servers.txt >> hosts
	cat lightswitch05 >> hosts
	cat Hosts.txt >> hosts
	cat KADhosts.txt >> hosts
	cat Pron >> hosts
	cat Badd-Boyz >> hosts
	cat Gamblinglist >> hosts
	cat cameleonhosts >> hosts
	cat tyzbit >> hosts
	cat nocoin >> hosts
	cat Adaway >> hosts
	rm Malwarehosts MVPShosts Hosts.txt cameleonhosts ad_servers.txt Pron Adaway nocoin tyzbit Gamblinglist KADhosts.txt lightswitch05 Badd-Boyz
	sort hosts | uniq -u | sort -r > /tmp/hosts.new && mv /tmp/hosts.new hosts
elif [[ $package == 5 ]];
then
	echo "##############################################################"
	echo "HPHOSTS"
	echo "##############################################################"
	wget http://hosts-file.malwareteks.com/hosts.txt -O hosts
	wget https://hosts-file.net/hphosts-partial.txt
	cat hphosts-partial.txt >> hosts
	rm hphosts-partial.txt
elif [[ $package == 6 ]];
then
	echo "#############################################################"
	echo "HPHOSTS PLUS"
	echo "#############################################################"
	wget http://hosts-file.malwareteks.com/hosts.txt -O hosts
	wget https://hosts-file.net/hphosts-partial.txt
	wget http://winhelp2002.mvps.org/hosts.txt -O MVPShosts
	cat hphosts-partial.txt >> hosts
	cat MVPShosts >> hosts
	rm hphosts-partial.txt MVPShosts
	sort hosts | uniq -u | sort -r > /tmp/hosts.new && mv /tmp/hosts.new hosts
fi

#Excludes domains to give you access to your favorite sites
while [ $? -eq 0 ];
do
	echo "Would you like to exclude a domain?(Y/n)"
	read answer
	if [[ $answer == Y ]];
	then
		echo "Enter the domain you wish to exclude"
		read domain
		sed -i "/$domain/d" hosts
	else
		break
	fi

done

#This ensures that we are using All zeros for pointing back to home
sed -i 's/127.0.0.1/0.0.0.0/g' hosts

#Remove comments
sed -e '/#.*/d' hosts > /tmp/hosts.new && mv /tmp/hosts.new hosts
sed -e '/^$/d' hosts > /tmp/hosts.new && mv /tmp/hosts.new hosts

#This merges hosts with /etc/hosts then removes hosts
sudo cat hosts >> /etc/hosts
rm hosts

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

#Searches for logs folder to determine if we need to create it
find $house/logs/ 
while [ $? -eq 1 ];
do
	mkdir $house/logs/
break
done
cat /etc/hosts > $house/logs/hosts.log
