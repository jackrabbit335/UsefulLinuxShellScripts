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

echo "Select your package 1 2 3 4 5 6 7 8 9 10"
read package

if [[ $package == 1 ]];
then 
	#Steven Black's hosts without any other sources
	wget https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn/hosts && sort -u hosts > /tmp/hosts.new && mv /tmp/hosts.new hosts
elif [[ $package == 2 ]];
then 
	#Steven Black's hosts and hphosts ad servers list also cameleon
	wget https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn/hosts && sort -u hosts > /tmp/host.new && mv /tmp/hosts.new hosts
	wget https://hosts-file.net/ad_servers.txt && sort -u ad_servers.txt > /tmp/ad_servers.new && mv /tmp/ad_servers.new ad_servers.txt
	wget http://sysctl.org/cameleon/hosts -O cameleonhosts && sort -u cameleonhosts > /tmp/cameleonhosts.new && mv /tmp/cameleonhosts.new cameleonhosts
	cat ad_servers.txt >> hosts
	cat cameleonhosts >> hosts
	rm ad_servers.txt cameleonhosts
elif [[ $package == 3 ]];
then
	#hphosts cameleon and coinblocker
	wget http://hosts-file.malwareteks.com/hosts.txt -O hosts && sort -u hosts > /tmp/hosts.new && mv /tmp/hosts.new hosts
	wget raw.githubusercontent.com/ZeroDot1/CoinBlockerLists/master/hosts -O coinblocker && sort -u coinblocker > /tmp/coinblocker.new && mv /tmp/coinblocker.new coinblocker
	wget https://hosts-file.net/hphosts-partial.txt && sort -u hphosts-partial.txt > /tmp/hphosts-partial.new && mv /tmp/hphosts-partial.new hphosts-partial.txt
	wget http://sysctl.org/cameleon/hosts -O cameleonhosts && sort -u cameleonhosts > /tmp/cameleonhosts.new && mv /tmp/cameleonhosts.new cameleonhosts
	cat hphosts-partial.txt >> hosts
	cat cameleonhosts >> hosts
	cat coinblocker >> hosts
	rm hphosts-partial.txt cameleonhosts coinblocker
elif [[ $package == 4 ]];
then 
	#Sources include Steven Black's Hosts with hphosts and cameleon
	wget https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn/hosts && sort -u hosts > /tmp/hosts.new && mv /tmp/hosts.new hosts
	wget http://hosts-file.malwareteks.com/hosts.txt -O hphosts && sort -u hphosts > /tmp/hphosts.new && mv /tmp/hphosts.new hphosts
	wget https://hosts-file.net/hphosts-partial.txt && sort -u hphosts-partial.txt > /tmp/hphosts-partial.new && mv /tmp/hphosts-partial.new hphosts-partial.txt
	wget https://raw.githubusercontent.com/hectorm/hmirror/master/data/spam404.com/list.txt -O spamhosts && sed -i -e 's/^/0.0.0.0  /' spamhosts && sort -u spamhosts > /tmp/spamhosts.new && mv /tmp/spamhosts.new spamhosts
	wget http://sysctl.org/cameleon/hosts -O cameleonhosts && sort -u cameleonhosts > /tmp/cameleonhosts.new && mv /tmp/cameleonhosts.new cameleonhosts
	wget https://raw.githubusercontent.com/hectorm/hmirror/master/data/malwaredomains.com-justdomains/list.txt -O Malwarehosts2 && sed -i 's/^/0.0.0.0  /' Malwarehosts2 && sort -u Malwarehosts2 > /tmp/Malwarehosts2.new && mv /tmp/Malwarehosts2.new Malwarehosts2
	cat hphosts >> hosts
	cat hphosts-partial.txt >> hosts
	cat cameleonhosts >> hosts
	cat spamhosts >> hosts
	cat Malwarehosts2 >> hosts
	rm cameleonhosts hphosts hphosts-partial.txt spamhosts Malwarehosts2
