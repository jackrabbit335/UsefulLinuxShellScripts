#!/bin/bash

Setup() {
	#This sets your default editor in bashrc
	echo "export EDITOR=nano" | sudo tee -a /etc/bash.bashrc

	#This activates the firewall
	sudo systemctl enable ufw
	sudo ufw enable
	echo "Would you like to deny ssh and telnet for security purposes?(Y/n)"
	read answer
	if [[ $answer == Y ]];
	then
		sudo ufw deny telnet && sudo ufw deny ssh
		sudo ufw reload
	fi
	
	#This disables ipv6
	echo "Sometimes ipv6 can cause network issues. Would you like to disable it?(Y/n)"
	read answer 
	if [[ $answer == Y ]];
	then
		sudo cp /etc/default/grub /etc/default/grub.bak
		sudo sed -i -e 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="ipv6.disable=1"/g' /etc/default/grub
		sudo update-grub2
	else
		echo "Okay!"
	fi

	#This adds a few aliases to bashrc
	echo "Aliases are shortcuts to commonly used commands."
	echo "would you like to add some aliases?(Y/n)"
	read answer 

	if [[ $answer == Y ]];
	then 
		sudo cp ~/.bashrc ~/.bashrc.bak
		echo "#Alias to update the system" >> ~/.bashrc
		echo 'alias update="sudo apt update && sudo apt dist-upgrade -yy"' >> ~/.bashrc
		echo "#Alias to clean the apt cache" >> ~/.bashrc
		echo 'alias clean="sudo apt autoremove && sudo apt autoclean && sudo apt clean"' >> ~/.bashrc
	fi

	#System tweaks
	sudo cp /etc/default/grub /etc/default/grub.bak
	sudo sed -i -e '/GRUB_TIMEOUT=10/c\GRUB_TIMEOUT=3 ' /etc/default/grub
	sudo update-grub2

	#Tweaks the sysctl config file
	sudo cp /etc/sysctl.conf /etc/sysctl.conf.bak
	echo "# Reduces the swap" | sudo tee -a /etc/sysctl.conf
	echo "vm.swappiness = 5" | sudo tee -a /etc/sysctl.conf
	echo "# Improve cache management" | sudo tee -a /etc/sysctl.conf
	echo "vm.vfs_cache_pressure = 50" | sudo tee -a /etc/sysctl.conf
	echo "#tcp flaw workaround" | sudo tee -a /etc/sysctl.conf
	echo "net.ipv4.tcp_challenge_ack_limit = 999999999" | sudo tee -a /etc/sysctl.conf
	sudo sysctl -p
	
	#This attempts to place noatime at the end of your drive entry in fstab
	echo "This can potentially make your drive unbootable, use with caution"
	echo "Would you like to improve hard drive performance with noatime?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		sudo cp /etc/fstab /etc/fstab.bak
		sudo sed -i 's/errors=remount-ro 0       1/errors=remount-ro,noatime 0        1/g ' /etc/fstab
	break
	done
	
	#This locks down ssh
	sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
	sudo sed -i -e '/#PermitRootLogin/c\PermitRootLogin no ' /etc/ssh/sshd_config
	
    #This removes that retarded gnome-keyring unlock error you get with    chrome
    echo "Killing this might make your passwords less secure on chrome."
    sleep 1
    echo "Do you wish to kill gnome-keyring? (Y/n)"
    read answer 
    if [[ $answer == Y ]];
    then
	    sudo mv /usr/bin/gnome-keyring-daemon /usr/bin/gnome-keyring-daemon-old
	    sudo killall gnome-keyring-daemon
    else
	    echo "Proceeding"
    fi

	#This determines what type of drive you have, then offers to enable trim or write-back caching
	drive=$(cat /sys/block/sda/queue/rotational)
	for rota in $drive;
	do
		if [[ $drive == 1 ]];
		then
			echo "Would you like to enable write back caching?(Y/n)"
			read answer 
			while [ $answer == Y ];
			do 
				echo "Enter the device you'd like to enable this on."
				read device
				sudo hdparm -W 1 $device
			break
			done
		elif [[ $drive == 0 ]];
		then
			echo "Trim is already enabled on Ubuntu-based systems\
			however, you can still run it manually if you'd like."
			echo "Would you like to run Trim?(Y/n)"
			read answer 
			while [ $answer == Y ];
			do 
				sudo fstrim -v --all
			break
			done
		fi
	done
	
	CheckNetwork
	
	#Updates the system
	sudo apt update
	sudo apt upgrade -yy
	sudo apt dist-upgrade -yy
	
	#Optional
	echo "Would you like to restart?(Y/n)"
	read answer 
	if [ $answer == Y ];
	then
		Restart
	else
		clear
		Greeting
	fi

}

Update() {
	CheckNetwork
	
	sudo apt update && sudo apt dist-upgrade -yy
	
	clear
	Greeting
	
}

