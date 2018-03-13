#!/bin/bash

#Simple System Setup
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
		sudo timedatectl set-ntp true 
		sudo timedatectl set-timezone $timezone
	break
	done

	#This starts your firewall 
	sudo systemctl enable ufw 
	sudo ufw enable 
	echo "Would you like to disable ssh and telnet for security?(Y/n)"
	read answer
	if [[ $answer == Y ]];
	then 
		sudo ufw deny telnet && sudo ufw deny ssh
		sudo ufw reload
	fi

	#This restricts coredumps to prevent attackers from getting info
	sudo cp /etc/systemd/coredump.conf /etc/systemd/coredump.conf.bak
	sudo sed -i -e '/#Storage=external/c\Storage=none ' /etc/systemd/coredump.conf
	sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
	sudo sed -i -e '/#PermitRootLogin/c\PermitRootLogin no ' /etc/ssh/sshd_config
	sudo touch /etc/sysctl.d/50-dmesg-restrict.conf
	sudo touch /etc/sysctl.d/50-kptr-restrict.conf
	sudo touch /etc/sysctl.d/99-sysctl.conf
	echo "kernel.dmesg_restrict = 1" | sudo tee -a /etc/sysctl.d/50-dmesg-restrict.conf
	echo "kernel.kptr_restrict = 1" | sudo tee -a /etc/sysctl.d/50-kptr-restrict.conf
	echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.d/99-sysctl.conf #lowers swap value
	sudo sysctl --system
	sudo systemctl daemon-reload

	#This disables ipv6
	echo "Sometimes ipv6 can cause network issues. Would you like to disable it?(Y/n)"
	read answer 
	if [[ $answer == Y ]];
	then 
		sudo cp /etc/default/grub /etc/default/grub.bak 
		sudo sed -i -e 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="ipv6.disable=1"/g' /etc/default/grub
		sudo grub-mkconfig -o /boot/grub/grub.cfg
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
				sudo systemctl enable fstrim.timer
				sudo systemctl start fstrim.service
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

	#This removes that retarded gnome-keyring unlock error you get with chrome
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

	#This allows you to add aliases to .bashrc
	echo "Aliases are shortcuts for commonly used commands."
	echo "Would you like to add some commonly used aliases?(Y/n)"
	read answer

	if [[ $answer == Y ]];
	then 
		echo "#Alias to edit fstab" >> ~/.bashrc
		echo 'alias fstab="sudo nano /etc/fstab"' >> ~/.bashrc
		echo "#Alias to edit grub" >> ~/.bashrc
		echo 'alias grub="sudo nano /etc/default/grub"' >> ~/.bashrc
		echo "#Alias to update grub" >> ~/.bashrc
		echo 'alias grubup="sudo grub-mkconfig -o /boot/grub/grub.cfg"' >> ~/.bashrc
		echo "#Alias to update the system" >> ~/.bashrc
		echo 'alias pacup="sudo pacman -Syu"' >> ~/.bashrc
		echo "#Alias to update the mirrors" >> ~/.bashrc
		echo 'alias mirrors="sudo pacman-mirrors -G && sudo pacman -Syy"' >> ~/.bashrc
	fi

	checkNetwork
	
	#This tries to update and rate mirrors if it fails it refreshes the keys
	distribution=$(cat /etc/issue | awk '{print $1}')
	for n in $distribution;
	do
		if [[ $distribution == Manjaro ]];
		then
			sudo pacman-mirrors -G
			sudo pacman-optimize && sync
			sudo pacman -Syyu --noconfirm 
			if [[ $? -eq 0 ]]; 
			then 
				echo "Update succeeded" 
			else
				sudo rm /var/lib/pacman/db.lck 
				sudo rm -r /etc/pacman.d/gnupg 
				sudo pacman -Sy gnupg archlinux-keyring manjaro-keyring
				sudo pacman-key --init 
				sudo pacman-key --populate archlinux manjaro 
				sudo pacman-key --refresh-keys 
				sudo pacman -Sc
				sudo pacman -Syyu
			fi
		elif [[ $distribution == Antergos ]];
		then
			sudo pacman rankmirrors /etc/pacman.d/antergos-mirrorlist
			sudo pacman -Syyu --noconfirm
			if [[ $? -eq 0 ]]; 
			then 
				echo "update successful"
			else 
				sudo rm /var/lib/pacman/db.lck 
				sudo rm -r /etc/pacman.d/gnupg 
				sudo pacman -Sy --noconfirm gnupg archlinux-keyring antergos-keyring
				sudo pacman-key --init
				sudo pacman-key --populate archlinux antergos 
				sudo pacman -Sc --noconfirm 
				sudo pacman -Syyu --noconfirm
			fi
		fi
	done
	
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
	
	sudo pacman -Syyu --noconfirm 
	
	clear
	Greeting
	
}