elif [[ $package == 5 ]];
then
	#Same sources that Steven Black uses in his own hosts with other sources from hphosts and cameleon also spam404
	wget https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts -O adservers.txt && sort -u adservers.txt > /tmp/adservers.new && mv /tmp/adservers.new adservers.txt
	wget http://winhelp2002.mvps.org/hosts.txt -O MVPShosts && sort -u MVPShosts > /tmp/MVPShosts.new && mv /tmp/MVPShosts.new MVPShosts
	wget someonewhocares.org/hosts/hosts && sort -u hosts > /tmp/hosts.new && mv /tmp/hosts.new hosts
	wget https://raw.githubusercontent.com/lightswitch05/hosts/master/ads-and-tracking-extended.txt -O lightswitch05list && sort -u lightswitch05list > /tmp/lightswitch05list.new && mv /tmp/lightswitch05list.new lightswitch05list
	wget raw.githubusercontent.com/ZeroDot1/CoinBlockerLists/master/hosts -O coinblocker && sort -u coinblocker > /tmp/coinblocker.new && mv /tmp/coinblocker.new coinblocker
	wget https://raw.githubusercontent.com/Sinfonietta/hostfiles/master/snuff-hosts -O Pron2 && sort -u Pron2 > /tmp/Pron2.new && mv /tmp/Pron2.new Pron2
	wget https://raw.githubusercontent.com/marktron/fakenews/master/fakenews && sort -u fakenews > /tmp/fakenews.new && mv /tmp/fakenews.new fakenews
	wget https://raw.githubusercontent.com/Sinfonietta/hostfiles/master/gambling-hosts -O Gamblinglist && sort -u Gamblinglist > /tmp/Gamblinglist.new && mv /tmp/Gamblinglist.new Gamblinglist
	wget https://raw.githubusercontent.com/StevenBlack/hosts/master/data/StevenBlack/hosts -O Stevenhosts && sort -u Stevenhosts > /tmp/Stevenhosts.new && mv /tmp/Stevenhosts.new Stevenhosts
	wget https://raw.githubusercontent.com/Clefspeare13/pornhosts/master/0.0.0.0/hosts -O Pron && sort -u Pron > /tmp/Pron.new && mv /tmp/Pron.new Pron
	wget http://www.malwaredomainlist.com/hostslist/hosts.txt -O Malwarehosts && sort -u Malwarehosts > /tmp/Malwarehosts.new && mv /tmp/Malwarehosts.new Malwarehosts
	wget https://raw.githubusercontent.com/tyzbit/hosts/master/data/tyzbit/hosts -O tyzbit && sort -u tyzbit > /tmp/tyzbit.new && mv /tmp/tyzbit.new tyzbit
	wget https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts -O add.2o7Net && sort -u add.2o7Net > /tmp/add.2o7Net.new && mv /tmp/add.2o7Net.new add.2o7Net
	wget https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Dead/hosts -O add.Dead && sort -u add.Dead > /tmp/add.Dead.new && mv /tmp/add.Dead.new add.Dead
	wget https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Risk/hosts -O add.Risk && sort -u add.Risk > /tmp/add.Risk.new && mv /tmp/add.Risk.new add.Risk
	wget https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts -O add.Spam && sort -u add.Spam > /tmp/add.Spam.new && mv /tmp/add.Spam.new add.Spam
	wget https://raw.githubusercontent.com/azet12/KADhosts/master/KADhosts.txt && sort -u KADhosts > /tmp/KADhosts.new && mv /tmp/KADhosts.new KADhosts
	wget https://raw.githubusercontent.com/mitchellkrogza/Badd-Boyz-Hosts/master/hosts -O Badd-Boyz && sort -u Badd-Boyz > /tmp/Badd-Boyz.new && mv /tmp/Badd-Boyz.new Badd-Boyz
	wget https://raw.githubusercontent.com/FadeMind/hosts.extras/master/UncheckyAds/hosts -O unchecky && sort -u unchecky > /tmp/unchecky.new && mv /tmp/unchecky.new unchecky
	wget https://raw.githubusercontent.com/hectorm/hmirror/master/data/spam404.com/list.txt -O spamhosts && sed -i -e 's/^/0.0.0.0 /' spamhosts && sort -u spamhosts > /tmp/spamhosts.new && mv /tmp/spamhosts.new spamhosts
	wget http://hosts-file.malwareteks.com/hosts.txt -O hphosts && sort -u hphosts > /tmp/hphosts.new && mv /tmp/hphosts.new hphosts
	wget https://hosts-file.net/hphosts-partial.txt	&& sort -u hphosts-partial.txt > /tmp/hphosts-partial.new && mv /tmp/hphosts-partial.new hphosts-partial.txt
	wget http://sysctl.org/cameleon/hosts -O cameleonhosts && sort -u cameleonhosts > /tmp/cameleonhosts.new && mv /tmp/cameleonhosts.new cameleonhosts
	wget https://raw.githubusercontent.com/hectorm/hmirror/master/data/malwaredomains.com-justdomains/list.txt -O Malwarehosts2 && sed -i 's/^/0.0.0.0 /' Malwarehosts2 && sort -u Malwarehosts2 > /tmp/Malwarehosts2.new && mv /tmp/Malwarehosts2.new Malwarehosts2
	cat MVPShosts >> hosts
	cat coinblocker >> hosts
	cat Malwarehosts >> hosts
	cat lightswitch05list >> hosts
	cat Pron >> hosts
	cat Pron2 >> hosts
	cat add.Spam >> hosts
	cat add.Dead >> hosts
	cat add.Risk >> hosts
	cat add.2o7Net >> hosts
	cat Gamblinglist >> hosts
	cat KADhosts.txt >> hosts
	cat Stevenhosts >> hosts
	cat Badd-Boyz >> hosts
	cat fakenews >> hosts
	cat tyzbit >> hosts
	cat adservers.txt >> hosts
	cat unchecky >> hosts
	cat spamhosts >> hosts
	cat hphosts >> hosts
	cat hphosts-partial.txt >> hosts
	cat cameleonhosts >> hosts
	cat Malwarehosts2 >> hosts
	rm KADhosts.txt MVPShosts lightswitch05list coinblocker Malwarehosts Malwarehosts2 add.Spam add.Dead add.Risk add.2o7Net Badd-Boyz tyzbit adservers.txt hphosts-partial.txt hphosts cameleonhosts unchecky spamhosts Stevenhosts Pron Pron2 Gamblinglist fakenews
