#!/bin/bash

Setup() {
	#Sets default editor to nano in bashrc
	echo "export EDITOR=nano" | sudo tee -a /etc/bash.bashrc

	#This sets up your system time.
	echo "Would you like to set ntp to true? (Y/n)"
	read answer
	while [ $answer == Y ];
	do
	    echo "Enter your preferred timezone"
		read timezone
		sudo timedatectl set-ntp true; sudo timedatectl set-timezone $timezone
	break
	done

	#This starts your firewall
    eopkg list-installed | grep gufw || sudo eopkg install gufw
	sudo systemctl enable ufw; sudo ufw enable
    echo "Would you also like to deny ssh and telnet for security?(Y/n)"
    read answer
    while [ $answer == Y ]
    do
      sudo ufw deny ssh; sudo ufw deny telnet; sudo ufw reload
    break
    done

	#This restricts coredumps to prevent attackers from getting info
	sudo cp /etc/systemd/coredump.conf /etc/systemd/coredump.conf.bak
	sudo sed -i -e '/#Storage=external/c\Storage=none ' /etc/systemd/coredump.conf
	sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
	sudo sed -i -e '/#PermitRootLogin/c\PermitRootLogin no ' /etc/ssh/sshd_config
	sudo touch /etc/sysctl.d/50-dmesg-restrict.conf
	sudo touch /etc/sysctl.d/50-kptr-restrict.conf
	sudo touch /etc/sysctl.d/99-sysctl.conf
    sudo touch /etc/syctl.d/60-network-hardening.conf
	echo "kernel.dmesg_restrict = 1" | sudo tee -a /etc/sysctl.d/50-dmesg-restrict.conf
	echo "kernel.kptr_restrict = 1" | sudo tee -a /etc/sysctl.d/50-kptr-restrict.conf
	echo "vm.swappiness = 5" | sudo tee -a /etc/sysctl.d/99-sysctl.conf #lowers swap value
	sudo sysctl -p

    #WE can block ICMP requests from the kernel if you'd like
cat <<_EOF_
Ping requests from unknown sources could mean that people are trying to
locate/attack your network. If you need this functionality, you can comment
this line out, however, this shouldn't impact normal users. If you blocked ICMP traffic
in Iptables or UFW, you really don't need this here.
_EOF_
    echo "Block icmp ping requests?(Y/n)"
    read answer
    while [ $answer == Y ];
    do
        sudo touch /etc/syctl.d/60-network-hardening.conf
        echo "net.ipv4.icmp_echo_ignore_all = 1" | sudo tee -a /etc/sysctl.d/60-network-hardening.conf
        sudo sysctl -p
    break
    done

	#This disables ipv6
	echo "Sometimes ipv6 can cause network issues. Would you like to disable it?(Y/n)"
	read answer
	if [[ $answer == Y ]];
	then
		sudo cp /etc/default/grub /etc/default/grub.bak
		sudo sed -i -e 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="ipv6.disable=1"/g' /etc/default/grub
		sudo update-grub
	else
		echo "OKAY!"
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
			echo "Would you like to enable Trim?(Y/n)"
			read answer
			while [ $answer == Y ];
			do
				sudo systemctl enable fstrim.timer; sudo systemctl start fstrim.timer
			break
			done
		fi
	done

	#This tweaks the journal file for efficiency
	echo "Would you like to limit the journal file from becoming too large?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		sudo cp /etc/systemd/journald.conf /etc/systemd/journald.conf.bak
		sudo sed -i -e '/#SystemMaxUse=/c\SystemMaxUse=50M ' /etc/systemd/journald.conf
		break
	done

	#This allows you to install the latest LTS kernel in Solus
	cat <<_EOF_
	LTS Kernels are those kernels which receive security patches for prolonged periods.
	Where kernel modules and headers do receive periodic updates, the overall
	system and user experience remains mostly unaffected. These kernels are
	handy for older systems or new users who experience driver incompatibilities with the latest
	kernels. CAUTION: Installing kernels should be done with caution and a back up should
	be ready should anything go wrong. You have been warned.
_EOF_
	echo "Would you like to install the latest LTS kernel stack?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		sudo eopkg install linux-lts linux-lts-headers
		echo "This keeps your current kernel in tact"
	break
	done

	#This removes that retarded gnome-keyring unlock error you get with chrome
	echo "Killing this might make your passwords less secure on chrome."
	sleep 1
	echo "Do you wish to kill gnome-keyring? (Y/n)"
	read answer
	if [[ $answer == Y ]];
	then
		sudo mv /usr/bin/gnome-keyring-daemon /usr/bin/gnome-keyring-daemon-old; sudo killall gnome-keyring-daemon
	else
		echo "Proceeding"
	fi

	#This allows you to add aliases to .bashrc
	echo "Aliases are shortcuts for commonly used commands."
	echo "Would you like to add some commonly used aliases?(Y/n)"
	read answer
	if [[ $answer == Y ]];
	then
		sudo cp ~/.bashrc ~/.bashrc.bak
		echo "#Alias to edit fstab" >> ~/.bashrc
		echo 'alias fstab="sudo nano /etc/fstab"' >> ~/.bashrc
		echo "#Alias to edit grub" >> ~/.bashrc
		echo 'alias grub="sudo nano /etc/default/grub"' >> ~/.bashrc
		echo "#Alias to update grub" >> ~/.bashrc
		echo 'alias grubup="sudo update-grub"' >> ~/.bashrc
		echo "#Alias to update the system" >> ~/.bashrc
		echo 'alias update="sudo eopkg upgrade"' >> ~/.bashrc
		echo "#Alias to clear package cache" >> ~/.bashrc
		echo 'alias cleanse="sudo eopkg delete-cache"' >> ~/.bashrc
		echo "#Alias to remove orphaned packages" >> ~/.bashrc
		echo 'alias orphaned="sudo eopkg remove-orphaned"' >> ~/.bashrc
		echo "#Alias to check installation integrity of software" >> ~/.bashrc
		echo 'alias convey="sudo eopkg check"' >> ~/.bashrc
		echo "#Alias to rebuild the database" >> ~/.bashrc
		echo 'alias rebuild="sudo eopkg rebuild-db"' >> ~/.bashrc
		echo "#Alias to check package integrity" >> ~/.bashrc
		echo 'alias check="sudo eopkg check"' >> ~/.bashrc
		echo "#Alias to free RAM cache" >> ~/.bashrc
		echo 'alias boost="sudo sync; echo 3 > /proc/sys/vm/drop_caches; sudo swapoff -a && sudo swapon -a"' >> ~/.bashrc
		echo "#Alias to trim journal size" >> ~/.bashrc
		echo 'alias vacuum="sudo journalctl --vacuum-size=25M"' >> ~/.bashrc
	fi

	checkNetwork

	#This tries to update repositories and upgrade the system
	sudo eopkg rebuild-db; sudo eopkg update-repo; sudo eopkg upgrade

	#Optional
	echo "Do you wish to reboot(Y/n)"
	read answer
	if [[ $answer == Y ]];
	then
		Restart
	else
		clear
		Greeting
	fi

}

