#!/bin/bash

Setup(){
	#Sets default editor to nano in bashrc
	echo "export EDITOR=nano" | sudo tee -a /etc/bash.bashrc

	#Backs up important system files
	sudo cp /etc/systemd/coredump.conf /etc/systemd/coredump.conf.bak
	sudo cp /etc/systemd/system.conf /etc/systemd/system.conf.bak
	sudo cp /etc/systemd/logind.conf /etc/systemd/logind.conf.bak
	sudo cp /etc/sudoers /etc/sudoers.bak
	sudo cp /etc/login.defs /etc/login.defs.bak
	sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
	sudo cp /etc/systemd/journald.conf /etc/systemd/journald.conf.bak
	sudo cp /etc/shadow /etc/shadow.bak
	sudo cp /etc/passwd /etc/passwd.bak
	sudo cp /etc/bash.bashrc /etc/bash.bashrc.bak
	sudo cp /etc/environment /etc/environment.bak
	sudo cp /etc/profile /etc/profile.bak
	sudo cp /etc/default/grub /etc/default/grub.bak
	sudo cp /etc/fstab /etc/fstab.bak
	sudo cp -r /boot /boot-old
	cp .bashrc .bashrc.bak
	cp .xsession-errors .xsession-errors.bak

	#Fix screen RESOLUTION
	echo "Would you like to choose a more accurate screen resolution?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		ScreenFix
		break
	done

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

	#This restricts coredumps to prevent attackers from getting info
	sudo sed -i -e '/#Storage=external/c\Storage=none ' /etc/systemd/coredump.conf
	sudo sed -i -e '/#PermitRootLogin/c\PermitRootLogin no ' /etc/ssh/sshd_config
	sudo touch /etc/sysctl.d/50-dmesg-restrict.conf
	sudo touch /etc/sysctl.d/50-kptr-restrict.conf
	sudo touch /etc/sysctl.d/99-sysctl.conf
	sudo touch /etc/sysctl.d/60-network-hardening.conf
	echo "kernel.dmesg_restrict = 1" | sudo tee -a /etc/sysctl.d/50-dmesg-restrict.conf
	echo "kernel.kptr_restrict = 1" | sudo tee -a /etc/sysctl.d/50-kptr-restrict.conf
	echo "vm.swappiness = 10" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
	echo "net.ipv4.icmp_echo_ignore_all = 1" | sudo tee -a /etc/sysctl.d/60-network-hardening.conf
	sudo sed -i -e '/GRUB_TIMEOUT=5/c\GRUB_TIMEOUT=3 ' /etc/default/grub; sudo clr-boot-manager update
	sudo sed -i -e '/#SystemMaxUse=/c\SystemMaxUse=50M ' /etc/systemd/journald.conf
	sudo sysctl --system; sudo sysctl -p

	#This disables ipv6
	echo "Sometimes ipv6 can cause network issues. Would you like to disable it?(Y/n)"
	read answer
	if [[ $answer == Y ]];
	then
		sudo sed -i -e 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="ipv6.disable=1"/g' /etc/default/grub; sudo update-grub
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

	#This removes that stupid gnome-keyring unlock error you get with chrome
	echo "Killing this might make your passwords less secure on chrome. Do you wish to kill gnome-keyring? (Y/n)"
	read answer
	if [[ $answer == Y ]];
	then
		sudo mv /usr/bin/gnome-keyring-daemon /usr/bin/gnome-keyring-daemon-old; sudo killall gnome-keyring-daemon
	else
		echo "Proceeding"
	fi

	#This allows you to add aliases to .bashrc
	echo "Would you like to add some commonly used aliases?(Y/n)"
	read answer
	if [[ $answer == Y ]];
	then
		echo "### Aliases ###" >> ~/.bashrc
		echo "# Package Manager" >> ~/.bashrc
		echo 'alias update="sudo eopkg -y upgrade"' >> ~/.bashrc
		echo 'alias flatup="flatpak --user update"' >> ~/.bashrc
		echo 'alias fix="sudo flatpak repair && flatpak --user uninstall --unused"' >> ~/.bashrc
		echo 'alias cleanse="sudo eopkg -y delete-cache"' >> ~/.bashrc
		echo 'alias purge="sudo eopkg -y clean"' >> ~/.bashrc
		echo 'alias rmo="sudo eopkg remove-orphans"' >> ~/.bashrc
		echo 'alias repair="sudo eopkg check | grep Broken | awk '{print $4}' | xargs sudo eopkg -y install --reinstall"' >> ~/.bashrc
		echo 'alias rebuild="sudo eopkg -y rebuild-db"' >> ~/.bashrc
		echo "" >> ~/.bashrc
		echo "# Firmware Upgrades" >> ~/.bashrc
		echo 'alias fwup="sudo /usr/bin/fwupdmgr refresh && sudo /usr/bin/fwupdmgr update"' >> ~/.bashrc
		echo "" >> ~/.bashrc
		echo "# System Cleaning" >> ~/.bashrc
		echo 'alias vaccum="sudo journalctl --vacuum-size=25M"' >> ~/.bashrc
		echo 'alias dust="sudo rm -r ~/.cache/*; sudo rm -r ~/.thumbnails/*"' >> ~/.bashrc
		echo 'alias sweep="sudo rm -r ~/.config/*-old"' >> ~/.bashrc
		echo 'alias mop="sudo rm -r /var/tmp/*"' >> ~/.bashrc
		echo 'alias garbage="sudo rm -r ~/.local/share/Trash/files/*"' >> ~/.bashrc
		echo "" ~/.bashrc
		echo "# System Maintenance" >> ~/.bashrc
		echo 'alias trim="sudo fstrim -v --all"' >> ~/.bashrc
		echo 'alias reload="sudo systemctl daemon-reload"' >> ~/.bashrc
		echo 'alias repair="sudo touch /forcefsck"' >> ~/.bashrc
		echo 'alias grubup="sudo clr-boot-manager update"' >> ~/.bashrc
		echo 'alias firewalld="sudo systemctl enable ufw; sudo ufw enable"' >> ~/.bashrc
		echo 'alias refresh="sudo gtk-update-icon-cache"' >> ~/.bashrc
		echo "" ~/.bashrc
		echo "# Networking" >> ~/.bashrc
		echo 'alias ipconfig="ip addr show"'
		echo 'alias tracert="traceroute google.com"'
		echo 'alias ping="ping -c4 google.com && ping -c4 facebook.com"'
		echo 'alias netstat="ss -tulpn"'
		echo 'alias query="nslookup www.google.com && host www.google.com"'
		echo 'alias netinfo="hostname -I"'
		echo 'alias arpinfo="arp -e"'
		echo 'alias dns="dig google.com"'
		echo 'alias wifi="iwconfig"'
		echo "" >> ~/.bashrc
		echo "# System Stats" >> ~/.bashrc
		echo 'alias temp="watch sensors"' >> ~/.bashrc
		echo 'alias mem="watch free -lh"' >> ~/.bashrc
		echo 'alias cpu="lscpu"' >> ~/.bashrc
		echo 'alias meminfo="cat /proc/meminfo"' >> ~/.bashrc
		echo 'alias swaps="cat /proc/swaps"' >> ~/.bashrc
		echo 'alias diskinfo="sudo smartctl -A /dev/sda"' >> ~/.bashrc
		echo 'alias ut="uptime -p"' >> ~/.bashrc
		echo "" ~/.bashrc
		echo "# Confirmations" >> ~/.bashrc
		echo 'alias mv="mv -i"' >> ~/.bashrc
		echo 'alias cp="cp -i"' >> ~/.bashrc
		echo 'alias rm="rm -i"' >> ~/.bashrc
		echo 'alias ln="ln =i"' >> ~/.bashrc
		echo "" >> ~/.bashrc
		echo "# System Permissions" >> ~/.bashrc
		echo 'alias ll="ls -l"' >> ~/.bashrc
		echo "" >> ~/.bashrc
		echo "# Clear Cached RAM" >> ~/.bashrc
		echo 'alias boost="sudo sysctl -w vm.drop_caches=3"' >> ~/.bashrc
		#echo "" >> ~/.bashrc
		#echo "# Adblocking" >> ~/.bashrc
		#echo 'alias hostsup="sudo ./Hostsman4linux.sh -B"' >> ~/.bashrc
		echo "neofetch" >> ~/.bashrc
		source .bashrc
	fi

	checkNetwork

	#This tries to update repositories and upgrade the system
	sudo eopkg -y delete-cache; sudo eopkg -y clean; sudo eopkg -y rebuild-db; sudo eopkg -y upgrade
	
	#This installs firmware updates
	Firmware_Upgrades
	
	#This optionally sets up flatpak support
	#sudo eopkg install flatpak xdg-desktop-portal-gtk; sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

	#This allows you to install the latest LTS kernel in Solus
	echo "Would you like to install the latest LTS kernel stack?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		sudo eopkg install linux-lts linux-lts-headers
		echo "This keeps your current kernel in tact"
	break
	done

	#This starts your firewall
	eopkg list-installed | grep gufw || sudo eopkg -y install gufw; sudo systemctl enable ufw; sudo ufw default deny incoming; sudo ufw default allow outgoing; sudo ufw enable
	echo "Would you also like to deny ssh and telnet for security?(Y/n)"
	read answer
	while [ $answer == Y ]
	do
		sudo ufw deny ssh; sudo ufw deny telnet; sudo ufw reload
	break
	done

	#This fixes  an issue with GUFW on KDE
	if [[ $DESKTOP_SESSION == /usr/share/xsessions/plasma ]];
	then
		echo "kdesu python3 /usr/lib/python3.7/site-packages/gufw/gufw.py" | sudo tee -a /bin/gufw
	fi

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

Update(){
	checkNetwork

	sudo eopkg -y upgrade

	clear
	Greeting
}

Downgrade(){
	checkNetwork

	echo "Please enter the number to which you wish to downgrade or revert"
	read number
	sudo eopkg history -t $number

	clear
	Greeting
}

Reset(){
	#This resets the desktop
	eopkg list-installed | grep dconf || sudo eopkg install dconf
	if [[ $DESKTOP_SESSION == budgie ]];
	then
		echo "############################################################################"
		echo "This resets Budgie"
		echo "############################################################################"
		dconf dump /org/budgie/ > budgie-desktop-backup; dconf reset -f /
	elif [[ $DESKTOP_SESSION == gnome ]];
	then
		echo "############################################################################"
		echo "This resets Gnome Shell"
		echo "############################################################################"
		dconf dump /org/gnome/ > gnome-desktop-backup; dconf reset -f /
	elif [[ $DESKTOP_SESSION == mate ]];
	then
		echo "############################################################################"
		echo "This resets MATE"
		echo "############################################################################"
		dconf dump /org/mate/ > mate-desktop-backup; dconf reset -f /
	else
		echo "You're running a desktop/Window Manager that we do not yet support... Come back later."
	fi
}

Systeminfo(){
	host=$(hostname)
	drive=$(df -P / | awk '{print $1}' | grep "/dev/")
	DisplayManager=$(ps auxf | awk '{print $11}' | \grep --color -e dm$ -e slim$)
	distribution=$(cat /etc/solus-release)
	echo "############################################################################" >> $host-sysinfo.txt
	echo "SYSTEM INFORMATION" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "DATE"  >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	date >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "USER" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo $USER >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "SHELL" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	which $SHELL >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "DISTRIBUTION" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo $distribution >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "DESKTOP" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo $XDG_CURRENT_DESKTOP >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "SCREEN SERVER" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo $XDG_SESSION_TYPE >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "DISPLAY MANAGER" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo $DisplayManager >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "SYSTEM INITIALIZATION" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	ps -p1 | awk 'NR!=1{print $4}' >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "SCREEN RESOLUTION" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	xrandr >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "SYSTEM INSTALL DATE" >>$host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	sudo tune2fs -l $drive | grep 'Filesystem created:' >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "KERNEL AND OPERATING SYSTEM INFORMATION" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	uname -r >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "OS/MACHINE INFO" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	hostnamectl >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "OPERATING SYSTEM RELEASE INFORMATION" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	lsb_release -a >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "HOSTNAME" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	hostname >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "SUDO VERSION CHECK" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	sudo -V >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "UPTIME" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	uptime -p >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "LOAD AVERAGE" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	cat /proc/loadavg >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "DISK SECTOR INFORMATION" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	sudo fdisk -l >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "DISK SPACE" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	df -h >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "I/O SCHEDULER INFO" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	cat /sys/block/sda/queue/scheduler >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "SMART DATA" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	sudo smartctl -a /dev/sda >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "DIRECTORY USAGE" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	sudo du -sh >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "MEMORY USAGE" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	free -h >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "LISTS ALL BLOCK DEVICES WITH SIZE" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	lsblk -o NAME,SIZE >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "BLOCK DEVICE ID " >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	sudo blkid >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "NETWORK CONFIGURATION" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	ip addr >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "PUBLIC IP INFORMATION" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	curl ifconfig.me/all >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "NETWORK STATS" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	ss -tulpn >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "WIFI INFO" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	iwconfig >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "DNS INFO" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	dig | grep SERVER >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "FIREWALL STATUS" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	sudo ufw status verbose >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "PROCESS TABLE" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	ps -aux >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "LAST LOGIN ATTEMPTS" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	lastlog >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "PERMISSIONS" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	ls -larS / >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "AUDIT SUID & SGID" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	sudo -s find / -type f \( -perm -4000 -o -perm -2000 \) -exec ls -l {} \; >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "USER AND GROUPS" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	cat /etc/passwd | awk '{print $1}' >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "INSTALLED PACKAGES" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	eopkg list-installed >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "INSTALLED FLATPAKS" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	flatpak list >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "PACKAGE MANAGER HISTORY" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	sudo eopkg history >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "APPARMOR" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	sudo apparmor_status >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "Inxi" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	inxi -F >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "CPU TEMP" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	sensors >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "HD TEMP" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	sudo hddtemp /dev/sda >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo " DRIVER INFO" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	sudo lsmod >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "USB INFORMATION" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	lsusb >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "HARDWARE INFORMATION" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	lspci >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "MORE HARDWARE INFORMATION" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	sudo lshw >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "EVEN MORE HARDWARE INFORMATION" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	sudo dmidecode >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "YET STILL MORE HARDWARE INFORMATION" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	lscpu >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "MEMORY INFOMRATION" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	cat /proc/meminfo >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "TLP STATS" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	sudo tlp-stat >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "LOGS" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	sudo dmesg >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "JOURNAL LOG ERRORS" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	journalctl -p 3 -xb >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "SYSTEMD SERVICES(ALSO FOUND IN SERVICE MANAGER)" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	systemctl list-unit-files --type=service >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "SYSTEMD BOOT INFORMATION" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	systemd-analyze >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "MORE SYSTEMD BOOT INFORMATION" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	systemd-analyze blame >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "SYSTEMD STATUS" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	systemctl status | less >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "SYSTEMD'S FAILED LIST" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	systemctl --failed >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "END OF FILE" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt

	clear
	Greeting
}

ScreenFix(){
	xrandr
	echo "Choose a resolution from the list above"
	read resolution
	xrandr -s $resolution

	clear
	Greeting
}

InstallAndConquer(){
	checkNetwork

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
		echo "11 - GAMES!!!!!!!!"
		echo "12 - Video editing/encoding"
		echo "13 - Proprietary fonts"
		echo "14 - Plank"
		echo "15 - Backup"
		echo "16 - THEMES!!!!!!!!"
		echo "17 - screenfetch"
		echo "18 - Stellarium constellation and space observation"
		echo "19 - Security software"
		echo "20 - exit out of this menu"
		read software;
		case $software in
			1)
			sudo eopkg install --reinstall mtr lshw hdparm tlp gparted gnome-disk-utility ncdu nmap smartmontools htop inxi gufw grsync curl net-tools
			sudo eopkg install --reinstall -c traceroute ifplugd tcpdump whois iperf cpu-x system.devel linux-current-headers smem tldr autojump cmatrix
			sudo snap install youtube-dl
			;;
			2)
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
				sudo eopkg bi --ignore-safety https://raw.githubusercontent.com/getsolus/3rd-party/master/programming/sublime-text-3/pspec.xml; sudo eopkg it sublime*.eopkg;sudo rm sublime*.eopkg
			fi
			;;
			3)
			echo "This installs a choice in download managers"
			echo "1 - wget"
			echo "2 - uget"
			read software
			if [[ $software == 1 ]];
			then
				sudo eopkg install wget
			elif [[ $software == 2 ]];
			then
				sudo eopkg install uget
			fi
			;;
			4)
			echo "1 - transmission"
			echo "2 - deluge"
			echo "3 - qbittorrent"
			read client
			if [[ $client == 1 ]];
			then
				sudo eopkg install transmission && sudo ufw allow transmission && sudo ufw reload
			elif [[ $client == 2 ]];
			then
				sudo eopkg install deluge
			elif [[ $client == 3 ]];
			then
				sudo eopkg install qbittorrent
			fi
			;;
			5)
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
			echo "1 - epiphany"
			echo "2 - falkon"
			echo "3 - midori"
			echo "4 - opera"
			echo "5 - lynx"
			echo "6 - vivaldi"
			echo "7 - vivaldi-snapshot"
			echo "8 - google-chrome"
			echo "9 - waterfox"
			echo "10 - palemoon"
			echo "11 - firefox"
			echo "12 - brave"
			echo "13 - LibreWolf"
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
				sudo eopkg install lynx
			elif [[ $browser == 6 ]];
			then
				sudo eopkg install vivaldi-stable
			elif [[ $browser == 7 ]];
			then
				sudo eopkg install vivaldi-snapshot
			elif [[ $browser == 8 ]];
			then
				sudo eopkg bi --ignore-safety https://raw.githubusercontent.com/getsolus/3rd-party/master/network/web/browser/google-chrome-stable/pspec.xml; sudo eopkg it google-chrome-*.eopkg;sudo rm google-chrome-*.eopkg
			elif [[ $browser == 9 ]];
			then
				wget https://cdn1.waterfox.net/waterfox/releases/G5.1.9/Linux_x86_64/waterfox-G5.1.9.tar.bz2; waterfox-G5.1.9.tar.bz2; sudo ln -s ~/waterfox/waterfox /usr/bin/waterfox; sudo mv waterfox /opt && sudo ln -s /opt/waterfox/waterfox /usr/bin/waterfox
				wget https://raw.githubusercontent.com/jackrabbit335/BrowserAndDesktop/main/waterfox.desktop; sudo mv waterfox.desktop /usr/share/applications/waterfox.desktop
			elif [[ $browser == 10 ]];
			then
				wget https://linux.palemoon.org/datastore/release/palemoon-32.3.1.linux-x86_64-gtk3.tar.xz; tar -xvf palemoon-32.3.1.linux-x86_64-gtk3.tar.xz; sudo ln -s ~/palemoon/palemoon /usr/bin/palemoon
				wget https://raw.githubusercontent.com/jackrabbit335/BrowserAndDesktop/main/palemoon.desktop; sudo mv palemoon.desktop /usr/share/applications/palemoon.desktop
			elif [[ $browser == 11 ]];
			then
				sudo eopkg install firefox
			elif [[ $browser == 12 ]];
			then
				sudo eopkg install brave
			elif [[ $browser == 13 ]];
			then
				flatpak install librewolf
			fi
			;;
			7)
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
			fi
			;;
			8)
			sudo eopkg install virtualbox virtualbox-guest-utils
			;;
			9)
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
				echo "You have entered an invalid number"
				InstallAndConquer
				;;
			esac
			;;
			10)
			sudo eopkg install guvcview
			;;
			11)
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
			fi
			;;
			12)
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
			sudo eopkg bi --ignore-safety https://raw.githubusercontent.com/getsolus/3rd-party/master/desktop/font/mscorefonts/pspec.xml; sudo eopkg it mscorefonts*.eopkg;sudo rm mscorefonts*.eopkg
			;;
			14)
			sudo eopkg install plank
			;;
			15)
			echo "1 - deja-dup"
			echo "2 - grsync"
			read package
			if [[ $package == 1 ]];
			then
				sudo eopkg install deja-dup
			elif [[ $package == 2 ]];
			then
				sudo eopkg install grsync
			fi
			;;
			16)
			sudo eopkg install adapta-gtk-theme moka-icon-theme mate-icon-theme-faenza faba-icon-theme numix-icon-theme arc-icon-theme evopop-icon-theme numix-gtk-theme vertex-gtk-theme arc-gtk-theme papirus-icon-theme faenza-green-icon-theme
			;;
			17)
			sudo eopkg install screenfetch
			;;
			18)
			sudo eopkg install stellarium
			;;
			19)
			sudo eopkg install firejail
			;;
			20)
			echo "Ok, well, I'm here if you change your mind"
			break
			;;
		esac
	done

	read -p "Please press enter to continue..."

	#This installs preload for faster load of apps
	echo "Would you like to install preload?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		sudo eopkg install preload && sudo systemctl enable preload && sudo systemctl start preload
	break
	done

	read -p "Please press enter to continue..."

	#This installs microcode
	cpu=$(lscpu | grep "Vendor ID:" | awk '{print $3}')
	for i in cpu;
	do
		if [[ $cpu == GenuineIntel ]];
		then
			sudo eopkg li | grep intel-microcode || sudo eopkg install intel-microcode
		fi
	done

	clear
	Greeting
}