elif [[ $package == 6 ]];
then
	#Introducing Joey Lane's hosts
	echo "This could block sites that you need, you've been warned."
	sleep 1
	wget hosts-file.net/ad_servers.txt && sort -u ad_servers.txt > /tmp/ad_servers.new && mv /tmp/ad_servers.new ad_servers.txt
	wget raw.githubusercontent.com/ZeroDot1/CoinBlockerLists/master/hosts -O coinblocker && sort -u coinblocker > /tmp/coinblocker.new && mv /tmp/coinblocker.new coinblocker
	wget https://raw.githubusercontent.com/joeylane/hosts/master/hosts && sort -u hosts > /tmp/hosts.new && mv /tmp/hosts.new hosts # Does block google
	cat ad_servers.txt >> hosts
	cat coinblocker >> hosts
	rm ad_servers.txt coinblocker
	#grep -v "Google.com" hosts > /tmp/hosts.new && mv /tmp/hosts.new hosts #This unblocks google.com outright
elif [[ $package == 7 ]];
then
	#Really large hosts file
	wget https://github.com/mitchellkrogza/Ultimate.Hosts.Blacklist/blob/master/hosts.zip?raw=true
	unzip 'hosts.zip?raw=true'
	mv hosts.txt hosts && sort -u hosts > /tmp/hosts.new && mv /tmp/hosts.new hosts
	wget raw.githubusercontent.com/ZeroDot1/CoinBlockerLists/master/hosts -O coinblocker && sort -u coinblocker > /tmp/coinblocker.new && mv /tmp/coinblocker.new coinblocker
	cat coinblocker >> hosts
	rm'hosts.zip?raw=true' coinblocker