Systeminfo() {
	#This gives some useful information for later troubleshooting 
	host=$(hostname)
	distribution=$(lsb_release -a | grep "Distributor ID:" | awk -F: '{print $2}')
	echo "##############################################################" >> $host-sysinfo.txt
	echo "SYSTEM INFORMATION" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "USER" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo $USER >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "DISTRIBUTION" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo $distribution >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "DESKTOP_SESSION" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo $DESKTOP_SESSION >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "SYSTEM INITIALIZATION" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	ps -p1 | awk 'NR!=1{print $4}' >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "DATE" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	date >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "KERNEL AND OPERATING SYSTEM INFORMATION" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	uname -a >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "OPERATING SYSTEM RELEASE INFORMATION" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	lsb_release -a >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "HOSTNAME" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	hostname >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "UPTIME" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	uptime -p >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "LOAD AVERAGE" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	cat /proc/loadavg >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "DISK SPACE" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	df -h >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "MEMORY USAGE" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	free -h >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "LISTS ALL BLOCK DEVICES WITH SIZE" >> $host-sysinfo.txt 
	echo "##############################################################" >> $host-sysinfo.txt
	lsblk -o NAME,SIZE >> $host-sysinfo.txt
	echo"" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "BLOCK DEVICE ID " >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	sudo blkid >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "NETWORK CONFIGURATION" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	ip addr >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "NETWORK STATS" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	ss -tulpn >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "FIREWALL STATUS" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	sudo ufw status verbose >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "PROCESS LIST" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	ps -aux >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "LAST LOGIN ATTEMPTS" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	lastlog >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "INSTALLED PACKAGES" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	sudo apt list --installed >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "APPARMOR" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	sudo apparmor_status >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "Inxi" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	inxi -F >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo " DRIVER INFO" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	sudo lsmod >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "USB INFORMATION" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	lsusb >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "HARDWARE INFORMATION" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	lspci >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "MORE HARDWARE INFORMATION" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	sudo lshw >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "EVEN MORE HARDWARE INFORMATION" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	sudo dmidecode >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "YET STILL MORE HARDWARE INFORMATION" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	lscpu >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "TLP STATS" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	sudo tlp-stat >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "LOGS" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	sudo dmesg >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "MORE LOGS" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	journalctl >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "SYSTEMD BOOT INFORMATION" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	systemd-analyze >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "MORE SYSTEMD BOOT INFORMATION" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	systemd-analyze blame >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "SYSTEMD STATUS" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	systemctl status | less >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "SYSTEMD'S FAILED LIST" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	systemctl --failed >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "END OF FILE" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt

	clear 
	Greeting
}