Systeminfo() {
	#This gives some useful information for later troubleshooting 
	host=$(hostname)
	distribution=$(cat /etc/issue | awk '{print $1}')
	echo "##############################################################" >> $host-sysinfo.txt
	echo "SYSTEM INFORMATION" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
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
	echo "PROCESS LIST" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	ps -aux >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	echo "INSTALLED PACKAGES" >> $host-sysinfo.txt
	echo "##############################################################" >> $host-sysinfo.txt
	sudo pacman -Q >> $host-sysinfo.txt
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
		echo "Here is a list of software to choose from"
		sleep 2
		echo "1 - bleachbit"
		echo "2 - gnome-disk-utility"
		echo "3 - ncdu"
		echo "4 - nmap"
		echo "5 - preload"
		echo "6 - hardinfo"
		echo "7 - lshw"
		echo "8 - hdparm"
		echo "9 - hddtemp xsensors"
		echo "10 - Code/text editor/IDE"
		echo "11 - htop iotop inxi"
		echo "12 - wget"
		echo "13 - rkhunter"
		echo "14 - abiword gnumeric"
		echo "15 - bittorrent"
		echo "16 - net-tools"
		echo "17 - virtualbox"
		echo "18 - redshift"
		echo "19 - blender"
		echo "20 - cower"
		echo "21 - xed"
		echo "22 - wine"
		echo "23 - web browser"
		echo "24 - media player"
		echo "25 - antivirus"
		echo "26 - backup software"
		echo "27 - video and audio editing"
		echo "28 - shotwell"
		echo "29 - guvcview"
		echo "30 - etc-update"
		echo "31 - Games"
		echo "32 - A dock program"
		echo "33 - Audio/Video Decoding software"
		echo "34 - Screenfetching utility"
		echo "35 - Hunspell language packs"
		echo "36 - Themes"
		echo "37 - to skip"
		
	read software;

	case $software in 

			1)
			echo "This installs cleaning software"
			sudo pacman -S --noconfirm bleachbit
	;;
			2)
			echo "This installs disk health checking software"
			sudo pacman -S --noconfirm gnome-disk-utility
	;;
			3)
			echo "This installs disk space checking software"
			sudo pacman -S --noconfirm ncdu
	;;
			4)
			echo "This installs network scanning software"
			sudo pacman -S --noconfirm nmap
	;;
			5)
			echo "This installs daemon that loads applications in memory"
			sudo pacman  -S --noconfirm preload
	;;
			6)
			echo "This installs hardware informations tool"
			sudo pacman -S --noconfirm hardinfo
	;;
			7)
			echo "This installs command line utility to gather certain system info"
			sudo pacman -S --noconfirm lshw
	;;
			8)
			echo "This installs software to configure hard drive settings"
			sudo pacman -S --noconfirm hdparm
	;;
			9)
			echo "This installs software to gather temps"
			sudo pacman -S --noconfirm xsensors hddtemp
	;;
			10)
			echo "This installs a light weight editor(text/code editor/IDE)"
			echo "1 - geany"
			echo "2 - sublime text editor"
			echo "3 - bluefish"
			echo "4 - atom"
			echo "5 - gedit"
			read package
			if [[ $package == 1 ]];
			then
				sudo pacman -S --noconfirm geany
			elif [[ $package == 2 ]];
			then
				wget https://aur.archlinux.org/cgit/aur.git/snapshot/sublime-text2.tar.gz
				gunzip sublime-text2.tar.gz && tar -xvf sublime-text2.tar
				cd /sublime-text2
				makepkg -si
			elif [[ $package == 3 ]];
			then
				sudo pacman -S --noconfirm bluefish
			elif [[ $package == 4 ]];
			then
				sudo pacman -S --noconfirm atom
			elif [[ $package == 5 ]];
			then
				sudo pacman -S --noconfirm gedit
			fi
	;;
			11)
			echo "This installs command line system monitors"
			sudo pacman -S --noconfirm htop iotop inxi
	;;
			12)
			echo "This installs a download manager"
			sudo pacman -S --noconfirm wget
	;;
			13)
			echo "This installs a rootkit checker"
			sudo pacman -S --noconfirm rkhunter
	;;
			14)
			echo "This installs light weight office tools"
			sudo pacman -S --noconfirm abiword gnumeric
	;;
			15)
			echo "This installs your choice of bittorrent client"
			echo "1 - qbittorrent"
			echo "2 - transmission-gtk"
			echo "3 - deluge"
			read client
			if [[ $client == 1 ]];
			then
				sudo pacman -S --noconfirm qbittorrent
			elif [[ $client == 2 ]];
			then
				sudo pacman -S --noconfirm transmission-gtk
			elif [[ $client == 3 ]];
			then
				sudo pacman -S --noconfirm deluge
			else
				echo "moving on"
			fi
	;;
			16)
			echo "This installs the old network tools for linux"
			sudo pacman -S --noconfirm net-tools
	;;
			17)
			echo "This installs a virtual box utility"
			sudo pacman -S --noconfirm virtualbox
	;;
			18)
			echo "This installs a program to dim the monitor at night"
			sudo pacman -S --noconfirm redshift
	;;
			19)
			echo "This installs 3D editing software"
			sudo pacman -S --noconfirm blender
	;;
			20)
			echo "This installs a command line utility for managing AUR software"
			sudo pacman -S --noconfirm cower
	;;
			21)
			echo "This installs a Linux Mint text editor"
			sudo pacman -S --noconfirm xed 
	;;
			22)
			echo "This installs windows emulation software"
			sudo pacman -S --noconfirm wine
	;;
			23)
			echo "This installs your choice in browsers"
			echo "1 - chromium"
			echo "2 - epiphany"
			echo "3 - qupzilla"
			echo "4 - opera" 
			echo "5 - Pale Moon"
			echo "6 - seamonkey"
			echo "7 - dillo"
			echo "8 - lynx"
			echo "9 - vivaldi"
			echo "10 - google-chrome"
			read browser
			if [[ $browser == 1 ]];
			then
				sudo pacman -S --noconfirm chromium
			elif [[ $browser == 2 ]];
			then
				sudo pacman -S --noconfirm epiphany
			elif [[ $browser == 3 ]];
			then
				sudo pacman -S --noconfirm qupzilla
			elif [[ $browser == 4 ]];
			then
				sudo pacman -S --noconfirm opera
			elif [[ $browser == 5 ]];
			then
				sudo pacman -S --noconfirm palemoon-bin
			elif [[ $browser == 6 ]];
			then
				sudo pacman -S --noconfirm seamonkey
			elif [[ $browser == 7 ]];
			then
				sudo pacman -S --noconfirm dillo
			elif [[ $browser == 8 ]];
			then
				sudo pacman -S --noconfirm lynx
			elif [[ $browser == 9 ]];
			then
				cd /tmp
				wget https://aur.archlinux.org/cgit/aur.git/snapshot/vivaldi-snapshot.tar.gz
				gunzip vivaldi-snapshot.tar.gz
				tar -xvf vivaldi-snapshot.tar
				cd vivaldi-snapshot
				makepkg -si
			elif [[ $browser == 10 ]];
			then
				cd /tmp
				wget https://aur.archlinux.org/cgit/aur.git/snapshot/google-chrome.tar.gz
				gunzip google-chrome.tar.gz
				tar -xvf google-chrome.tar
				cd google-chrome
				makepkg -si
			fi
	;;
			24)
			echo "This installs a choice in media players"
			echo "1 - xplayer"
			echo "2 - parole"
			echo "3 - kodi"
			echo "4 - Music"
			echo "5 - rhythmbox"
			echo "6 - mpv"
			echo "7 - VLC"
			echo "8 - totem"
			echo "9 - pragha"
			read player
			if [[ $player == 1 ]];
			then
				sudo pacman -S --noconfirm xplayer
			elif [[ $player == 2 ]];
			then
				sudo pacman -S --noconfirm parole
			elif [[ $player == 3 ]];
			then
				sudo pacman -S --noconfirm kodi
			elif [[ $player == 4 ]];
			then
				sudo pacman -S --noconfirm Music
			elif [[ $player == 5 ]];
			then
				sudo pacman -S --noconfirm rhythmbox
			elif [[ $player == 6 ]];
			then
				sudo pacman -S --noconfirm mpv 
			elif [[ $player == 7 ]];
			then
				distribution=$(cat /etc/issue | awk '{print $1}')
				if [[ $distribution == manjaro ]];
				then
					sudo pacman -Rs --noconfirm vlc-nightly && sudo pacman -S vlc clementine
				else
					sudo pacman -S --noconfirm vlc
				fi
			elif [[ $player == 8 ]];
			then
				sudo pacman -s --noconfirm totem
			elif [[ $player == 9 ]];
			then
				sudo pacman -S --noconfirm pragha 
				echo "comes standard with antergos"
			fi
	;;
			25)
			echo "This installs an antivirus if you think you need it"
			sudo pacman -S clamav clamtk 
	;;
			26)
			echo "This installs your backup software"
			echo "1 - deja-dup"
			echo "2 - grsync"
			read package
			if [[ $package == 1 ]];
			then
				sudo pacman -S --noconfirm deja-dup
			elif [[ $package == 2 ]];
			then
				sudo pacman -S --noconfirm grsync
			fi
	;;
			27)
			echo "This installs audio editing software and video editing software"
			sudo pacman -S --noconfirm kdenlive audacity
	;;
			28)
			echo "This installs image organizing software"
			sudo pacman -S --noconfirm shotwell
	;;
			29) 
			sudo pacman -S --noconfirm guvcview
	;;
			30)
			echo "This installs etc-update"
			echo "etc-update can help you manage pacnew files and other configuration files after system updates."
			sleep 2
			cd /tmp
			sudo pacman -S --needed base-devel 
			wget https://aur.archlinux.org/cgit/aur.git/snapshot/etc-update.tar.gz
			gunzip etc-update.tar.gz && tar -xvf etc-update.tar
			cd etc-update
			makepkg -si
	;;
			31)
			echo "This installs games"
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
				sudo pacman -S --noconfirm supertuxkart
			elif [[ $package == 2 ]];
			then
				sudo pacman -S --noconfirm gnome-mahjongg
			elif [[ $package == 3 ]];
			then
				sudo pacman -S --noconfirm aisleriot
			elif [[ $package == 4 ]];
			then
				sudo pacman -S --noconfirm ace-of-penguins
			elif [[ $package == 5 ]];
			then
				sudo pacman -S --noconfirm gnome-sudoku
			elif [[ $package == 6 ]];
			then
				sudo pacman -S --noconfirm gnome-mines
			elif [[ $package == 7 ]];
			then
				sudo pacman -S --noconfirm chromium-bsu
			elif [[ $package == 8 ]];
			then
				sudo pacman -S --noconfirm supertux
			elif [[ $package == 9 ]];
			then
				sudo pacman -S --noconfirm supertuxkart gnome-mahjongg aisleriot ace-of-penguins gnome-sudoku gnome-mines chromium-bsu supertux
			else
				echo "You entered an invalid number, please try again later."
			fi
	;;
			32)
			echo "This installs plank, a popular dock application"
			sudo pacman -S --noconfirm plank
	;;
			33)
			echo "This installs handbrake"
			sudo pacman -S --noconfirm handbrake
	;;
			34)
			echo "This installs screenfetch"
			sudo pacman -S --noconfirm  screenfetch
			sudo cp /etc/bash.bashrc /etc/bash.bashrc.bak
			echo "screenfetch" | sudo tee -a /etc/bash.bashrc
	;;
			35)
			echo "This installs extra language packs"
			sudo pacman -S --noconfirm firefox-i18n-en-us thunderbird-i18n-en-us aspell-en gimp-help-en hunspell-en_US hunspell-en hyphen-en
	;;
			36)
			echo "This installs themes"
			sudo pacman -S --noconfirm adapta-gtk-theme moka-icon-theme faba-icon-theme arc-icon-theme  evopop-icon-theme elementary-xfce-icons xfce-theme-greybird numix-themes-archblue arc-gtk-theme menda-themes-dark papirus-icon-theme gtk-theme-breath
	;; 
			37)
			echo "We will skip this"
			break
	;;
	esac
	done
	
	read -p "Press enter to continue..."

	#This allows you to install any software you might know of that is not on the list
	echo "If you would like to contribute software titles to this script, 
	contact me: jackharkness444@protonmail.com"
	echo "Would you like to install any additional software?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		echo "Enter the name of any software you'd like to install"
		read software
		sleep 1
		sudo pacman -S --noconfirm $software
	break
	done
	
	read -p "Press enter to continue..."

	#This installs xfce4-goodies package on xfce versions of Manjaro
	for env in $DESKTOP_SESSION
	do
		if [ $DESKTOP_SESSION == xfce ];
		then
			echo "We found you're running the xfce desktop, would you like
			to install extra extensions for xfce?(Y/n)"
			read answer
			while [ $answer == Y ];
			do
				sudo pacman -S --noconfirm xfce4-goodies
			break
			done
		fi
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
			sudo dhclient -v -r && sudo dhclient
			sudo systemctl stop NetworkManager.service
			sudo systemctl disable NetworkManager.service
			sudo systemctl enable NetworkManager.service
			sudo systemctl start NetworkManager.service
			sudo ip link set $interface up #Refer to networkconfig.log
		fi
	done
}