elif [[ $package == 8 ]];
then
	#Umatrix style formula with some extras
	wget hosts-file.net/ad_servers.txt && sort -u ad_servers.txt > /tmp/ad_servers.new && mv /tmp/ad_servers.new ad_servers.txt
	wget someonewhocares.org/hosts/hosts && sort -u hosts > /tmp/hosts.new && mv /tmp/hosts.new hosts
	wget raw.githubusercontent.com/ZeroDot1/CoinBlockerLists/master/hosts -O coinblocker && sort -u coinblocker > /tmp/coinblocker.new && mv /tmp/coinblocker.new coinblocker
	wget http://sysctl.org/cameleon/hosts -O cameleonhosts && sort -u cameleonhosts > /tmp/cameleonhosts.new && mv /tmp/cameleonhosts.new cameleonhosts
	wget http://winhelp2002.mvps.org/hosts.txt -O MVPShosts && sort -u MVPShosts > /tmp/MVPShosts.new && mv /tmp/MVPShosts.new MVPShosts
	wget http://www.malwaredomainlist.com/hostslist/hosts.txt -O Malwarehosts && sort -u Malwarehosts > /tmp/Malwarehosts.new && mv /tmp/Malwarehosts.new Malwarehosts
	wget https://raw.githubusercontent.com/hectorm/hmirror/master/data/pgl.yoyo.org/list.txt -O Petersadslist && sed -i -e 's/^/0.0.0.0  /' Petersadslist && sort -u Petersadslist > /tmp/Petersadslist.new && mv /tmp/Petersadslist.new Petersadslist
	wget https://raw.githubusercontent.com/hectorm/hmirror/master/data/malwaredomains.com-immortaldomains/list.txt -O Malware2 && sed -i -e 's/^/0.0.0.0  /' Malware2 && sort -u Malware2 > /tmp/Malware2.new && mv /tmp/Malware2.new Malware2
	wget https://raw.githubusercontent.com/hectorm/hmirror/master/data/spam404.com/list.txt -O Spamhosts && sed -i -e 's/^/0.0.0.0  /' Spamhosts && sort -u Spamhosts > /tmp/Spamhosts.new && mv /tmp/Spamhosts.new Spamhosts
	cat MVPShosts >> hosts 
	cat Malwarehosts >> hosts 
	cat Petersadslist >> hosts
	cat Malware2 >> hosts
	cat cameleonhosts >> hosts
	cat ad_servers.txt >> hosts
	cat Spamhosts >> hosts
	cat coinblocker >> hosts
	rm ad_servers.txt Petersadslist coinblocker Malwarehosts Malware2 Spamhosts MVPShosts cameleonhosts
elif [[ $package == 9 ]];
then
	#Borrowed from Hblock on github, hphosts and a number of other sources
	wget https://raw.githubusercontent.com/hectorm/hmirror/master/data/disconnect.me-ad/list.txt -O Adslist && sed -i -e 's/^/0.0.0.0 /' Adslist && sed -i '1,4d' Adslist && sort -u Adslist > /tmp/Adslist.new && mv /tmp/Adslist.new Adslist
	wget https://raw.githubusercontent.com/hectorm/hmirror/master/data/disconnect.me-malvertising/list.txt -O Malvertisinglist && sed -i -e 's/^/0.0.0.0 /' Malvertisinglist && sed -i '1,4d' Malvertisinglist && sort -u Malvertisinglist > /tmp/Malvertisinglist.new && mv /tmp/Malvertisinglist.new Malvertisinglist
	wget https://raw.githubusercontent.com/hectorm/hmirror/master/data/disconnect.me-malware/list.txt -O Malwarelist && sed -i -e 's/^/0.0.0.0 /' Malwarelist && sed -i '1,4d' Malwarelist && sort -u Malwarelist > /tmp/Malwarelist.new && mv /tmp/Malwarelist.new Malwarelist
	wget https://raw.githubusercontent.com/hectorm/hmirror/master/data/disconnect.me-tracking/list.txt -O Trackinglist && sed -i -e 's/^/0.0.0.0 /' Trackinglist && sed -i '1,4d' Trackinglist && sort -u Trackinglist > /tmp/Trackinglist.new && mv /tmp/Trackinglist.new Trackinglist
	wget https://hosts-file.net/ad_servers.txt && sort -u ad_servers.txt > /tmp/ad_servers.new && mv /tmp/ad_servers.new ad_servers.txt
	wget https://hosts-file.net/emd.txt && sort -u emd.txt > /tmp/emd.new && mv /tmp/emd.new emd.txt
	wget http://winhelp2002.mvps.org/hosts.txt -O MVPShosts && sort -u MVPShosts > /tmp/MVPShosts.new && mv /tmp/MVPShosts.new MVPShosts
	wget http://www.malwaredomainlist.com/hostslist/hosts.txt -O Malwarehosts && sort -u Malwarehost > /tmp/Malwarehost.new && mv /tmp/Malwarehosts.new Malwarehosts
	touch hosts 
	cat ad_servers.txt >> hosts 
	cat emd.txt >> hosts
	cat Trackinglist >> hosts
	cat Malwarelist >> hosts
	cat Malvertisinglist >> hosts
	cat Adslist >> hosts
	cat MVPShosts >> hosts
	cat Malwarehosts >> hosts
	rm Trackinglist Adslist Malvertisinglist Malwarehosts Malwarelist emd.txt fsa.txt psh.txt ad_servers.txt