Help(){
less <<EOF

Press "q" to quit

##########################################################################
ACKNOWLEDGEMENTS
##########################################################################
I wrote these scripts and of course, I had to learn to
do some of the things in this work. Many of the ideas came from me
but the information came from various other linux users. Without their
massive contributions to the community, this project of mine would not
be possible. A list of acknowledgements below:
Joe Collins
Quidsup
SwitchedtoLinux
Matthew Moore
Chris Titus
Average Linux User
Joshua Strobl of the Solus project
Steven Black,
The creator of the other hosts lists I utilize on my own machines.
Many others...

##########################################################################
WELCOME AND RAMBLE WITH LICENSING
##########################################################################
Welcome to Solus-Toolbox. This is a useful little utility that
tries to setup, maintain, and keep up to date with the latest
software on your system. Solus-Toolbox is delivered as is and thus,
I can not be held accountable if something goes wrong. This software is
freely given under the GPL license and is distributable and changeable
as you see fit, I only ask that you give the author the credit for the
original work. Solus-Toolbox has been tested and should work on your
device assuming that you are running an Solus-based system.
A cronjob is any task or script that you place in the crontab file to be
ran at a certain time.It should be noted that Solus has
taken a slightly different approach to dealing with task scheduling.
Solus prefers to rely on Systemd. To not go to deep into it,
the basic syntax is
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
00 20 * * * /bin/sh /home/USER/hostsupdater.sh.
I set it up under the root account by typing su followed by my password
in manjaro, sudo -i in Ubuntu systems and then typing crontab -e.
The maintenance scripts are ok to run manually each month.
It is recommended that you do not run these without being present.
However, if you wish to run them as cron jobs then you can tweak the
cleaning routines as follows."sudo rm -r ./cache/*" should be changed to
"rm -r /home/USER/.cache/*" and etc. The setup script should only be
ran once to set the system up.
Some good reference sites are:
https://wiki.manjaro.org/index.php?title=Main_Page
https://wiki.archlinux.org
https://forum.manjaro.org
https://kaosx.us/docs/
https://getsol.us/help-center/home/
https://averagelinuxuser.com/after-installing-solus/

##########################################################################
UPDATE ROLLBACK FEATURE
##########################################################################
EOPKG in Solus provides its own rollback feature. To use this feature,
you have to know the number in the historical record of operations
in EOPKG. EOPKG records every action taken to update repos and the system
since installation. Using a simple command string like sudo eopkg history
will give you a rather lengthy list of these operations in the terminal.
To rollback to a previous package state, you only need to issue the comm-
and sudo eopkg history -t and the number of the state you wish to revert
to. This will be available in a future release of this script and can be
quite handy in troubleshooting situations(specifically when booting older-
kernels does not help). More on this can be found here:
https://getsol.us/articles/package-management/history-and-rollback/en/
Of course, this does probably require package cache to be left alone,
however, in some situations, you can not install updates with invalid or
corrupted packages in there.

##########################################################################
SCREEN RESOLUTION
##########################################################################
As you can see with the newest releases of my toolbox scripts, I have
implemented a new function which leverages xrandr to allow the user to
pick and choose their screen resolution. Sometimes Linux does not always
choose the best resolution for your needs, this is why this was implemen-
ted. Simply type the number for ScreenFix and it will prompt you with
a list of possible screen resolutions supported by your distribution.
Choose the proper resolution to fit with your monitor and go. Sometimes
Linux uses ancient 800x600 resolutions or some other resolution that is
either too big or small and this can be caused by the driver or some other
issue. Xrandr will allow you to save your resolution in place and keep it
consistent between boots. Xrandr is installed in most distributions now-
adays. I have recently added a monitor configuration file to Github. Is a
template only and if you use it you will have to tweak it to fit your
needs. See 10-monitor.conf. This file is to be placed in
/etc/X11/xorg.conf.d/

##########################################################################
WATERFOX CLASSIC OVER THIRD GEN
##########################################################################
I have chosen to continue to support the installation of Waterfox class-
ic edition over the newest Third Gen as the classic allows users to
retain many of their older npapi extensions. Old extensions went out
Firefox changed to their new engine, Quantum that only uses
Webextensions now. Web extensions are still good and viable for the
future, however, many users complained when this change took place.
This is not a permanent thing and I will eventually switch it over,
this just allows users their convenience and peace of mind for now.

##########################################################################
SECURITY IN KAOS WITH TOMOYO AND SOME STUFF WITH UFW
##########################################################################
UFW is the uncomplicated firewall. Firewalls filter content getting in
and going out on your local network. UFW is meant to make interfacing
with iptables on Linux much easier. IPtables is the kernel version of
the firewall. UFW comes with default deny and allow rules set up for
convenience and peace of mind for new users so starting it up is enough
to implement basic security of a firewall on your system, however, ufw
does not allow user specific ports to be opened on the system so interven-
tion is required in such a case. UFW also is debatably needed if you have
a normal desktop usecase behind an already secured router. UFW shows blocks
in dmesg or kernel coredumps. Tomoyo is a newish security feature similar to
apparmor and SELinux in Ubuntu and DEP in Windows. This is a feature that
prevents applications from getting unnecessary permissions and access to
unnecessary files on the system. Tomoyo is the preferred method for users
of KaOS Linux and uses a learning period before it fully effects changes
on user applications. Tomoyo uses ACLs and MAC style methods of determining
application access. Tomoyo can be installed in other distributions and
can be set in the grub commandline for the kernel by using security=tomoyo.
KaOS has a basic wiki in docs to get you started with setting it up, however,
if you wish to get more in depth you will be required to go to the tomoyo
wiki.

##########################################################################
BACK UP IMPORTANT SYSTEM FILES
##########################################################################
It is important to keep a back up copy of certain system files in Arch
Linux as pacnew files become abundant on the system and these files
bring with them many changes that can help with the system, but you
are tasked with managing them yourself to get these changes.
Sometimes these said changes also cause problems to the point that your
system will be unbootable if your fstab is changed or you might lose admin
permissions if you are suddenly taken out of the wheel by the passwd file
update. It is also important to look these files over and compare them
before applying them to your system. There is a really good program in
Linux now that can help you accomplish this. The software I am referring to
is Meld. Still, it is good practice when modifying or setting up your Linux
system to keep a back up copy of many of these and so I have added it in to
this script automatically on Setup function.

##########################################################################
EOPKG AND PACKAGE MANAGERS IN GENERAL
##########################################################################
EOPKG is a package manager forked from Pisi. It is unlike any other pack-
age manager software as it does not use deb or rpm package formats by
default. EOPKG is meant to be used with Solus OS and is therefore the
work of its developers. Solus is kinda low on Software titles at the
moment, however, it is quickly growing. EOPKG uses third party repos
as well as its own repo to give users a more robust range of software.
The third party repository fetches software from remote servers and
installs the software on the system using the EOPKG standard technique
of software management. Solus also ships with snapd by default. This
allows the user access to even more software, some even platform
agnosticated packages like Notepad Plus Plus(Still wont work on linux).
Snap also offers Chromium as the standard repository does not, at this
time, ship it. The differences in package management is among
the multitude of things that make Solus different. Developing working
scripts for the three major OSes required a deal of research and trial
and error. This is not the only reason, but it is a big one as to why
there are three toolbox scripts rather than just one. Upgrading is
simple with this one though and learning a few key commands should get
you by. All the main commands will be used in this script so enjoy.
Sudo eopkg up will update the system, while sudo eopkg remove name
will remove an application. To install an application in the standard
repo simply type sudo eopkg install name.

##########################################################################
FLATPAKS AND SNAPS
##########################################################################
Flatpaks and snaps are package formats that are universal across platforms
and every Linux distribution can run the same package version and get the
same updates at the same time. These formats allow for the developers to
load the correct dependencies with the package every time. This prevents
broken packages which are common with apt. These formats also allow for
users of LTS and Interim releases to use more up to date packages and a
wider range of such packages similar to what is offered in Arch Linux
with the AUR. Flatpaks and snaps are both offered from a central
repository and setting up the two managers on Ubuntu systems are
relatively painless. setting up snapd consists mostly of just in-
stalling snapd on Ubuntu. To install simply type: sudo apt update &&
sudo apt install snapd && sudo snap install snapd. To set up flatpaks,
ensure flatpak is installed on your distribution, you can find it in the
package manager repository on most distros. Then install the flathub
repository by typing: flatpak remote-add --if-not-exists flathub
https://flathub.org/repo/flathub.flatpakrepo and that is it. Cleaning flat-
paks is a pretty easy endeavor as well. sudo flatpak --user uninstall --unused.
To repair broken flatpaks or flatpak itself; sudo flatpak repair.
To install apps sudo flatpak install appname; sudo flatpak uninstall appname.
Users can remove them as well with the --user flag(Which negates the need for sudo).
To refresh and install/uninstall snaps; sudo snap refresh(Update)
sudo snap install appname/sudo snap remove appname. It may be
necessary to reboot after installing snap or flatpak to ensure it loads
and updates the path properly.

##########################################################################
ClEANING AND ROUTINE MAINTENANCE
##########################################################################
Within this and the other two scripts is a section devoted to cleaning
and maintaining the system. Cleaning is not as necessary as in
Windows, however, it is something to consider doing when things
are not working right or when disk space is becoming sparse. Maintenance
is another function that this script will provide. Maintainence in this
script is classified as anything to promote the continued level of
security and optimization necessary for smooth running of the system.
Maintenace can be done anytime that you wish and will include things like
basic checking of the network and ensuring the firewall is enabled.
offering to run trim on ssd hardware and offering to check fragmentation
on mechanical hard drives. Updating the system and fixing minor updating
issues are also included in this function. Man pages get updated while
older ones get purged from the system as well as file databases are
ammended as needed. The grub configurations get updated incase of changes
made and not accounted for since last boot, there is also a flag file
created to force fsck to run and fix any file system corruption it finds
on next boot. The user is then asked if the user would like to run clean up
as well. Cleaning handles things like removing all cache and thumbnails
from the system as well as freeing memory taken up and clearing tmp which
does get cleared on boot. Cleaning also clears broken symbolic links and
remnant cloned files and left over application files in the home folder.
It also does the standard and cleans the bash history and removes old
update cache and orphaned packages among other things. When ran together,
these items can make a significant and noticeable difference in the
smooth and secure feeling of your distribution.

##########################################################################
SYSTEM INFORMATION
##########################################################################
This script has the ability to help with troubleshooting as well. It can
collect hardware and software information for troubleshooting issues
online as well as for reinstalling fresh in the future. This script
tries to make things as clear to read as possible by separating the
different information into categories. Each category pertains to things
such as hardware, software, login attempts and many more things. This
data will be saved to one rather large text file in the home folder of
the user who executes the script. Many of this will be useless to a new
user, so there are online forums for help.

##########################################################################
KERNELS AND SERVICES
##########################################################################
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
services. It should be noted that in Solus, the default kernel package
is the linux-current package. Users can still use this script during
setup to install the LTS if they so choose.

##########################################################################
MICROCODE
##########################################################################
Microcode is a piece of system language programming that is used in
giving instructions to the CPU(Brain of the device). Microcode updates
are not only important for updating the security of the CPU, but also
for extending the functionality as well. Some systems wont benefit from
this, but most will. Microcode helps to lock down certain Spectre
vulnerabilities. Modern multi-step and multithreading architectures
will make some use of microcode as it can help make some hardware designed
for less to do more. In a sense, it can make weaker CPUs seemingly more
powerful. Most Linux distributions have begun making this piece of code
stock baked into their kernels, however, I have added functionality that
tries to install this piece of coding in the event that it wasnt installed
and or loaded already. On most systems, Intel microcode is wrapped in the
package intel-ucode, while AMDs microcode is wrapped under amd-ucode.

##########################################################################
FIRMWARE UPGRADES
##########################################################################
Firmware upgrades are handled by an automated systemctl utility which
periodically checks for bios and other firmware upgrades on your system.
Bios upgrades don't typically work with legacy enabled, At least not UEFI
upgrades. To enable this to work you need to disable legacy temporarily in
Bios. Firmware upgrades can include nvme and ssd various other devices as 
well. Firmware is the layer of programming that sits between the hardware 
and the OS or in this case the hardware and the Operating system on-board 
the CPU.

##########################################################################
BACKUP AND RESTORE
##########################################################################
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
Update: There is now an ability to backup the entire system using rsync.
With this new ability, in time there should be a way to restore the
system in the event of a catastrophic issue.

##########################################################################
Recent Changes with Installing certain apps and things
##########################################################################
Since Pale Moon 28.x there have been some changes as to how we install
the browser. Pale Moons lead Developer states how to install the browser
in Linux systems via this page: http://linux.palemoon.org/help/installation/ 
I have still added a basic set up of palemoon that will extract the browser 
and send it to the home directory while allowing the user to set up a symbolic 
link to the usr bin directory. This will allow you to use the browser by 
typing the name into a terminal much like any other application. For more 
tips and details see his website. Also, due to recently working with a 
friend on her laptop, I have found the need for Wine and so I added a 
simple command way to install wine on newer systems. Will work on this 
further.

##########################################################################
HOSTS FILE MANIPULATION
##########################################################################
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
browser. Update: I have finally created the perfect script for
automation. Now users are able to create the perfect hosts file
for them Without being bothered to answer questions. The defaults
I have chosen cover a broad spectrum of Ads, Trackers and Malware,
for your convenience.

##########################################################################
SWAP FILES
##########################################################################
Swap files are an important asset to any Linux system. Swap files are
responsible for storing temporary data when there is no available memory
left on the device. Swap is also useful for storing system contents
during hibernation etc. These scripts will eventually all have the ability
to create one in the event that your system does not currently have
one. The blog article about this issue can be found here:
https://techiegeek123.blogspot.com/2019/02/swap-files-in-linux.html.
Please  email me at VeilofMaya@vivaldi.net for more info about
these scripts or any problems you have with Linux. I will be more than
happy to help. One further notice, the Swap file size is configurable
for users who are somewhat advanced enough to go into the code and
change the size from 2G to whatever they desire.

##########################################################################
LINUX PERMISSIONS
##########################################################################
Unlike Windows, Linux permissions are a bit different. There is a learning
curve to implementing specially tailored policies on Linux that are just
easier in Windows. Linux uses numbers frequently to determine the read,
write, and execute permissions of the files on the disk. Sometimes in Arch,
these numbers do not always match up after an update. Users and Groups assi-
gned to each can be found in the etc-passwd or etc-group files. When
changing user and groups assigned to a file, the numbers also change.
A general rule of thumb is that 4 is equal to read, 1 to execute, and
2 to write. So a series of numbers like 755 would imply that the user and
group is probably different from the way in which these attributes were
assigned originally on your system by default. It was probably something
like 777 or something, but everyones system is different. It is simple
enough to change with either the chown or chmod commands, but I have yet
to figure out an easy way to streamline this for new users in these scripts.
I will get there though, so please be patient. A good website to better
explain this is:https://www.guru99.com/file-permissions.html

##########################################################################
SUDO VERSION CHECKING
##########################################################################
With recent news of possible privilege escalation bugs found in sudo, I
figured it wise to include a sudo version check option in SystemInfo.
This will check for version numbers of sudo and sudo plugins. Versions
1.8 are privy to the bug and some early 1.9 versions(eg. 1.9.2). 1.9.5
should be immune, however as with sudo, many more bugs will eventually
be discovered. It is imperative to keep your system updated regularly
to patch these kinds of vulnerabilities.

##########################################################################
CONTACT ME
##########################################################################
For sending me hate mail, for inquiring assistance, and for sending me
feedback and suggestions, email me at VeilofMaya@vivaldi.net
Send your inquiries and suggestions with a corresponding subject line.
EOF

	clear
	Greeting
}