HELP() {
less <<_EOF_

Press "q" to quit

########################################################################
ACKNOWLEDGEMENTS
########################################################################
I wrote these scripts and of course, I had to learn to 
do some of the things in this work. Many of the ideas came from me
but the information came from various other linux users. Without their 
massive contributions to the community, this project of mine would not 
be possible. A list of acknowledgements below:
Joe Collins
Quidsup
SwitchedtoLinux
Matthew Moore
Steven Black
The creator of the other hosts lists I utilize on my own machines. 
Many others... 

########################################################################
WELCOME AND RAMBLE WITH LICENSING
########################################################################
Welcome to Arch-Toolbox. This is a useful little utility that 
tries to setup, maintain, and keep up to date with the latest 
software on your system. Arch-Toolbox is delivered as is and thus, 
I can't be held accountable if something goes wrong. This software is 
freely given under the GPL license and is distributable and changeable 
as you see fit, I only ask that you give the author the credit for the 
original work. Arch-Toolbox has been tested and should work on your 
device assuming that you are running an arch-based system. 
A cronjob is any task or script that you place in the crontab file to be 
ran at a certain time.To not go to deep into it, the basic syntax is 
this:
*     *     *   *    *        command to be executed
-     -     -   -    -
|     |     |   |    |
|     |     |   |    +----- day of week (0 - 6) (Sunday=0)
|     |     |   +------- month (1 - 12)
|     |     +--------- day of        month (1 - 31)
|     +----------- hour (0 - 23)
+------------- min (0 - 59) source: 
http://www.adminschoice.com/crontab-quick-reference
What I normally do is set the hosts updater to run at 8 every night ex.
00 20 * * * /bin/sh /home/$USER/hostsupdater.sh. 
I set it up under the root account by typing su followed by my password 
in manjaro, sudo -i in Ubuntu systems and then typing crontab -e.
The maintenance scripts are ok to run manually each month. 
It is recommended that you do not run these without being present.
Hoever, if you wish to run them as cron jobs then you can tweak the 
cleaning routines as follows."sudo rm -r ./cache/*" should be changed to 
"rm -r /home/$USER/.cache/*" and etc. The setup script should only be 
ran once to set the system up. 

########################################################################
KERNELS AND SERVICES
########################################################################
Kernels, as mentioned in the manager, are an important and integral part 
of the system. For your system to work, it needs to run a certain kernel
I'd suggest the LTS that is recommended or preconfigured by your OS. 
Assuming that you have that kernel installed, testing out newer kernels 
for specific hardware and or security functionality is not a bad idea
just use caution. Disabling services is generally a bad idea, however, 
if you know you do not need it, if it is something like Bluetooth or 
some app that you installed personally and the service is not required
by your system, disabling that service could potentially help speed up
your system. However, I'd advise against disabling system critical 
services.

########################################################################
BACKUP AND RESTORE
########################################################################
Backup and Restore functions are there to provide a quick and painless 
service. The backup will be sent to an alternate drive by your request.
This was designed that way as the working drive could infact become com-
promised and as such, should not be relied on to store important user 
data in the event of an unlikely hack or malware attack, nor under the
event of hardware failure. Having these files on a separate and less 
often used drive is important for security and redundancy. Restore will 
attempt to place that information back on the old drive or a new one if 
or when misfortune should befall you. Just ensure that the drive is a 
usable and safe one and ensure that you have it ready when making 
reparations. So far, the only available option is to Backup the home 
directory, but that might soon change. Please also note that backing up
the home directory can save some user settings as well.

########################################################################
HOSTS FILE MANIPULATION
########################################################################
Setting up a custom hosts file can be selectively simple with the script
Hostsman4linux and the corresponding function HostsfileSelect Both have 
the ability to compile and sort one central file out of multiple source
third party hosts files. These can be a great extra layer to your system
security regimen or can be a helpful adblocking tool allowing your 
browser to be fast and clean from extensions. Running the main script 
yourself is fine, but you have to run it as root. There is no other way
as of yet that I have found to give it proper clearance to manipulate
a secure system file like that without running sudo ./Hostsman4linux.sh.
I am thinking of making the Hostsman4linux script a bit more cron-
friendly in the future. Allowing users to use flags would give users the
ability to make this script run on a schedule and it would always give
them the desired hosts file. Alternatively, if you wish to run this 
script from a menu as a regular user, chmoding the file to 755 might
help before storing it in the /usr/local/bin directory and creating a 
desktop file for it. I'll write a blog article for that later.
to find my blog just go to: https://techiegeek123.blogspot.com/ in a 
browser.

########################################################################
CONTACT ME
########################################################################
For sending me hate mail, for inquiring assistance, and for sending me 
feedback and suggestions, email me at jackharkness444@protonmail.com
or js185r@gmail.com Send your inquiries and suggestions with a 
corresponding subject line.
_EOF_

	clear
	Greeting

}