Update() {
	checkNetwork

	sudo eopkg upgrade

	clear
	Greeting

}

Reset() {
#This resets the desktop
if [[ $DESKTOP_SESSION == budgie ]];
then
	echo "########################################################################"
	echo "This resets Budgie"
	echo "########################################################################"
	dconf dump /org/budgie/ > budgie-desktop-backup; dconf reset -f /org/budgie
elif [[ $DESKTOP_SESSION == gnome ]];
then
	echo "########################################################################"
	echo "This resets Gnome Shell"
	echo "########################################################################"
	dconf dump /org/gnome/ > gnome-desktop-backup; dconf reset -f /org/gnome
elif [[ $DESKTOP_SESSION == xfce ]];
then
	echo "#######################################################################"
	echo "This resets MATE"
	echo "#######################################################################"
	dconf dump /org/mate/ > mate-desktop-backup; dconf reset -f /org/mate
else
	echo "You're running a desktop/Window Manager that we do not yet support... Come back later."
fi
}

Systeminfo() {
	#This gives some useful information for later troubleshooting
	host=$(hostname)
	distribution=$(lsb_release -a | grep "Description:" | awk -F: '{print $2}')
	echo "##############################################################" >> $host-sysinfo.txt
	echo "SYSTEM INFORMATION" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "DATE"  >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	date >> $host-sysinfo.txt
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
	echo "DESKTOP" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo $DESKTOP_SESSION >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "SYSTEM INITIALIZATION" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	ps -p1 | awk 'NR!=1{print $4}' >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "KERNEL AND OPERATING SYSTEM INFORMATION" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	uname -a >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "OS/MACHINE INFO" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	hostnamectl >> $host-sysinfo.txt
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
	echo "DISK SECTOR INFORMATION" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	sudo fdisk -l >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "DISK SPACE" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	df -h >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "SMART DATA" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	sudo smartctl -A /dev/sda >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "DIRECTORY USAGE" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	du -sh >> $host-sysinfo.txt
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
	echo "DNS INFO" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	dig | grep SERVER >> $host-sysinfo.txt
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
	eopkg list-installed >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "PACKAGE MANAGER HISTORY" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	cat /var/log/eopkg.log >> $host-sysinfo.txt
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
	echo "CPU TEMP" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	sensors >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "HD TEMP" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	sudo hddtemp /dev/sda >> $host-sysinfo.txt
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
	echo "MEMORY INFOMRATION" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	cat /proc/meminfo >> $host-sysinfo.txt
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

InstallAndConquer() {
	checkNetwork

	#This installs extra software
	echo "Would you like to install software?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		echo "1 - Utility suite/Monitoring Software"
		echo "2 - IDE or text/code editor"
		echo "3 - Download managers"
		echo "4 - Torrent clients"
		echo "5 - Chat"
		echo "6 - Web browser from a list"
		echo "7 - Media/home theater software"
		echo "8 - Virtual machine client"
		echo "9 - Wine and play on linux"
		echo "10 - quvcview"
		echo "11 - GAMES!!!!!!!!!"
		echo "12 - Video editing/encoding"
		echo "13 - Plank"
		echo "14 - Proprietary Fonts"
		echo "15 - Backup"
		echo "16 - THEMES!!!!!!!!"
		echo "17 - screenfetch"
		echo "18 - Stellarium constellation and space observation"
		echo "19 - exit out of this menu"

	read software;

	case $software in
		1)
		echo "This installs a choice of utility software"
		sudo eopkg install --reinstall mtr lshw hdparm gparted gnome-disk-utility ncdu nmap smartmontools htop inxi gufw
		sudo snap install youtube-dl
	;;
		2)
		echo "This installs a light weight editor(text/code editor/IDE)"
		echo "1 - geany"
		echo "2 - bluefish"
		echo "3 - atom"
		echo "4 - kate"
		echo "5 - Sublime-text"
		read package
		if [[ $package == 1 ]];
		then
			sudo eopkg install geany
		elif [[ $package == 2 ]];
		then
			sudo eopkg install bluefish
		elif [[ $package == 3 ]];
		then
			sudo eopkg install atom
		elif [[ $package == 4 ]];
		then
			sudo eopkg install kate
		elif [[ $package == 5 ]];
		then
			sudo eopkg bi --ignore-safety https://raw.githubusercontent.com/getsolus/3rd-party/master/programming/sublime-text-3/pspec.xml; sudo eopkg it webstorm*.eopkg;sudo rm webstorm*.eopkg
		else
			echo "You've entered an invalid number"
		fi
	;;
		3)
		echo "This installs a choice in download managers"
		echo "1 - wget"
		echo "2 - uget"
		read software
		if [[ $software == 1 ]];
		then
			sudo eopkg install wget #Usually already installed
		elif [[ $software == 2 ]];
		then
			sudo eopkg install uget
		else
			echo "You have entered an invalid number"
		fi
	;;
		4)
		echo "This installs your choice of torrent clients"
		echo "1 - transmission"
		echo "2 - deluge"
		echo "3 - qbittorrent"
		read client
		if [[ $client == 1 ]];
		then
			sudo eopkg install transmission
		elif [[ $client == 2 ]];
		then
			sudo eopkg install deluge
		elif [[ $client == 3 ]];
		then
			sudo eopkg install qbittorrent
		else
			echo "You have entered an invalid number"
		fi
	;;
		5)
		echo "This installs a chat/face-time program"
		echo "1 - HexChat"
		echo "2 - Skype"
		read package
		if [[ $package == 1 ]];
		then
			sudo eopkg install hexchat
		elif [[ $package == 2 ]];
		then
			sudo eopkg bi --ignore-safety https://raw.githubusercontent.com/getsolus/3rd-party/master/network/im/skype/pspec.xml; sudo eopkg it skype*.eopkg;sudo rm *.eopkg
		fi
	;;
		6)
		echo "This installs your choice in browsers"
		echo "1 - epiphany"
		echo "2 - falkon"
		echo "3 - midori"
		echo "4 - opera"
		echo "5 - vivaldi-snapshot"
		echo "6 - lynx"
		echo "7 - vivaldi"
		echo "8 - google-chrome"
		echo "9 - chromium"
		echo "10 - waterfox"
		echo "11 - basilisk"
		echo "12 - palemoon"
		echo "13 - firefox"
		read browser
		if [[ $browser == 1 ]];
		then
			sudo eopkg install epiphany
		elif [[ $browser == 2 ]];
		then
			sudo eopkg install falkon
		elif [[ $browser == 3 ]];
		then
			sudo eopkg install midori
		elif [[ $browser == 4 ]];
		then
			sudo eopkg install opera-stable
		elif [[ $browser == 5 ]];
		then
			wget https://downloads.vivaldi.com/snapshot/install-vivaldi.sh; chmod +x install-vivaldi.sh
			./install-vivaldi.sh
		elif [[ $browser == 6 ]];
		then
			sudo eopkg install lynx
		elif [[ $browser == 7 ]];
		then
			sudo eopkg install vivaldi-stable
		elif [[ $browser == 8 ]];
		then
			sudo eopkg bi --ignore-safety https://raw.githubusercontent.com/getsolus/3rd-party/master/network/web/browser/google-chrome-stable/pspec.xml
			sudo eopkg it google-chrome-*.eopkg;sudo rm google-chrome-*.eopkg
		elif [[ $browser == 9 ]];
		then
			sudo snap install chromium
		elif [[ $browser == 10 ]];
		then
			wget https://storage-waterfox.netdna-ssl.com/releases/linux64/installer/waterfox-56.2.7.1.en-US.linux-x86_64.tar.bz2
			tar -xvf waterfox-56.2.7.1.en-US.linux-x86_64.tar.bz2; sudo mv waterfox /opt && sudo ln -s /opt/waterfox/waterfox /usr/bin/waterfox
			wget https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/waterfox.desktop; sudo mv waterfox.desktop /usr/share/applications/waterfox.desktop
		elif [[ $browser == 11 ]];
		then
			wget us.basilisk-browser.org/release/basilisk-latest.linux64.tar.bz2
			tar -xvf basilisk-latest.linux64.tar.bz2; sudo mv basilisk /opt && sudo ln -s /opt/basilisk/basilisk /usr/bin/basilisk
			wget https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/basilisk.desktop; sudo mv basilisk.desktop /usr/share/applications/basilisk.desktop
		elif [[ $browser == 12 ]];
		then
			user=$(whoami)
			wget http://linux.palemoon.org/datastore/release/palemoon-28.4.0.linux-x86_64.tar.bz2; tar -xvf palemoon-28.4.0.linux-x86_64.tar.bz2
			sudo ln -s ~/palemoon/palemoon /usr/bin/palemoon
			wget https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/palemoon.desktop; sudo mv palemoon.desktop /usr/share/applications/palemoon.desktop
		elif [[ $browser == 13 ]];
		then
			sudo eopkg install firefox
		else
			echo "You have entered an invalid number"
		fi
	;;
		7)
		echo "This installs a choice in media players"
		echo "1 - kodi"
		echo "2 - spotify"
		echo "3 - rhythmbox"
		echo "4 - mpv"
		echo "5 - smplayer"
		echo "6 - VLC"
		echo "7 - totem"
		echo "8 - strawberry"
		read player
		if [[ $player == 3 ]];
		then
			sudo eopkg install kodi
		elif [[ $player == 2 ]];
		then
			sudo eopkg bi --ignore-safety https://raw.githubusercontent.com/getsolus/3rd-party/master/multimedia/music/spotify/pspec.xml; sudo eopkg it spotify*.eopkg;sudo rm spotify*.eopkg
		elif [[ $player == 3 ]];
		then
			sudo eopkg install rhythmbox
		elif [[ $player == 4 ]];
		then
			sudo eopkg install mpv
		elif [[ $player == 5 ]];
		then
			sudo eopkg install smplayer
		elif [[ $player == 6 ]];
		then
			sudo eopkg install vlc
		elif [[ $player == 7 ]];
		then
			sudo eopkg install totem
		elif [[ $player == 8 ]];
		then
			sudo eopkg install strawberry
		else
			echo "You have entered an invalid number"
		fi
	;;
		8)
		echo "This installs a virtualbox client"
		sudo eopkg install virtualbox

	;;
		9)
		echo "This installs Wine or Windows emulation software"
		echo "1 - Wine"
		echo "2 - playonlinux"
		echo "3 - Both"

		read software;

		case $software in
			1)
			sudo eopkg install wine ;;
			2)
			sudo eopkg install playonlinux ;;
			3)
			sudo eopkg install wine playonlinux ;;
			*)
			echo "You have entered an invalid number" ;;
		esac
	;;
		10)
		echo "This installs a webcam application for laptops"
		sudo eopkg install guvcview

	;;
		11)
		echo "This installs a choice in small games"
		echo "1 - supertuxkart"
		echo "2 - gnome-mahjongg"
		echo "3 - aisleriot"
		echo "4 - ace-of-penguins"
		echo "5 - gnome-sudoku"
		echo "6 - gnome-mines"
		echo "7 - chromium-bsu"
		echo "8 - supertux"
		echo "9 - everything"
		read package
		if [[ $package == 1 ]];
		then
			sudo eopkg install supertuxkart
		elif [[ $package == 2 ]];
		then
			sudo eopkg install gnome-mahjongg
		elif [[ $package == 3 ]];
		then
			sudo eopkg install aisleriot
		elif [[ $package == 4 ]];
		then
			sudo eopkg install ace-of-penguins
		elif [[ $package == 5 ]];
		then
			sudo eopkg install gnome-sudoku
		elif [[ $package == 6 ]];
		then
			sudo eopkg install gnome-mines
		elif [[ $package == 7 ]];
		then
			sudo eopkg install chromium-bsu
		elif [[ $package == 8 ]];
		then
			sudo eopkg install supertux
		elif [[ $package == 9 ]];
		then
			sudo eopkg install supertuxkart gnome-mahjongg aisleriot ace-of-penguins gnome-sudoku gnome-mines chromium-bsu supertux
		else
			echo "You have entered an invalid number"
		fi
	;;
		12)
		echo "This installs video/audio decoding/reencoding software"
		sudo eopkg install kdenlive audacity
		echo "Would you also like obs-studio?(Y/n)"
		read answer
		while [ $answer == Y ];
		do
			sudo eopkg install obs-studio
		break
		done
	;;
		13)
		echo "This installs Microsoft Core Fonts"
		sudo eopkg bi --ignore-safety https://raw.githubusercontent.com/getsolus/3rd-party/master/desktop/font/mscorefonts/pspec.xml
		sudo eopkg it mscorefonts*.eopkg;sudo rm mscorefonts*.eopkg
	;;
		14)
		echo "This installs a dock application"
		sudo eopkg install plank
	;;
		15)
		echo "This installs your backup software"
		echo "1 - deja-dup"
		echo "2 - grsync"
		read package
		if [[ $package == 1 ]];
		then
			sudo eopkg install deja-dup
		elif [[ $package == 2 ]];
		then
			sudo eopkg install grsync
		else
			echo "You have entered an invalid number"
		fi
	;;
		16)
		echo "This installs a few common themes"
		sudo eopkg install adapta-gtk-theme moka-icon-theme faba-icon-theme arc-icon-theme evopop-icon-theme numix-themes-archblue arc-gtk-theme papirus-icon-theme faenza-green-icon-theme
	;;
		17)
		echo "This installs screenfetch"
		sudo eopkg install screenfetch
	;;
		18)
		echo "This installs stellarium incase you are a night sky observer"
		sudo eopkg install stellarium
	;;
		19)
		echo "Ok, well, I'm here if you change your mind"
		break
	;;
	esac
	done

	read -p "Please press enter to continue..."

	#This offers to install preload for storing apps in memory