AccountSettings(){
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
		sleep 1
		read -p "Please enter the groups you wish the user to be in:" $group1 $group2 $group3
		echo "Please enter the name of the user"
		read name
		echo "Please enter the password"
		read password
		sudo useradd $name -m -s /bin/bash -G $group1 $group2 $group3; echo $password | passwd --stdin $name
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
		sudo cat /etc/shadow | awk -F: '($2==""){print $1}' >> ~/accounts.txt; cat /etc/passwd | awk -F: '{print $1}' >> ~/accounts.txt
		;;
		5)
		echo "########################################################################" >> Accounts.txt
		echo "USERS AND GROUPS" >> Accounts.txt
		echo "########################################################################" >> Accounts.txt
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

checkNetwork(){
	for c in computer;
	do
		ping -c4 google.com
		if [[ $? -eq 0 ]];
		then
			echo "Connection successful"
		else
			read -p "Check hardware cable status and press enter..."
			interface=$(ip -o -4 route show to default | awk '{print $5}')
			sudo dhclient -v -r && sudo dhclient; sudo systemctl stop NetworkManager.service
			sudo systemctl disable NetworkManager.service; sudo systemctl enable NetworkManager.service
			sudo systemctl start NetworkManager.service; sudo ip link set $interface up
		fi
	done
}