InstallAndConquer() {
	#This checks network connectivity
	CheckNetwork
	
	#This installs other software that I've found to be useful
	echo "Would you like to install some useful apps?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		echo "1 - Light Weight IDE or text editor"
		echo "2 - rootkit and security checkers"
		echo "3 - Utility Software/Monitoring tools"
		echo "4 - Backup software"
		echo "5 - Web Browsers"
		echo "6 - Media Players"
		echo "7 - Bittorrent Clients"
		echo "8 - Guake terminal"
		echo "9 - video and audio editing"
		echo "10 - preload"
		echo "11 - Webcam application"
		echo "12 - bleachbit cleaning software"
		echo "13 - proprietary fonts"
		echo "14 - THEMES"
		echo "15 - GAMES"
		echo "16 - get out of this menu"

		read software;
	
		case $software in
			1)
			sudo apt install -y geany
		;;
			2)
			echo "1 - rkhunter"
			echo "2 - clamav"
			echo "3 - both"
			read package
			if [[ $package == 1 ]];
			then
				sudo apt install -y rkhunter
			elif [[ $package == 2 ]];
			then
				sudo apt install -y clamav && sudo freshclam
			elif [[ $package == 3 ]];
			then
				sudo apt install -y rkhunter && sudo rkhunter --propupd && sudo rkhunter --update
				sudo apt install -y clamav && sudo freshclam
			fi
		;;
			3)
			sudo apt install -y hddtemp hdparm ncdu nmap hardinfo traceroute gnome-disk-utility  htop iotop inxi xsensors lm-sensors gufw gparted smartmontools
		;;
			4)
			echo "1 - deja-dup"
			echo "2 - bacula"
			echo "3 - backintime"
			echo "4 - timeshift"
			read software
			if [[ $software == 1 ]];
			then
				sudo apt install -y deja-dup
			elif [[ $software == 2 ]];
			then
				sudo apt install -y bacula
			elif [[ $software == 3 ]];
			then
				sudo apt install -y backintime-common
			elif [[ $software == 4 ]];
			then
				sudo apt install timeshift
			fi
			
		;;
			5)
			echo "This installs your choice of browser"
			echo "1 - Chromium"
			echo "2 - Epiphany"
			echo "3 - Qupzilla"
			echo "4 - Midori"
			echo "5 - Google-Chrome"
			echo "6 - Pale Moon"
			echo "7 - Vivaldi"
			echo "8 - Vivaldi-snapshot"
			echo "9 - Lynx"
			echo "10 - Dillo"
			echo "11 - Waterfox"
			echo "12 - Basiliks"
			read browser
			if [[ $browser == 1 ]];
			then
				sudo apt install -y chromium-browser
			elif [[ $browser == 2 ]];
			then
				sudo apt install -y epiphany
			elif [[ $browser == 3 ]];
			then
				sudo apt install -y qupzilla
			elif [[ $browser == 4 ]];
			then
				sudo apt install -y midori
			elif [[ $browser == 5 ]];
			then
				cd /tmp
				wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
				sudo dpkg -i *.deb
				sudo apt install -f 
			elif [[ $browser == 6 ]];
			then
				cd Downloads
				wget http://linux.palemoon.org/datastore/release/pminstaller-0.2.4.tar.bz2
				tar -xvjf pminstaller-0.2.3.tar.bz2
				./pminstaller.sh
			elif [[ $browser == 7 ]];
			then
				cd /tmp
				wget https://downloads.vivaldi.com/stable/vivaldi-stable_1.15.1147.36-1_amd64.deb
				sudo dpkg -i *.deb
				sudo apt install -f
			elif [[ $browser == 8 ]];
			then
				cd /tmp
				wget https://downloads.vivaldi.com/snapshot/vivaldi-snapshot_1.16.1246.7-1_amd64.deb
				sudo dpkg -i *.deb
				sudo apt install -f
			elif [[ $browser == 9 ]];
			then
				sudo apt install lynx
			elif [[ $browser == 10 ]];
			then
				sudo apt install dillo
			elif [[ $browser == 11 ]];
			then
				wget https://storage-waterfox.netdna-ssl.com/releases/linux64/installer/waterfox-56.2.2.en-US.linux-x86_64.tar.bz2
				tar -xvf waterfox-56.2.2.en-US.linux-x86_64.tar.bz2
				cd waterfox
				./waterfox #To import any user data you'd like to import first run.
				cd 
				sudo mv waterfox /opt && sudo ln -s /opt/waterfox/waterfox /usr/bin/waterfox #Now just type waterfox in a terminal and it should open
			elif [[ $browser == 12 ]];
			then
				wget us.basilisk-browser.org/release/basilisk-latest.linux64.tar.bz2
				tar -xvf basilisk-latest.linux64.tar.bz2
				cd basilisk
				./basilisk #To import any user data you'd like to import first run
				cd
				sudo mv basilisk /opt && sudo ln -s /opt/basilisk/basilisk /usr/bin/basilisk #Now just type basilisk in a terminal and it should open
			fi
		;;
			6)
			echo "This installs your choice of media players/music players"
			echo "1 - VLC"
			echo "2 - rhythmbox"
			echo "3 - banshee"
			echo "4 - parole"
			echo "5 - clementine"
			echo "6 - mplayer"
			echo "7 - smplayer"
			echo "8 - kodi"
			read player
			if [[ $player == 1 ]];
			then
				sudo apt install -y vlc
			elif [[ $player == 2 ]];
			then
				sudo apt install -y rhythmbox
			elif [[ $player == 3 ]];
			then
				sudo apt install -y banshee
			elif [[ $player == 4 ]];
			then
				sudo apt install -y parole
			elif [[ $player == 5 ]];
			then
				sudo apt install -y clementine
			elif [[ $player == 6 ]];
			then
				sudo apt-get -y install mplayer
			elif [[ $player == 7 ]];
			then
				sudo add-apt-repository ppa:rvm/smplayer
				sudo apt update
				sudo apt install smplayer smplayer-themes smplayer-skins
			elif [[ $player == 8 ]];
			then
				sudo apt-get install software-properties-common
				sudo add-apt-repository ppa:team-xbmc/ppa
				sudo apt-get update
				sudo apt-get -y install kodi
			fi
		;;
			7)
			echo "This installs your choice of bittorrent client"
			echo "1 - transmission-gtk"
			echo "2 - deluge"
			echo "3 - qbittorrent"
			read client
			if [[ $client == 1 ]];
			then
				sudo apt-get -y install transmission-gtk
			elif [[ $client == 2 ]];
			then
				sudo apt-get -y install deluge
			elif [[ $client == 3 ]];
			then
				sudo apt-get -y install qbittorrent
			fi
		;;
			8)
			sudo apt install -y guake
		;;
			9)
			sudo apt install -y kdenlive audacity obs-studio
		;;
			10)
			sudo apt install -y preload
		;;
			11)
			sudo apt install -y guvcview
		;;
			12)
			sudo apt install -y bleachbit
		;;
			13)
			sudo apt install -y ttf-mscorefonts-installer
		;;
			
			14)
			echo "THEMES"
			sudo add-apt-repository ppa:noobslab/icons
			sudo add-apt-repository ppa:noobslab/icons
			sudo add-apt-repository ppa:noobslab/icons
			sudo add-apt-repository ppa:papirus/papirus
			sudo add-apt-repository ppa:moka/daily
			sudo apt-get update
			sudo apt-get install -y mate-themes faenza-icon-theme obsidian-1-icons dalisha-icons shadow-icon-theme moka-icon-theme papirus-icon-theme
		;;
			15)
			echo "Installs your choice in linux games"
			echo "1 - supertuxkart"
			echo "2 - gnome-mahjongg"
			echo "3 - aisleriot"
			echo "4 - ace of penguins"
			echo "5 - gnome-sudoku"
			echo "6 - gnome-mines"
			echo "7 - chromium-bsu"
			echo "8 - supertux"
			echo "9 - Everything plus steam"
			read package
			if [[ package == 1 ]];
			then
				sudo apt-get -y install supertuxkart
			elif [[ $package == 2 ]];
			then
				sudo apt-get -y install gnome-mahjongg
			elif [[ $package == 3 ]];
			then
				sudo apt-get -y install aisleriot
			elif [[ $package == 4 ]];
			then
				sudo apt-get -y install ace-of-penguins
			elif [[ $package == 5 ]];
			then
				sudo apt-get -y install gnome-sudoku
			elif [[ $package == 6 ]];
			then
				sudo apt-get -y install gnome-mines
			elif [[ $package == 7 ]];
			then
				sudo apt-get -y install chromium-bsu
			elif [[ $package == 8 ]];
			then
				sudo apt-get -y install supertux
			elif [[ $package == 9 ]];
			then
				sudo apt-get install -y supertuxkart gnome-mahjongg aisleriot ace-of-penguins gnome-sudoku gnome-mines chromium-bsu supertux steam
			else 
				echo "You have entered an invalid number, please come back later and try again."
			fi
		;;
			16)
			echo "Alright den!"
			break
		;;
		esac
	done
	
	#This can install screenfetch
	echo "Would you like to install screenfetch?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		sudo apt install -y screenfetch
	break
	done
	
	#This installs software we might have missed
	echo "If you'd like to contribute to the previous list of software,
	contact me: jackharkness444@protonmail.com"	
	echo "Is there any other software you'd like to install?(Y/n)"
	read answer 
	while [ $answer == Y ];
	do 
		echo "Enter the name of the software you wish to install"
		read software
		sudo apt install -y $software
	break
	done

	#This tries to install codecs
	echo "This will install codecs." 
	echo "These depend upon your environment."
	echo "Would you like me to continue?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		for env in $DESKTOP_SESSION;
		do
			if [[ $DESKTOP_SESSION == unity ]];
			then
				sudo apt install -y ubuntu-restricted-extras
			elif [[ $DESKTOP_SESSION == xfce ]];
			then
				sudo apt install -y xubuntu-restricted-extras
				sudo apt install -y xfce4-goodies
			elif [[ $DESKTOP_SESSION == kde ]];
			then
				sudo apt install -y kubuntu-restricted-extras
			elif [[ $DESKTOP_SESSION == lxde ]];
			then 
				sudo apt install -y lubuntu-restricted-extras
			elif [[ $DESKTOP_SESSION == mate ]];
			then
				sudo apt install -y ubuntu-restricted-extras
			elif [[ $DESKTOP_SESSION == gnome ]];
			then
				sudo apt install -y ubuntu-restricted-extras gnome-session gnome-tweak-tool gnome-shell-extensions
			elif [[ $DESKTOP_SESSION == enlightenment ]];
			then
				sudo apt install -y ubuntu-restricted-extras
			elif [[ $DESKTOP_SESSION == Budgie ]];
			then
				sudo apt install -y ubuntu-restricted-extras
			elif [[ $DESKTOP_SESSION == Cinnamon ]];
			then
				sudo apt install -y ubuntu-restricted-extras gnome-tweak-tool
			else
				echo "You're running some other window manager I haven't tested yet."
				sleep 1
			fi
		done
		
		echo "If you're running Mint, it's a good idea to install the mint meta package"
		distribution=$(lsb_release -a | grep "Distributor ID:" | awk -F: '{print $2}')
		if [[ $distribution == LinuxMint ]];
		then
			sudo apt install -y mint-meta-codecs
		fi
	break
	done 
	
	clear
	Greeting
	
}