cat <<_EOF_
Preload is as the name implies, a preloader. This nifty tool can shadow
your uses of the desktop and store bits of applications into memory for
faster future use. This does have its drawbacks though as preload does
take up its own cache of memory. This is debatably better on low end
devices.
_EOF_
	echo "Would you like to install preload?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		sudo eopkg install preload && sudo systemctl enable preload && sudo systemctl start preload
	break
	done

	read -p "Please press enter to continue..."

	#This allows you to install any software you might know of that is not on the list
	echo "If you would like to contribute software titles to this script,
	contact me: jackharkness444@protonmail.com"
	echo "Would you like to install any additional software?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		echo "Enter the name of any software you'd like to install"
		read software
		sleep 0.5
		sudo eopkg install $software
	break
	done

	clear
	Greeting
}

Help() {
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
I can not be held accountable if something goes wrong. This software is
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
Some good reference sites are:
https://wiki.manjaro.org/index.php?title=Main_Page
https://wiki.archlinux.org
https://forum.manjaro.org
https://getsol.us/help-center/home/

########################################################################
KERNELS AND SERVICES
########################################################################
Kernels, as mentioned in the manager, are an important and integral part
of the system. For your system to work, it needs to run a certain kernel
I would suggest the LTS that is recommended or preconfigured by your OS.
Assuming that you have that kernel installed, testing out newer kernels
for specific hardware and or security functionality is not a bad idea
just use caution. Disabling services is generally a bad idea, however,
if you know you do not need it, if it is something like Bluetooth or
some app that you installed personally and the service is not required
by your system, disabling that service could potentially help speed up
your system. However, I would advise against disabling system critical
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
desktop file for it. I will write a blog article for that later.
to find my blog just go to: https://techiegeek123.blogspot.com/ in a
browser.

########################################################################
SWAP FILES
########################################################################
Swap files are an important asset to any Linux system. Swap files are
responsible for storing temporary data when there is no available memory
left on the device. Swap is also useful for storing system contents
during hibernation etc. These scripts will eventually all have the ability
to create one in the event that your system does not currently have
one. The blog article about this issue can be found here:
https://techiegeek123.blogspot.com/2019/02/swap-files-in-linux.html.
Please  email me at jackharkness444@protonmail.com for more info about
these scripts or any problems you have with Linux. I will be more than
happy to help.

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

AccountSettings() {
cat <<_EOF_
This is a completely untested and experimental utility at best.
Use this function "Account Settings" at your own risk.
_EOF_
	#This can create and remove user accounts
	echo "What would you like to do?"
	echo "1 - Create user account(s)"
	echo "2 - Delete user account(s)"
	echo "3 - Lock pesky user accounts"
	echo "4 - Look for empty password users on the system"
	echo "5 - See a list of accounts and groups on the system"
	echo "6 - Skip this menu"

	read operation;

	case $operation in
		1)
		echo $(cat /etc/group | awk -F: '{print $1}')
		sleep 2
		read -p "Please enter the groups you wish the user to be in:" $group1 $group2 $group3
		echo "Please enter the name of the user"
		read name
		echo "Please enter the password"
		read password
		sudo useradd $name -m -s /bin/bash -G $group1 $group2 $group3
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
		echo "##########################################################" >> Accounts.txt
		echo "USERS AND GROUPS" >> Accounts.txt
		echo "##########################################################" >> Accounts.txt
		cat /etc/passwd >> Accounts.txt
	;;
		6)
		echo "We can do this later"
	;;
		*)
		echo "This is an invalid selection, please run this function again and try another."
	;;
	esac

	clear
	Greeting
}