Adblocking(){
	find Hostsman4linux.sh
	while [ $? -eq 1 ];
	do
		wget https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/Hostsman4linux.sh; chmod +x Hostsman4linux.sh
	break
	done
	sudo ./Hostsman4linux.sh -ABCD

	clear
	Greeting
}

Firmware_Upgrades(){
    sudo /usr/bin/fwupdmgr refresh && sudo /usr/bin/fwupdmgr update
    
    clear
    Greeting
}

MakeSwap(){
	#This attempts to create a swap file in the event the system does not have swap
	cat /etc/fstab | grep "swap"
	if [ $? -eq 0 ];
	then
		sudo fallocate --length 2G /swapfile; chmod 600 /swapfile; sudo mkswap /swapfile; sudo swapon /swapfile; echo "/swapfile swap swap sw 0 0" | sudo tee -a /etc/fstab
	else
		echo "Swap was already there so there is nothing to do"
	fi
	cat /proc/swaps >> swaplog.txt; free -h >> swaplog.txt

	Restart
}

Uninstall(){
	echo "Would you like to remove any other unwanted junk?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		read -a software
		sudo eopkg -y autoremove ${software[@]}; flatpak --user uninstall ${software[@]}
	break
	done

	clear
	Greeting
}

RAMBack(){
	sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches"

	clear
	Greeting
}