AccountSettings() {
cat <<_EOF_
This is a completely untested and experimental utility at best. 
Use this function "Account Settings" at your own risk. 
_EOF_
	#This can create and remove user accounts
	echo "This is experimental(untested). Use at  your own risk."
	echo "What would you like to do today?"
	echo "1 - Create user account(s)" 
	echo "2 - Delete user account(s)"
	echo "3 - Lock pesky user accounts"
	echo "4 - Look for empty password users on the system"
	echo "5 - skip this menu"
	
	read operation;
	
	case $operation in
		1)
		echo $(cat /etc/group | awk -F: '{print $1}')
		sleep 3
		read -p "Please enter the groups you wish the user to be in:" $group1 $group2 $group3 $group4 $group5
		echo "Please enter the name of the user"
		read name
		echo "Please enter the password"
		read password
		sudo useradd $name -m -s /bin/bash -G $group1 $group2 $group3 $group4 $group5
		echo $password | passwd --stdin $name
	;;
		2)
		echo "Note, this will remove all files related to the account"
		echo "Please enter the name of the user you wish to delete"
		read name
		sudo userdel -rf $name
	;;
		3)
		echo "Alternatively, we can lock a specific user account for security"
		read -p "Enter the account you wish to lock:" $account
		sudo passwd -l $account
	;;
		4)
		sudo cat /etc/shadow | awk -F: '($2==""){print $1}' >> ~/accounts.txt
		cat /etc/passwd | awk -F: '{print $1}' >> ~/accounts.txt
	;;
		5)
		echo "We can do this later"
	;;
		*)
		echo "This is an invaldi selection, please run this function again and try another."
	;;
	esac
	
	clear
	Greeting
}