elif [[ $package == 10 ]];
then
	#Steven Black's hosts with fully updated sources and with hosts-file.net ads servers added.
	wget https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts -O adservers.txt && sort -u adservers.txt > /tmp/adservers.new && mv /tmp/adservers.new adservers.txt
	wget http://winhelp2002.mvps.org/hosts.txt -O MVPShosts && sort -u MVPShosts > /tmp/MVPShosts.new && mv /tmp/MVPShosts.new MVPShosts
	wget someonewhocares.org/hosts/hosts && sort -u hosts > /tmp/hosts.new && mv /tmp/hosts.new hosts
	wget https://raw.githubusercontent.com/lightswitch05/hosts/master/ads-and-tracking-extended.txt -O lightswitch05list && sort -u lightswitch05list > /tmp/lightswitch05list.new && mv /tmp/lightswitch05list.new lightswitch05list
	wget raw.githubusercontent.com/ZeroDot1/CoinBlockerLists/master/hosts -O coinblocker && sort -u coinblocker > /tmp/coinblocker.new && mv /tmp/coinblocker.new coinblocker
	wget https://raw.githubusercontent.com/Sinfonietta/hostfiles/master/snuff-hosts -O Pron2 && sort -u Pron2 > /tmp/Pron2.new && mv /tmp/Pron2.new Pron2
	wget https://raw.githubusercontent.com/marktron/fakenews/master/fakenews && sort -u fakenews > /tmp/fakenews.new && mv /tmp/fakenews.new fakenews
	wget https://raw.githubusercontent.com/Sinfonietta/hostfiles/master/gambling-hosts -O Gamblinglist && sort -u Gamblinglist > /tmp/Gamblinglist.new && mv /tmp/Gamblinglist.new Gamblinglist
	wget https://raw.githubusercontent.com/StevenBlack/hosts/master/data/StevenBlack/hosts -O Stevenhosts && sort -u Stevenhosts > /tmp/Stevenhosts.new && mv /tmp/Stevenhosts.new Stevenhosts
	wget https://raw.githubusercontent.com/Clefspeare13/pornhosts/master/0.0.0.0/hosts -O Pron && sort -u Pron > /tmp/Pron.new && mv /tmp/Pron.new Pron
	wget http://www.malwaredomainlist.com/hostslist/hosts.txt -O Malwarehosts && sort -u Malwarehosts > /tmp/Malwarehosts.new && mv /tmp/Malwarehosts.new Malwarehosts
	wget https://raw.githubusercontent.com/tyzbit/hosts/master/data/tyzbit/hosts -O tyzbit && sort -u tyzbit > /tmp/tyzbit.new && mv /tmp/tyzbit.new tyzbit
	wget https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts -O add.2o7Net && sort -u add.2o7Net > /tmp/add.2o7Net.new && mv /tmp/add.2o7Net.new add.2o7Net
	wget https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Dead/hosts -O add.Dead && sort -u add.Dead > /tmp/add.Dead.new && mv /tmp/add.Dead.new add.Dead
	wget https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Risk/hosts -O add.Risk && sort -u add.Risk > /tmp/add.Risk.new && mv /tmp/add.Risk.new add.Risk
	wget https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts -O add.Spam && sort -u add.Spam > /tmp/add.Spam.new && mv /tmp/add.Spam.new add.Spam
	wget https://raw.githubusercontent.com/azet12/KADhosts/master/KADhosts.txt && sort -u KADhosts > /tmp/KADhosts.new && mv /tmp/KADhosts.new KADhosts
	wget https://raw.githubusercontent.com/mitchellkrogza/Badd-Boyz-Hosts/master/hosts -O Badd-Boyz && sort -u Badd-Boyz > /tmp/Badd-Boyz.new && mv /tmp/Badd-Boyz.new Badd-Boyz
	wget https://raw.githubusercontent.com/FadeMind/hosts.extras/master/UncheckyAds/hosts -O unchecky && sort -u unchecky > /tmp/unchecky.new && mv /tmp/unchecky.new unchecky
	wget https://raw.githubusercontent.com/hectorm/hmirror/master/data/spam404.com/list.txt -O Spamhosts && sed -i -e 's/^/0.0.0.0  /' Spamhosts && sort -u Spamhosts > /tmp/Spamhosts.new && mv /tmp/Spamhosts.new Spamhosts
	wget http://sysctl.org/cameleon/hosts -O cameleonhosts && sort -u cameleonhosts > /tmp/cameleonhosts.new && mv /tmp/cameleonhosts.new cameleonhosts
	wget https://hosts-file.net/ad_servers.txt && sort -u ad_servers.txt > /tmp/ad_servers.new && mv /tmp/ad_servers.new ad_servers.txt
	wget https://raw.githubusercontent.com/hectorm/hmirror/master/data/malwaredomains.com-justdomains/list.txt -O Malwarehosts2 && sed -i 's/^/0.0.0.0  /' Malwarehosts2 && sort -u Malwarehosts2 > /tmp/Malwarehosts2.new && mv /tmp/Malwarehosts2.new Malwarehosts2
	cat MVPShosts >> hosts
	cat coinblocker >> hosts
	cat Malwarehosts >> hosts
	cat lightswitch05list >> hosts
	cat Pron >> hosts
	cat Pron2 >> hosts
	cat add.Spam >> hosts
	cat add.Dead >> hosts
	cat add.Risk >> hosts
	cat add.2o7Net >> hosts
	cat Gamblinglist >> hosts
	cat KADhosts.txt >> hosts
	cat Stevenhosts >> hosts
	cat Badd-Boyz >> hosts
	cat fakenews >> hosts
	cat tyzbit >> hosts
	cat adservers.txt >> hosts
	cat ad_servers.txt >> hosts
	cat unchecky >> hosts
	cat Spamhosts >> hosts
	cat cameleonhosts >> hosts
	cat Malwarehosts2 >> hosts
	rm KADhosts.txt MVPShosts ad_servers.txt lightswitch05list coinblocker Malwarehosts Malwarehosts2 add.Spam add.Dead add.Risk add.2o7Net Badd-Boyz tyzbit adservers.txt cameleonhosts unchecky Spamhosts Stevenhosts Pron Pron2 Gamblinglist fakenews