cleanup(){
	#This will clean the cache
	sudo rm -r {.cache/*,.thumbnails/*,~/.local/share/Trash/files/*,~/.nv/*,~/.npm/*,~/.w3m/*,~/.esd_auth,~/.local/share/recently-used.xbel,/.tmp/*,/var/tmp/*}; history -c && rm ~/.bash_history

	#This remove old configurations for software
	sudo rm -r ~/.config/*-old
	
	#This removes Internet Traces from Firefox
	#sudo rm -rf ~/.mozilla/firefox/*.default-release/storage/default/*; sudo rm -rf ~/.mozilla/firefox/*.default-release/{places.sqlite,cookies.sqlite,formhistory.sqlite}

	#This could clean your Video folder and Picture folder based on a set time
	TRASHCAN=~/.local/share/Trash/files/
	find ~/Downloads/* -mtime +30 -exec mv {} $TRASHCAN \;
	#find ~/Video/* -mtime +30 -exec mv {} $TRASHCAN \;
	#find ~/Pictures/* -mtime +30 -exec mv {} $TRASHCAN \;

	#Sometimes it's good to check for and remove broken symlinks
	find -xtype l -delete

	#clean some unneccessary files leftover by applications in home directory
	find $HOME -type f -name "*~" -print -exec rm {} \;

	#cleans old kernel crash logs
	sudo find /var -type f -name "core" -print -exec rm {} \;

	#This helps get rid of old archived log entries
	sudo journalctl --vacuum-size=25M

	#This will remove orphan packages from eopkg
	sudo eopkg remove-orphans

	#Optional This will remove the eopkg cached applications, cleans stale blocks, etc.
	sudo eopkg delete-cache; sudo eopkg clean
	
	#This cleans flatpaks that are unused by the user
	#flatpak --user uninstall --unused

	#This will also remove unwanted programs
	echo "Would you like to remove software?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		Uninstall
	done
	
	clear
	Greeting
}

BrowserRepair(){
	browser1="$(find /usr/bin/firefox)"
	browser2="$(find /usr/bin/vivaldi*)"
	browser3="$(find /usr/bin/palemoon)"
	browser4="$(find /usr/bin/google-chrome*)"
	browser5="$(find /usr/bin/opera)"
	browser6="$(find /usr/bin/vivaldi-snapshot)"
	browser7="$(find /usr/bin/waterfox)"
	browser8="$(find /usr/bin/epiphany)"
	browser9="$(find /usr/bin/midori)"
	browser10="$(find /usr/bin/brave-browser)"
	browser11="$(find /usr/bin/falkon)"
	browser12="$(find /usr/bin/qutebrowser)"

	echo $browser1
	echo $browser2
	echo $browser3
	echo $browser4
	echo $browser5
	echo $browser6
	echo $browser7
	echo $browser8
	echo $browser9
	echo $browser10
	echo $browser11
	echo $browser12

	sleep 1

	echo "choose the browser you wish to reset"
	echo "1 - Firefox"
	echo "2 - Vivaldi"
	echo "3 - Pale Moon"
	echo "4 - Chrome"
	echo "5 - Opera"
	echo "6 - Vivaldi-snapshot"
	echo "7 - Waterfox"
	echo "8 - Epiphany"
	echo "9 - Midori"
	echo "10 - Brave"
	echo "11 - Falkon"
	echo "12 - Qutebrowser"
	read operation;
	case $operation in
		1)
		sudo cp -r ~/.mozilla/firefox ~/.mozilla/firefox-old; sudo rm -rf ~/.mozilla/firefox/*
		echo "Your browser has now been reset"
		sleep 1
		;;
		2)
		sudo cp -r ~/.config/vivaldi/ ~/.config/vivaldi-old; sudo rm -rf ~/.config/vivaldi/*
		echo "Your browser has now been reset"
		sleep 1
		;;
		3)
		sudo cp -r ~/'.moonchild productions'/'pale moon' ~/'.moonchild productions'/'pale moon'-old; sudo rm -rf ~/'.moonchild productions'/'pale moon'/*
		echo "Your browser has now been reset"
		sleep 1
		;;
		4)
		sudo cp -r ~/.config/google-chrome ~/.config/google-chrome-old; sudo rm -rf ~/.config/google-chrome/*
		echo "Your browser has now been reset"
		sleep 1
		;;
		5)
		sudo cp -r ~/.config/opera ~/.config/opera-old; sudo rm -rf ~/.config/opera/*
		echo "Your browser has now been reset"
		sleep 1
		;;
		6)
		sudo cp -r ~/.config/vivaldi-snapshot ~/.config/vivaldi-snapshot-old; sudo rm -rf ~/.config/vivaldi-snapshot/*
		echo "Your browser has now been reset"
		sleep 1
		;;
		7)
		sudo cp -r ~/.waterfox ~/.waterfox-old; sudo rm -rf ~/.waterfox/*
		echo "Your browser has now been reset"
		sleep 1
		;;
		8)
		sudo cp -r ~/.config/epiphany ~/.config/epiphany-old; sudo rm -rf ~/.config/epiphany/*
		sudo cp -r ~/.local/share/epiphany ~/.local/share/epiphany-old; sudo rm -rf ~/.local/share/epiphany/*
		echo "Your browser has now been reset"
		sleep 1
		;;
		9)
		sudo cp -r ~/.config/midori ~/.config/midori-old; sudo rm -rf ~/.config/midori/*
		echo "Your browser has now been reset"
		sleep 1
		;;
		10)
		sudo cp -r ~/.config/BraveSoftware ~/.config/BraveSoftware-old; sudo rm -rf ~/.config/BraveSoftware/*
		echo "Your browser has now been reset"
		sleep 1
		;;
		11)
		sudo cp -r ~/.config/falkon ~/.config/falkon-old; sudo rm -rf ~/.config/falkon/*
		echo "Your browser has now been reset"
		sleep 1
		;;
		12)
		sudo cp -r ~/.config/qutebrowser ~/.config/qutebrowser-old; sudo rm -rf ~/.config/qutebrowser/*
		sudo cp -r ~/.local/share/qutebrowser ~/.local/share/qutebrowser-old; sudo rm -rf ~/.local/share/qutebrowser/*
		echo "Your browser has been reset"
		sleep 1
		;;
		*)
		echo "No browser for that entry exists, please try again!"
		sleep 1

		BrowserRepair
		;;
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

TraceCleaner(){
	echo "Choose a browser to clean"
	echo "1 - Firefox"
	echo "2 - Google Chrome"
	echo "3 - Vivaldi"
	echo "4 - All of the above"
	read operation;
	case $operation in
		1)
		sudo rm -rf ~/.mozilla/firefox/*.default-release/storage/default/*; sudo rm -rf ~/.mozilla/firefox/*.default-release/{places.sqlite,cookies.sqlite,formhistory.sqlite}
		;;
		2)
		sudo rm -rf ~/.config/google-chrome/Default/Cookies; sudo rm -rf ~/.config/google-chrome/Default/History; sudo rm -rf ~/.config/google-chrome/{}
		;;
		3)
		sudo rm -rf ~/.config/vivaldi/Default/Cookies; sudo rm -rf ~/.config/vivaldi/Default/History; sudo rm -rf ~/.config/vivaldi/{}
		;;
		4)
		sudo rm -rf ~/.mozilla/firefox/*.default-release/storage/default/*; sudo rm -rf ~/.mozilla/firefox/*.default-release/{places.sqlite,cookies.sqlite,formhistory.sqlite}; sudo rm -rf ~/.config/google-chrome/Default/Cookies; sudo rm -rf ~/.config/google-chrome/Default/History; sudo rm -rf ~/.config/google-chrome/{}; sudo rm -rf ~/.config/vivaldi/Default/Cookies; sudo rm -rf ~/.config/vivaldi/Default/History; sudo rm -rf ~/.config/vivaldi/{}
		;;
		*)
		echo "No browser for that number exists, please try again."
		sleep 1
		TraceCleaner
		;;
	esac

 	clear
  	Greeting
   }

SystemMaintenance(){
	checkNetwork

	#This attempts to fix databases and update your system
	sudo eopkg -y rebuild-db; sudo eopkg -y upgrade
	
	#Repairs flatpaks installed on your system not everyone has these on Ubuntu
	#flatpak repair; flatpak update

	#This checks for broken packages
	sudo eopkg check | grep Broken | awk '{print $4}' | xargs sudo eopkg -y install --reinstall

	#This refreshes systemd in case of or changed configurations of units
	sudo systemctl daemon-reload

	#This will reload the firewall to ensure it's enabled
	sudo systemctl restart ufw; sudo ufw enable

	#This refreshes file index
	sudo updatedb && sudo mandb
	
	#This updates icon cache
	sudo gtk-update-icon-cache

	#update the grub
	sudo clr-boot-manager update

	#This runs a disk checkup and attempts to fix filesystem
	sudo touch /forcefsck

	#Optional and prolly not needed
	drive=$(cat /sys/block/sda/queue/rotational)
	for rota in drive;
	do
		if [[ $drive == 1 ]];
		then
			sudo e4defrag / -c > fragmentation.log
		elif [[ $drive == 0 ]];
		then
			sudo fstrim -v --all
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

ServiceManager(){
	systemctl list-unit-files --type=service
	read -p "Press enter to continue..."
	echo "What would you like to do?"
	echo "1 - enable service"
	echo "2 - disable service"
	echo "3 - mask service"
	echo "4 - reset failed"
	echo "5 - save a copy of all the services on your system to a text file"
	echo "6 - Exit without doing anything"
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
		echo "Please enter the name of a service to mask"
		read service
		sudo systemctl mask $service
		echo "Would you like to reboot?(Y/n)"
		read answer
		while [ $answer == Y ];
		do
			Restart
		break
		done
		;;
		4)
		sudo systemctl reset-failed
		;;
		5)
		echo "########################################################################" >> services.txt
		echo "SERVICES MANAGER" >> services.txt
		echo "########################################################################" >> services.txt
		systemctl list-unit-files --type=service >> services.txt
		echo "########################################################################" >> services.txt
		echo "END OF FILE" >> services.txt
		echo "########################################################################" >> services.txt
		echo "Thank you for your patience"
		sleep 1
		;;
		6)
		echo "Smart choice."
		sleep 1
		;;
	esac

	clear
	Greeting
}

Restart(){
	sudo sync && sudo systemctl reboot
}

Backup(){
	echo "What would you like to do?"
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
			sudo mount $device /mnt; sudo rsync -aAXv --delete --exclude={"*.cache/*","*.thumbnails/*","*/.local/share/Trash/*"} /home/$USER /mnt/$host-backups; sudo sync; sudo umount $device
		elif [[ $Mountpoint == /run/media/$USER/* ]];
		then
			read -p "Found a block device at designated coordinates...If this is the preferred drive, unmount it, leave it plugged in, and run this again. Press enter to continue..."
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
			sudo mount $device /mnt; sudo rsync -aAXv --delete --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} / /mnt/$host-backups; sudo sync; sudo umount $device
		elif [[ $Mountpoint == /run/media/$USER/* ]];
		then
			echo "Found a block device at designated coordinates...If this is the preferred drive, unmount it, leave it plugged in, and then run this again. Press enter to continue..."
		fi
		;;
		*)
		echo "This is an invalid entry, please try again"
		;;
	esac

	clear
	Greeting
}

Restore(){
	Mountpoint=$(lsblk | awk '{print $7}' | grep /run/media/$USER/*)
	if [[ $Mountpoint != /run/media/$USER/* ]];
	then
		read -p "Please insert the backup drive and hit enter..."
		echo $(lsblk | awk '{print $1}')
		sleep 1
		echo "Please select the device from the list"
		read device
		sudo mount $device /mnt; sudo rsync -aAXv --delete --exclude={"*.cache/*","*.thumbnails/*"."*/.local/share/Trash/*"}  /mnt/$host-$date-backups/* /home; sudo sync
		Restart
	elif [[ $Mountpoint == /run/media/$USER/* ]];
	then
		read -p "Found a block device at designated coordinates... If this is the preferred drive, try unmounting the device, leaving it plugged in, and running this again. Press enter to continue..."
	fi

	clear
	Greeting
}

Disclaimer(){
cat <<EOF
##########################################################################
Hello! Thank you for using Arch Toolbox. Within this script is a multitu-
de of potential solutions for every day tasks as trivial as maintenance,
all the way to as important as setting up a new system. This script is
meant for new users, but anyone can read, change and use this script to
their liking. This script is to be placed under the GPLv3 and is to be
redistributable, however, if you are distributing, I would appreciate it
if you gave the credit back to the original author. I should also add that
I have a few blog articles which may or may not be of benefit for newbies
on occasion. The link will be placed here. In the blog I write about
typical scenarios that I face on a day to day basis as well as add commen-
tary and my opinions about software and technology. You may copy and paste
the following link into your browser: https://techiegeek123.blogspot.com/
Again, Thank you!
##########################################################################
EOF
read -p $'\n'$"Press enter to continue..."
}

Greeting(){
	echo $'\n'$"Enter a selection from the following list"
	echo "1 - Setup your system"
	echo "2 - Add/Remove user accounts"
	echo "3 - Install software"
	echo "4 - Uninstall software"
	echo "5 - Setup a hosts file"
	echo "6 - Backup your important files and photos"
	echo "7 - Restore your important files and photos"
	echo "8 - Manage system services"
	echo "9 - Collect system information for troubleshooting"
	echo "10 - Screen Resolution Switcher"
	echo "11 - Cleanup"
	echo "12 - System Maintenance"
	echo "13 - RAMBack"
	echo "14 - Browser Repair"
 	echo "15 - Trace Cleaner"
	echo "16 - Update"
	echo "17 - Downgrade"
	echo "18 - MakeSwap"
	echo "19 - Help"
	echo "20 - Restart"
	echo "21 - Reset the desktop"
	echo "22 - Firmware Upgrades"
	echo "23 - exit"
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
		Adblocking
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
		ScreenFix
		;;
		11)
		cleanup
		;;
		12)
		SystemMaintenance
		;;
		13)
		RAMBack
		;;
		14)
		BrowserRepair
		;;
  		15)
    		TraceCleaner
      		;;
		16)
		Update
		;;
		17)
		Downgrade
		;;
		18)
		MakeSwap
		;;
		19)
		Help
		;;
		20)
		Restart
		;;
		21)
		Reset
		;;
		22)
		Firmware_Upgrades
		;;
		23)
		echo $'\n'$"Thank you for using Solus-Toolbox... Goodbye!"
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

Disclaimer
Greeting