checkNetwork() {
	#This will try to ensure you have a strong network connection
	for c in computer;
	do
		ping -c4 google.com
		if [[ $? -eq 0 ]];
		then
			echo "Connection successful"
		else
			interface=$(ip -o -4 route show to default | awk '{print $5}')
			sudo dhclient -v -r && sudo dhclient; sudo systemctl stop NetworkManager.service
			sudo systemctl disable NetworkManager.service; sudo systemctl enable NetworkManager.service
			sudo systemctl start NetworkManager.service; sudo ip link set $interface up #Refer to networkconfig.log
		fi
	done
}

HostsfileSelect() {
	#I can prepare a simple hosts file
	find Hostsman4linux.sh
	while [ $? -eq 1 ];
	do
		wget https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hostsman4linux.sh; chmod +x Hostsman4linux.sh
	break
	done
	sudo ./Hostsman4linux.sh

	clear
	Greeting
}

Uninstall() {
	#This allows the user to remove unwanted shite
	echo "Would you like to remove any other unwanted junk?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		echo "Please enter the name of any software you wish to remove"
		read software
		echo "Should we remove the unnecessary dependencies?(Y/n)"
		read answer
		if [[ $answer == Y ]];
		then
			sudo eopkg autoremove $software
		else
			sudo eopkg remove $software
		fi
	break
	done

	clear
	Greeting
}