CheckNetwork() {
	for c in computer; 
	do 
		ping -c4 google.com > /dev/null
		if [[ $? -eq 0 ]];
		then 
			echo "Connection successful!"
		else
			interface=$(ip -o -4 route show to default | awk '{print $5}')
			sudo dhclient -v -r && sudo dhclient
			sudo mmcli nm enable false 
			sudo nmcli nm enable true
			sudo /etc/init.d/ network-manager restart
			sudo ip link set $interface up #Refer to networkconfig.log
		fi
	done

}

HostsfileSelect() {
	find Hostsman4linux.sh
	while [ $? -eq 1 ];
	do
		wget https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hostsman4linux.sh
		chmod +x Hostsman4linux.sh
	break
	done
	sudo ./Hostsman4linux.sh
	
	clear
	Greeting
}

cleanup() {
	#This flushes apt cache
	sudo apt autoremove -y
	sudo apt autoclean -y
	sudo apt clean -y

	#This allows you to remove unwanted junk
	echo "Are there any other applications you wish to remove(Y/n)"
	read answer 
	while [ $answer ==  Y ];
	do
		echo "Please enter the name of the software you wish to remove"
        read software
		sudo apt -y remove --purge $software
	break
	done

	#This clears the cache and thumbnails and other junk
	sudo rm -r .cache/*
	sudo rm -r .thumbnails/*
	sudo rm -r ~/.local/share/Trash
	sudo rm -r ~/.nv/*
	sudo rm -r ~/.npm/*
	sudo rm -r ~/.w3m/*
	sudo rm -r ~/.esd_auth #Best I can tell cookie for pulse audio
	sudo rm -r ~/.local/share/recently-used.xbel
	sudo rm -r /tmp/*
	find ~/Downloads/* -mtime +3 -exec rm {} \; 
	history -cw && cat /dev/null/ > ~/.bash_history
	
	#This clears the cached RAM 
	read -p "This will free up cached RAM. Press enter to continue..."
	sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches"

	#This could clean your Video folder and Picture folder based on a set time
	TRASHCAN=~/.local/share/Trash/
	find ~/Video/* -mtime +30 -exec mv {} $TRASHCAN \; 
	find ~/Pictures/* -mtime +30 -exec mv {} $TRASHCAN \;

	#check for and remove broken symlinks
	find -xtype l -delete

	#clean some unneccessary files leftover by applications in home directory
	find $HOME -type f -name "*~" -print -exec rm {} \;
 
	#This trims the journal logs
	sudo journalctl --vacuum-size=25M #For newer systemd releases
	
	clear
	Greeting
}

BrowserRepair() {
cat << _EOF_
This can fix a lot of the usual issues with a few of the bigger browsers. 
These can include performance hitting issues. If your browser needs a tuneup,
it is probably best to do it in the browser itself, but when you just want something
fast, this can do it for you. More browsers and options are coming.
_EOF_

	#Look for the following browsers
	browser1="$(find /usr/bin/firefox)"
	browser2="$(find /usr/bin/vivaldi*)"
	browser3="$(find /usr/bin/palemoon)"
	browser4="$(find /usr/bin/google-chrome*)"
	browser5="$(find /usr/bin/chromium)"
	browser6="$(find /usr/bin/opera)"
	browser7="$(find /usr/bin/waterfox)"

	echo $browser1
	echo $browser2
	echo $browser3
	echo $browser4
	echo $browser5
	echo $browser6
	echo $browser7

	sleep 1

	echo "choose the browser you wish to reset"
	echo "1 - Firefox"
	echo "2 - Vivaldi" 
	echo "3 - Pale Moon"
	echo "4 - Chrome"
	echo "5 - Chromium"
	echo "6 - Opera"
	echo "7 - Vivaldi-snapshot"
	echo "8 - Waterfox"

	read operation;

	case $operation in
		1)
		sudo cp -r ~/.mozilla/firefox ~/.mozilla/firefox-old
		sudo rm -r ~/.mozilla/firefox/profile.ini 
		echo "Your browser has now been reset"
		sleep 1
	;;
		2)
		sudo cp -r ~/.config/vivaldi/ ~/.config/vivaldi-old
		sudo rm -r ~/.config/vivaldi/* 
		echo "Your browser has now been reset"
		sleep 1
	;;
		3)
		sudo cp -r ~/'.moonchild productions'/'pale moon' ~/'.moonchild productions'/'pale moon'-old
		sudo rm -r ~/'.moonchild productions'/'pale moon'/profile.ini 
		echo "Your browser has now been reset"
		sleep 1
	;;	
		4)
		sudo cp -r ~/.config/google-chrome ~/.config/google-chrome-old
		sudo rm -r ~/.config/google-chrome/*
		echo "Your browser has now been reset"
		sleep 1 
	;;
		5)
		sudo cp -r ~/.config/chromium ~/.config/chromium-old
		sudo rm -r ~/.config/chromium/*
		echo "Your browser has now been reset"
		sleep 1
	;;
		6)
		sudo cp -r ~/.config/opera ~/.config/opera-old
		sudo rm -r ~/.config/opera/* 
		echo "Your browser has now been reset"
		sleep 1
	;;	
		7)
		sudo cp -r ~/.config/vivaldi-snapshot ~/.config/vivaldi-snapshot-old
		sudo rm -r ~/.config/vivaldi-snapshot/*
		echo "Your browser has now been reset"
		sleep 1
	;;
		8)
		sudo cp -r ~/.waterfox ~/.waterfox-old
		sudo rm -r ~/.waterfox/*
		echo "Your browser has now been reset"
		sleep 1
	;;
		*)
		echo "No browser for that entry exists, please try again"
		sleep 1
		clear
		Greeting
	;;
	esac
	
	#Change the default browser
	echo "Would you like to change your default browser also?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		echo "Enter the name of the browser you wish to use"
		read browser
		sudo update-alternatives --set x-www-browser /usr/bin/$browser
	break
	done

	clear
	Greeting

}

SystemMaintenance() {
	CheckNetwork
	
	#This updates your system
	sudo dpkg --configure -a
	sudo apt install  -f
	sudo apt update && sudo apt dist-upgrade -yy

	#It is recommended that your firewall is enabled
	sudo ufw reload
	
	#This restarts systemd daemon. This can be useful for different reasons.
	sudo systemctl daemon-reload #For systemd releases
	
	#This runs update db for index cache and cleans the manual database
	sudo updatedb && sudo mandb
	
	#This updates grub
	sudo update-grub2 

	#Checks disk for errors
	sudo touch /forcefsck
	
	#Optional and prolly not needed
	drive=$(cat /sys/block/sda/queue/rotational)
	for rota in drive;
	do
		if [[ $drive == 1 ]];
		then
			echo "Would you like to check fragmentation levels?(Y/n)"
			read answer 
			while [ $answer == Y ];
			do
				sudo e4defrag / -c > fragmentation.log 
			break
			done
		elif [[ $drive == 0 ]];
		then
			echo "Would you also like to run trim?(Y/n)"
			read answer
			while [ $answer == Y ];
			do
				sudo fstrim -v --all
			break
			done
		fi 
	done
	
	#Optional
	echo "Would you like to run cleanup?(Y/n)"
	read answer
	if [[ $answer == Y ]];
	then
		cleanup
	else
		clear
		Greeting
	fi
}

ServiceManager() {
	#This is for service management. Prolly not a good idea but...
cat <<_EOF_
This is usually better off left undone, only disable services you know 
you will not need or miss. I can not be held responsible if you brick 
your system. Handle with caution. Also, may only take effect once you 
reboot your machine. Services can be turned back on with a good backup 
and possibly by chrooting into the device via live cd and reversing the 
process by running this again and reenabling the service.
_EOF_

	init=$(ps -p1 | awk 'NR!=1{print $4}')
	for init in $init;
	do
		if [[ $init == upstart ]];
		then
			service --status-all
			read -p "Press enter to continue..."
			echo "What would you like to do?"
			echo "1 - Enable services"
			echo "2 - Disable services"
			echo "3 - create a list of all services running on your system"
			echo "4 - Nothing just get me out of this menu"

			read operation;

			case $operation in
				1) 
				echo "Enter the name of the service you wish to enable"
				read service
				sudo /etc/init.d/$service start
			;;
				2)
				echo "Enter the name of the service you wish to disable"
				read service
				sudo /etc/init.d/$service stop 
				echo "Optionally we can create an override which will keep this setting"
				echo "Would you like to retain this setting after reboot?(Y/n)"
				read answer
				while [ $answer == Y ];
				do
					echo manual | sudo tee /etc/init/$service.override
				break
				done
			;;
				3)
				echo "##################################################" >> services.txt
				echo "SERVICE MANAGER" >> services.txt
				echo "##################################################" >> services.txt
				service --status-all >> services.txt
				systemctl list-unit-files --type=service >> services.txt
				echo "##################################################" >> services.txt
				echo "END OF FILE" >> services.txt
				echo "##################################################" >> services.txt
			;;
				4)
				echo "Great choice"
			;;
			esac
		elif [[ $init == systemd ]];
		then
			systemctl list-unit-files --type=service
			read -p "Press enter to continue..."
			echo "What would you like to do?"
			echo "1 - Enable services"
			echo "2 - Disable services"
			echo "3 - create a list of all services running on your system"
			echo "4 - Nothing just get me out of this menu"

			read operation;

			case $operation in
				1)
				echo "Enter the name of the service you wish to enable"
				read service
				sudo systemctl enable $service
				sudo systemctl start $service
			;;
				2)
				echo "Enter the name of the service you wish to disable"
				read service
				sudo systemctl stop $service
				sudo systemctl disable $service
			;;
				3)
				echo "##################################################" >> services.txt
				echo "SERVICE MANAGER" >> services.txt
				echo "##################################################" >> services.txt
				systemctl list-unit-files --type=service >> services.txt
				echo "##################################################" >> services.txt
				echo "END OF FILE" >> services.txt
				echo "##################################################" >> services.txt
			;;
				4)
				echo "Nice!!!!!"
			;;
			esac
		else
			echo "You might be running an init system I haven't tested yet"
		fi
	done

	clear
	Greeting
}

Restart() { 
	sudo sync && sudo systemctl reboot
}

Backup() { 
	#This tries to backup your system
	host=$(hostname)
	Mountpoint=$(lsblk |awk '{print $7}' | grep /run/media/$USER/*)
	if [[ $Mountpoint != /run/media/$USER/* ]];
	then
		read -p "Please insert a drive and hit enter"
		echo $(lsblk | awk '{print $1}')
		sleep 1 
		echo "Please select the device you wish to use"
		read device
		sudo mount $device /mnt
		sudo rsync -aAXv --delete --exclude={"*.cache/*","*.thumbnails/*"."*/.local/share/Trash/*"} /home/$USER /mnt/$host-backups
	elif [[ $Mountpoint == /run/media/$USER/* ]];
	then
		echo "Found a block device at designated coordinates... If this is the preferred
		device, try umounting it, leave it plugged in, and then running this again. Press enter to continue..."
	fi
	
	clear
	Greeting
}

Restore() { 
		#This tries to restore the home folder
cat <<_EOF_
This tries to restore the home folder and nothing else, if you want to 
restore the entire system,  you will have to do that in a live environment.
This can, however, help in circumstances where you have family photos and
school work stored in the home directory. This also assumes that your home
directory is on the drive in question. This can also restore browser settings 
including unwanted toolbars so be warned. 
_EOF_

	Mountpoint=$(lsblk | awk '{print $7}' | grep /run/media/$USER/*)
	if [[ $Mountpoint != /run/media/$USER/* ]];
	then
		read -p "Please insert the backup drive and hit enter..."
		echo $(lsblk | awk '{print $1}')
		sleep 1
		echo "Please select the device from the list"
		read device
		sudo mount $device /mnt 
		sudo rsync -aAXv --delete --exclude={"*.cache/*","*.thumbnails/*"."*/.local/share/Trash/*"} /mnt/$host-backups/* /home
		sudo sync
		Restart
	elif [[ $Mountpoint == /run/media/$USER/* ]];
	then
		read -p "Found a block device at designated coordinates... If this is the preferred
		device, try umounting it, leaving it plugged in, and then running this again. Press enter to continue..."
	fi 
}

Greeting() {
	echo "Enter a selection from the following list"
	echo "1 - Setup your system"
	echo "2 - Add/Remove user accounts"
	echo "3 - Install software"
	echo "4 - Setup a hosts file"
	echo "5 - Backup your system"
	echo "6 - Restore your system"
	echo "7 - Manage system services"
	echo "8 - Collect System Information"
	echo "9 - Help"
	echo "10 - Cleanup"
	echo "11 - System Maintenance"
	echo "12 - Browser Repair"
	echo "13 - Update"
	echo "14 - exit"
	
	read selection;
	
	case $selection in
		1)
		Setup
	;;
		2)
		AccountSettings
	;;
		3)
		InstallAndConquer
	;;
		4)
		HostsfileSelect
	;;
		5)
		Backup
	;;
		6)
		Restore
	;;
		7)
		ServiceManager
	;;
		8)
		Systeminfo
	;;
		9)
		HELP
	;;
		10)
		cleanup
	;;
		11)
		SystemMaintenance
	;;
		12)
		BrowserRepair
	;;
		13)
		Update
	;;
		14)
		echo "Thank you for using Ubuntu-Toolbox... Goodbye!"
		sleep 1
		exit
	;;
		*)
		echo "This is an invalid number, please try again."
		sleep 1
		clear 
		Greeting
	;;
	esac
}

echo "Hello!"
Greeting