HostsfileSelect() {
	#I can prepare a simple hosts file
	find Hostsman4linux.sh
	while [ $? -eq 1 ];
	do
		wget https://raw.githubusercontent.com/thedummy06/Helpful-Linux-Shell-Scripts/master/Hostsman4linux.sh
		chmod +x Hostsman4linux.sh
	break
	done
	sudo ./Hostsman4linux.sh

	clear
	Greeting
}

cleanup() {
	#This will clean the cache
	sudo rm -r .cache/*
	sudo rm -r .thumbnails/*
	sudo rm -r ~/.local/share/Trash
	sudo rm -r ~/.nv/*
	sudo rm -r ~/.local/share/recently-used.xbel
	sudo rm -r /tmp/* 
	find ~/Downloads/* -mtime +3 -exec rm {} \; #Deletes contents older than three day
	history -cw && cat /dev/null/ > ~/.bash_history

	#This could clean your Video folder and Picture folder based on a set time
	TRASHCAN=~/.local/share/Trash/
	find ~/Video/* -mtime +30 -exec mv {} $TRASHCAN \; #throws away month old content
	find ~/Pictures/* -mtime +30 -exec mv {} $TRASHCAN \; #The times can be changed

	#Sometimes it's good to check for and remove broken symlinks
	find -xtype l -delete

	#clean some unneccessary files leftover by applications in home directory
	find $HOME -type f -name "*~" -print -exec rm {} \;
	 
	#This helps get rid of old archived log entries
	sudo journalctl --vacuum-size=25M

	#This will remove orphan packages from pacman 
	sudo pacman -Rsn --noconfirm $(pacman -Qqdt)

	#This allows the user to remove unwanted shite
	echo "Would you like to remove any other unwanted shite?(Y/n)"
	read answer 
	while [ $answer == Y ];
	do
		echo "Please enter the name of any software you wish to remove"
		read software
		sudo pacman -Rs --noconfirm $software
		break
	done

	#Optional This will remove the pamac cached applications and older versions
	cat <<_EOF_
	It's probably not a great idea to be cleaning this part of the system
	all willy nilly, but here is a way to free up some space before doing
	backups that may cause you to not be able to downgrade, so be careful. 
	It is possible and encouraged to clean all but the latest three 
	versions of software on your system that you may not need, but this 
	removes all backup versions. You will be given a choice, but it is 
	strongly recommended that you use the simpler option to remove only 
	up to the latest three versions of your software. Thanks!
_EOF_

	echo "What would you like to do?"
	echo "1 - Remove up to the latest three versions of software"
	echo "2 - Remove all cache except for the version on your system"
	echo "3 - Remove all cache from every package and every version"
	echo "4 - Skip this step"

	read operation;

	case $operation in 
		1)
		sudo paccache -rvk3
		sleep 3
		;;
		2)
		sudo pacman -Sc --noconfirm 
		sleep 3
		;;
		3)
		sudo pacman -Scc --noconfirm
		sleep 3
		;;
		4)
		echo "NICE!"
		;;
	esac

	clear
	Greeting
}

SystemMaintenance() {
	checkNetwork
	
	#This attempts to rank mirrors and update your system
	distribution=$(cat /etc/issue | awk '{print $1}')
	if [[ $distribution == Manjaro ]];
	then
		sudo pacman-mirrors -G && sudo pacman -Syy
	else
		sudo reflector -l 50 -f 20 --save /tmp/mirrorlist.new && rankmirrors -n 0 /tmp/mirrorlist.new > /tmp/mirrorlist && sudo cp /tmp/mirrorlist /etc/pacman.d
		sudo rankmirrors -n 0 /etc/pacman.d/antergos-mirrorlist > /tmp/antergos-mirrorlist && sudo cp /tmp/antergos-mirrorlist /etc/pacman.d
		sudo pacman -Syyu --noconfirm
	fi

	#This refreshes systemd in case of failed or changed units
	sudo systemctl daemon-reload
	
	#This will reload the firewall to ensure it's enabled
	sudo ufw reload

	#This refreshes index cache
	sudo updatedb && sudo mandb 
	
	#Checks for pacnew files and other extra configuration file updates
	sudo etc-update

	#update the grub 
	sudo grub-mkconfig -o /boot/grub/grub.cfg

	#This runs a disk checkup and attempts to fix filesystem
	sudo touch /forcefsck 

	#Optional and prolly not needed
	echo "Only to be used on standard Mechanical hard drives, do not use on SSD,
	if you don't know, don't hit Y"
	echo "Would you like to check your hard drive fragmentation levels?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		sudo e4defrag / -c > fragmentation.log #only to be used on HDD
		break
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
reboot your machine.
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
		systemctl list-unit-files --type=service >> services.txt
		echo "Thank you for your patience"
		sleep 3
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

KernelManager() {
	#This gives a list of available kernels and offers to both install and uninstall them
	sudo mhwd-kernel -l 
	sudo mhwd-kernel -li
	read -p "Press enter to continue..."
	echo "What would you like to do today?"
	echo "1 - Install new kernel(s)"
	echo "2 - Uninstall kernel(s)"
	echo "3 - save a list of available and installed kernels to a text file"
	echo "4 - skip"

	read operation;

	case $operation in
		1)
		echo "Are you sure you want to install a kernel?(Y/n)"
		read answer
		while [ $answer == Y ];
		do
			echo "Enter the name of the kernel you wish to install"
			read kernel
			sudo mhwd-kernel -i $kernel
			Restart
		break
		done
	;;
		2)
		echo "Are you sure you want to remove a kernel?(Y/n)"
		read answer
		while [ $answer == Y ];
		do
			echo "Enter the name of the kernel you wish to remove"
			read kernel
			sudo mhwd-kernel -r $kernel
			Restart
		break
		done
	;;
		3)
		sudo mhwd-kernel -l >> kernels.txt
		echo "######################################################" >> kernels.txt
		sudo mhwd-kernel -li >> kernels.txt
	;;
		4)
		echo "Skipping"
	;;
	esac
	

	clear
	Greeting
}

Backup() {
	#This backsups the system assuming you have your external drive mounted to /mnt
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
		sudo rsync -aAXv --delete --exclude={"/home/*/.cache/*","/home/*/.thumbnails/*"."/home/*/.local/share/Trash/*"} /home/$USER /mnt/$host-backups
	elif [[ $Mountpoint == /run/media/$USER/* ]];
	then
		echo "Found a block device at designated coordinates...
		If this is the preferred drive, unmount it, leave it plugged in, and run this again."
		sleep 3
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
directory is on the drive in question. 
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
		sudo rsync -aAXv --delete --exclude={"/home/*/.cache/*","/home/*/.thumbnails/*"."/home/*/.local/share/Trash/*"}  /mnt/$host-backups/* /home
		sudo sync 
		Restart
	elif [[ $Mountpoint == /run/media/$USER/* ]];
	then
		echo "Found a block device at designated coordinates... If this is the preferred
		drive, try unmounting the device, leaving it plugged in, and running this again."
	fi 
}

Greeting() {
	echo "Enter a selection from the following list"
	echo "1 - Setup your system"
	echo "2 - Install software"
	echo "3 - Setup a hosts file"
	echo "4 - Backup your important files and photos"
	echo "5 - Restore your important files and photos"
	echo "6 - Manage system services"
	echo "7 - Install or uninstall kernels"
	echo "8 - Collect system information"
	echo "9 - Cleanup"
	echo "10 - System Maintenance"
	echo "11 - Update"
	echo "12 - Help"
	echo "13 - exit"
	
	read selection;
	
	case $selection in
		1)
		Setup
	;;
		2)
		InstallAndConquer
	;;
		3)
		HostsfileSelect
	;;
		4)
		Backup
	;;
		5)
		Restore
	;;
		6)
		ServiceManager
	;;
		7)
		KernelManager
	;;
		8)
		Systeminfo
	;;
		9)
		cleanup
	;;
		10)
		SystemMaintenance
	;;
		11)
		Update
	;;
		12)
		Help
	;;
		13)
		echo "Thank you for using Arch-Toolbox... Goodbye!"
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