else 
	echo "Run again and pick a valid number."
	exit
fi

#These can add extra lists for deeper blocking of ads
echo "Would you like to add some extra domains?(Y/n)"
read answer 
while [ $answer == Y ];
do
	wget https://raw.githubusercontent.com/bjornstar/hosts/master/hosts -O bjornhosts && sort -u bjornhosts > /tmp/bjornhosts.new && mv /tmp/bjornhosts.new bjornhosts
	cat bjornhosts >> hosts 
	rm bjornhosts
break
done

echo "This list is the simple ad filter from adguard. I cannot attest to how often it is updated"
echo "Would you like to use adguarlist?(Y/n)"
read answer
while [ $answer == Y ];
do
	wget https://raw.githubusercontent.com/hectorm/hmirror/master/data/adguard-simplified/list.txt -O Adguardlist && sed -i -e 's/^/0.0.0.0 /' Adguardlist && sort -u Adguardlist > /tmp/Adguardlist.new && mv /tmp/Adguardlist.new Adguardlist
	cat Adguardlist >> hosts 
	rm Adguardlist
break
done

echo "This hosts file also doesn't update everyday, however, it does block some third-parties that others do not."
echo "Would you like to add My own hosts list?(Y/n)"
read answer
while [ $answer == Y ];
do
	wget https://raw.githubusercontent.com/thedummy06/Helpful-Linux-Shell-Scripts/master/extrahosts && sort -u extrahosts > /tmp/extrahosts.new && mv /tmp/extrahosts.new extrahosts
	cat extrahosts >> hosts
	rm extrahosts
break
done

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

#This ensures that we are using All 0's for pointing back to home
sed -i 's/127.0.0.1/0.0.0.0/g' hosts

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

#Searches for logs fold to determine if we need to create it
find $house/logs/ 
while [ $? -eq 1 ];
do
	mkdir $house/logs/
break
done
cat /etc/hosts > $house/logs/hosts.log
