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

echo "Select your package 1 2 3 4"
read package

if [[ $package == 1 ]];
then
	echo "You've opted for the basic package, this blocks typical ad and spyware"
	wget http://winhelp2002.mvps.org/hosts.txt -O hosts
elif [[ $package == 2 ]];
then
	echo "You've opted for the Medium Package, this blocks some ads as 
	\\ well as known malicious"
	wget http://winhelp2002.mvps.org/hosts.txt -O hosts
	wget http://www.malwaredomainlist.com/hostslist/hosts.txt -O Malwarehosts
	cat Malwarehosts >> hosts
	rm Malwarehosts
	sort hosts | uniq | sort -r > /tmp/hosts.new && mv /tmp/hosts.new hosts
elif [[ $package == 3 ]];
then
	echo "You've opted for High, this blocks all known ads, spyware, tracking, malicious"
	wget http://winhelp2002.mvps.org/hosts.txt -O MVPShosts
	wget http://www.malwaredomainlist.com/hostslist/hosts.txt -O Malwarehosts
	wget https://someonewhocares.org/hosts/zero/hosts
	wget https://raw.githubusercontent.com/hectorm/hmirror/master/data/pgl.yoyo.org/list.txt -O Petersadslist && sed -i -e 's/^/127.0.0.1 /' Petersadslist
	cat MVPShosts >> hosts
	cat Malwarehosts >> hosts
	cat Petersadslist >> hosts
	rm Malwarehosts MVPShosts Petersadslist
	sort hosts | uniq | sort -r > /tmp/hosts.new && mv /tmp/hosts.new hosts
elif [[ $package == 4 ]];
then
	echo "You've opted for all the bells and whistles. The Paranoia package"
	wget http://winhelp2002.mvps.org/hosts.txt -O MVPShosts
	wget https://someonewhocares.org/hosts/zero/hosts
	wget http://www.malwaredomainlist.com/hostslist/hosts.txt -O Malwarehosts
	wget https://raw.githubusercontent.com/hectorm/hmirror/master/data/pgl.yoyo.org/list.txt -O Petersadslist && sed -i -e 's/^/127.0.0.1 /' Petersadslist
	wget https://hosts-file.net/ad_servers.txt
	wget raw.githubusercontent.com/ZeroDot1/CoinBlockerLists/master/hosts -O coinblocker
	wget https://raw.githubusercontent.com/hectorm/hmirror/master/data/adguard-simplified/list.txt -O Adguardlist && sed -i -e 's/^/127.0.0.1 /' Adguardlist 
	cat Adguardlist >> hosts
	cat MVPShosts >> hosts
	cat Malwarehosts >> hosts
	cat ad_servers.txt >> hosts
	cat coinblocker >> hosts
	cat Petersadslist >> hosts
	rm Malwarehosts MVPShosts Adguardlist ad_servers.txt Petersadslist coinblocker
	sort hosts | uniq | sort -r > /tmp/hosts.new && mv /tmp/hosts.new hosts
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
sed -e '/^$/d' > /tmp/hosts.new && mv /tmp/hosts.new hosts

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