cleanup() {
	#This will clean the cache
	sudo rm -rf .cache/*
	sudo rm -rf .thumbnails/*
	sudo rm -rf ~/.local/share/Trash/*
	sudo rm -rf ~/.nv/*
	sudo rm -rf ~/.npm/*
	sudo rm -rf ~/.w3m/*
	sudo rm -rf ~/.esd_auth #Best I can tell cookie for pulse audio
	sudo rm -rf ~/.local/share/recently-used.xbel
	sudo rm -rf /tmp/*
	history -c && rm ~/.bash_history

	#This clears the cached RAM
	read -p "This will free up cached RAM. Press enter to continue..."
	sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches"

	#This could clean your Video folder and Picture folder based on a set time
	TRASHCAN=~/.local/share/Trash/
	find ~/Downloads/* -mtime +30 -exec mv {} $TRASHCAN \;
	find ~/Video/* -mtime +30 -exec mv {} $TRASHCAN \;
	find ~/Pictures/* -mtime +30 -exec mv {} $TRASHCAN \;

	#Sometimes it's good to check for and remove broken symlinks
	find -xtype l -delete

	#clean some unneccessary files leftover by applications in home directory
	find $HOME -type f -name "*~" -print -exec rm {} \;

	#cleans old kernel crash logs
	echo "Would you like to remove kernel crash logs?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		sudo find /var -type f -name "core" -print -exec rm {} \;
	break
	done

	#This helps get rid of old archived log entries
	sudo journalctl --vacuum-size=25M

	#This will remove orphan packages from eopkg
	sudo eopkg remove-orphans

	#Optional This will remove the eopkg cached applications, cleans stale blocks, etc.
	sudo eopkg delete-cache; sudo eopkg clean

	#This will also remove unwanted programs
	Uninstall
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
	browser5="$(find /usr/bin/opera)"
	browser6="$(find /usr/bin/waterfox)"
	browser7="$(find /usr/bin/basilisk)"
	browser8="$(find /usr/bin/epiphany)"
	browser9="$(find /usr/bin/midori)"

	echo $browser1
	echo $browser2
	echo $browser3
	echo $browser4
	echo $browser5
	echo $browser6
	echo $browser7
	echo $browser8
	echo $browser9

	sleep 1

	echo "choose the browser you wish to reset"
	echo "1 - Firefox"
	echo "2 - Vivaldi"
	echo "3 - Pale Moon"
	echo "4 - Chrome"
	echo "5 - Opera"
	echo "6 - Vivaldi-snapshot"
	echo "7 - Waterfox"
	echo "8 - Basilisk"
	echo "9 - Epiphany"
	echo "10 - Midori"

	read operation;

	case $operation in
		1)
		sudo cp -r ~/.mozilla/firefox ~/.mozilla/firefox-old
		sudo rm -rf ~/.mozilla/firefox/*
		echo "Your browser has now been reset"
		sleep 1
	;;
		2)
		sudo cp -r ~/.config/vivaldi/ ~/.config/vivaldi-old
		sudo rm -rf ~/.config/vivaldi/*
		echo "Your browser has now been reset"
		sleep 1
	;;
		3)
		sudo cp -r ~/'.moonchild productions'/'pale moon' ~/'.moonchild productions'/'pale moon'-old
		sudo rm -rf ~/'.moonchild productions'/'pale moon'/*
		echo "Your browser has now been reset"
		sleep 1
	;;
		4)
		sudo cp -r ~/.config/google-chrome ~/.config/google-chrome-old
		sudo rm -rf ~/.config/google-chrome/*
		echo "Your browser has now been reset"
		sleep 1
	;;
		5)
		sudo cp -r ~/.config/opera ~/.config/opera-old
		sudo rm -rf ~/.config/opera/*
		echo "Your browser has now been reset"
		sleep 1
	;;
		6)
		sudo cp -r ~/.config/vivaldi-snapshot ~/.config/vivaldi-snapshot-old
		sudo rm -rf ~/.config/vivaldi-snapshot/*
		echo "Your browser has now been reset"
		sleep 1
	;;
		7)
		sudo cp -r ~/.waterfox ~/.waterfox-old
		sudo rm -rf ~/.waterfox/*
		echo "Your browser has now been reset"
		sleep 1
	;;
		8)
		sudo cp -r ~/'.moonchild productions'/'basilisk' ~/'.moonchild productions'/'basilisk'-old
		sudo rm -rf ~/'.moonchild productions'/'basilisk'/*
		echo "Your browser has now been reset"
		sleep 1
	;;
		9)
		sudo cp -r ~/.config/epiphany ~/.config/epiphany-old
		sudo rm -rf ~/.config/epiphany/*
		echo "Your browser has now been reset"
		sleep 1
	;;
		10)
		sudo cp -r ~/.config/midori ~/.config/midori-old
		sudo rm -rf ~/.config/midori/*
		echo "Your browser has now been reset"
		sleep 1
	;;
		*)
		echo "No browser for that entry exists, please try again!"
		sleep 1
		clear
		Greeting
	esac

	#Change the default browser
	echo "Would you like to change your default browser also?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		echo "Enter the name of the browser you wish to use"
		read browser
		xdg-settings set default-web-browser $browser.desktop
	break
	done

	clear
	Greeting
}

SystemMaintenance() {
	checkNetwork

	#This attempts to fix databases and update your system
	sudo eopkg rebuild-db; sudo eopkg update-repo; sudo eopkg upgrade

	#This checks for broken packages
	sudo eopkg check | grep Broken | awk '{print $4}' | xargs sudo eopkg install --reinstall

	#This refreshes systemd in case of failed or changed units
	sudo systemctl daemon-reload

	#This will reload the firewall to ensure it's enabled
	sudo systemctl enable ufw; sudo ufw enable

	#This refreshes file index
	sudo updatedb && sudo mandb

	#update the grub
	sudo update-grub

	#This runs a disk checkup and attempts to fix filesystem
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
			echo "Would you like to run trim?(Y/n)"
			read answer
			while [ $answer == Y ];
			do
				sudo fstrim -v /
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
	#This is for service management Prolly not a great idea, but...
cat <<_EOF_
This is usually better off left undone, only disable services you know
you will not need or miss. I can not be held responsible if you brick
your system. Handle with caution. Also, may only take effect once you
reboot your machine. Services can be turned back on with a good backup
and possibly by chrooting into the device via live cd and reversing the
process by running this again and reenabling the service.
_EOF_

	systemctl list-unit-files --type=service
	read -p "Press enter to continue..."
	echo "What would you like to do?"
	echo "1 - enable service"
	echo "2 - disable service"
	echo "3 - save a copy of all the services on your system to a text file"
	echo "4 - Exit without doing anything"

read operation;

	case $operation in
		1)
		echo "Please enter the name of a service to enable"
		read service
		sudo systemctl enable $service
		echo "Would you like to reboot?(Y/n)"
		read answer
		while [ $answer == Y ];
		do
			Restart
		break
		done
	;;
		2)
		echo "Please enter the name of a service to disable"
		read service
		sudo systemctl disable $service
		echo "Would you like to reboot?(Y/n)"
		read answer
		while [ $answer == Y ];
		do
			Restart
		break
		done
	;;
		3)
		echo "##########################################################" >> services.txt
		echo "SERVICES MANAGER" >> services.txt
		echo "##########################################################" >> services.txt
		systemctl list-unit-files --type=service >> services.txt
		echo "##########################################################" >> services.txt
		echo "END OF FILE" >> services.txt
		echo "##########################################################" >> services.txt
		echo "Thank you for your patience"
		sleep 1
	;;
		4)
		echo "Smart choice."
		sleep 2
	;;
	esac

	clear
	Greeting
}

Restart() {
	sudo sync && sudo systemctl reboot
}

Backup() {
	#This backsups the system assuming you have your external drive mounted to /mnt
	echo "What would you like to do?(Y/n)"
	echo "1 - Backup home folder and user files"
	echo "2 - Backup entire drive and root partition"

	read operation;

	case $operation in
		1)
		host=$(hostname)
		Mountpoint=$(lsblk | awk '{print $7}' | grep /run/media/$USER/*)
		if [[ $Mountpoint != /run/media/$USER/* ]];
		then
			read -p "Please insert a drive and hit enter"
			echo $(lsblk | awk '{print $1}')
			sleep 1
			echo "Please select the device you wish to use"
			read device
			sudo mount $device /mnt
			sudo rsync -aAXv --delete --exclude={"*.cache/*","*.thumbnails/*","*/.local/share/Trash/*"} /home/$USER /mnt/$host-backups
		elif [[ $Mountpoint == /run/media/$USER/* ]];
		then
			read -p "Found a block device at designated coordinates...
			if this is the preferred drive, unmount it, leave it plugged in, and run this again. Press enter to continue..."
		fi
	;;
		2)
		host=$(hostname)
		Mountpoint=$(lsblk | awk '{print $7}' | grep /run/media/$USER/*)
		if [[ $Mountpoint != /run/media/$USER/* ]];
		then
			read -p "Please insert a drive and hit enter"
			echo $(lsblk | awk '{print $1}')
			sleep 1
			echo "Please select the device you wish to use"
			read device
			sudo mount $device /mnt
			sudo rsync -aAXv --delete --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} / /mnt/$host-backups
		elif [[ $Mountpoint == /run/media/$USER/* ]];
		then
			echo "Found a block device at designated coordinates...
			if this is the preferred drive, unmount it, leave it plugged in, and then run this again. Press enter to continue..."
		fi
	;;
		*)
		echo "This is an invalid entry, please try again"
	;;
	esac

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
		sudo rsync -aAXv --delete --exclude={"*.cache/*","*.thumbnails/*"."*/.local/share/Trash/*"}  /mnt/$host-$date-backups/* /home
		sudo sync
		Restart
	elif [[ $Mountpoint == /run/media/$USER/* ]];
	then
		read -p "Found a block device at designated coordinates... If this is the preferred
		drive, try unmounting the device, leaving it plugged in, and running this again. Press enter to continue..."
	fi

	clear
	Greeting
}

Greeting() {
	echo "Enter a selection from the following list"
	echo "1 - Setup your system"
	echo "2 - Add/Remove user accounts"
	echo "3 - Install software"
	echo "4 - Uninstall software"
	echo "5 - Setup a hosts file"
	echo "6 - Backup your important files and photos"
	echo "7 - Restore your important files and photos"
	echo "8 - Manage system services"
	echo "9 - Collect system information for troubleshooting"
	echo "10 - Cleanup"
	echo "11 - System Maintenance"
	echo "12 - Browser Repair"
	echo "13 - Update"
	echo "14 - Help"
	echo "15 - Restart"
	echo "16 - exit"

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
		Uninstall
	;;
		5)
		HostsfileSelect
	;;
		6)
		Backup
	;;
		7)
		Restore
	;;
		8)
		ServiceManager
	;;
		9)
		Systeminfo
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
		Help
	;;
		15)
		Restart
	;;
		16)
		echo "Thank you for using Solus-Toolbox... Goodbye!"
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

cat <<_EOF_
########################################################################
Hello! Thank you for using Solus Toolbox. Within this script is a multitu-
de of potential solutions for every day tasks as trivial as maintenance,
all the way to as important as setting up a new system.
This script is meant for new users, but anyone can read, change and use
this script to their liking. This script is to be placed under the GPLv3
and is to be redistributable, however, if you are distributing,
I would appreciate it if you gave the credit back to the original author. I
should also add that I have a few blog articles which may or may not be
of benefit for newbies on occasion. The link will be placed here. In the
blog I write about typical scenarios that I face on a day to day basis
as well as add commentary and my opinions about software and technology.
You may copy and paste the following link into your browser:
https://techiegeek123.blogspot.com/
Again, Thank you!
########################################################################
_EOF_
Greeting
