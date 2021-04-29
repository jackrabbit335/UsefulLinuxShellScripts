#!/bin/bash

Setup(){
	#This sets your default editor in bashrc
	echo "export EDITOR=nano" | sudo tee -a /etc/bash.bashrc

	#This backs up important system files for your convenience
	sudo cp /etc/sysctl.conf /etc/sysctl.conf.bak
	sudo cp /etc/systemd/logind.conf /etc/systemd/logind.conf.bak
	sudo cp /etc/systemd/system.conf /etc/systemd/system.conf.bak
	sudo cp /etc/systemd/coredump.conf /etc/systemd/coredump.conf.bak
	sudo cp /etc/systemd/journald.conf /etc/systemd/journald.conf.bak
	sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
	sudo cp /etc/sudoers /etc/sudoers.bak
	sudo cp /etc/login.defs /etc/login.defs.bak
	sudo cp /etc/environment /etc/environment.bak
	sudo cp /etc/profile /etc/profile.bak
	sudo cp /etc/bash.bashrc /etc/bash.bashrc.bak
	sudo cp /etc/default/grub /etc/default/grub.bak
	sudo cp /etc/fstab /etc/fstab.bak
	sudo cp /etc/passwd /etc/passwd.bak
	sudo cp /etc/shadow /etc/shadow.bak
	sudo cp /etc/host.conf /etc/host.conf.bak
	sudo cp -r /boot /boot-old
	cp .bashrc .bashrc.bak
	cp .xsession-errors .xsession-errors.bak

	#Fix screen RESOLUTION
	echo "Would you like to choose a more accurate screen resolution?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		Screenfix
		break
	done

	#This activates the firewall
	dpkg --list | grep ufw || sudo apt install -y gufw; sudo systemctl enable ufw; sudo ufw default deny incoming; sudo ufw default allow outgoing; sudo ufw enable
	echo "Would you like to deny ssh and telnet for security purposes?(Y/n)"
	read answer
	if [[ $answer == Y ]];
	then
		sudo ufw deny telnet; sudo ufw deny ssh; sudo ufw reload
	fi

	#This disables ipv6
	echo "Sometimes ipv6 can cause network issues. Would you like to disable it?(Y/n)"
	read answer
	if [[ $answer == Y ]];
	then
		sudo sed -i -e 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="ipv6.disable=1"/g' /etc/default/grub; sudo update-grub2
	else
		echo "Okay!"
	fi

	#This adds a few aliases to bashrc
	echo "Aliases are shortcuts to commonly used commands."
	echo "would you like to add some aliases?(Y/n)"
	read answer
	if [[ $answer == Y ]];
	then
		echo "#Alias to update the system" >> ~/.bashrc
		echo 'alias update="sudo apt update && sudo apt dist-upgrade -yy"' >> ~/.bashrc
		echo "#Alias to clean the apt cache" >> ~/.bashrc
		echo 'alias clean="sudo apt autoremove && sudo apt autoclean && sudo apt clean"' >> ~/.bashrc
		echo "#Alias to free up RAM" >> ~/.bashrc
		echo 'alias boost="sudo sysctl -w vm.drop_caches=3"' >> ~/.bashrc
		echo "#Alias to trim down journal size" >> ~/.bashrc
		echo 'alias vacuum="sudo journalctl --vacuum-size=25M"' >> ~/.bashrc
		echo "#Alias to trim ssd" >> ~/.bashrc
		echo 'alias trim="sudo fstrim -v --all"' >> ~/.bashrc
		echo "#Alias to fix broken packages" >> ~/.bashrc
		echo 'alias fix="sudo dpkg --configure -a && sudo apt install -f"' >> ~/.bashrc
		echo "#Alias to see RAM info" >> ~/.bashrc
		echo 'alias meminfo="cat /proc/meminfo"' >> ~/.bashrc
		echo "#Alias to monitor memory usage stats over time" >> ~/.bashrc
		echo 'alias mem="watch free -lh"' >> ~/.bashrc
		echo "#Alias to view cpu info" >> ~/.bashrc
		echo 'alias cpu="lscpu"' >> ~/.bashrc
		echo "#Alias to view temp readings over time" >> ~/.bashrc
		echo 'alias temp="watch sensors"' >> ~/.bashrc
		echo "#Alias to view swap info" >> ~/.bashrc
		echo 'alias swaps="cat /proc/swaps"' >> ~/.bashrc
	fi

	#System tweaks
	sudo sed -i -e '/GRUB_TIMEOUT=10/c\GRUB_TIMEOUT=3 ' /etc/default/grub; sudo update-grub2

	#Tweaks the sysctl config file
	sudo touch /etc/sysctl.d/50-dmesg-restrict.conf
	echo "kernel.dmesg_restrict = 1" | sudo tee -a /etc/sysctl.d/50-dmesg-restrict.conf
	echo "# Reduces the swap" | sudo tee -a /etc/sysctl.conf
	echo "vm.swappiness = 10" | sudo tee -a /etc/sysctl.conf
	echo "# Improve cache management" | sudo tee -a /etc/sysctl.conf
	echo "vm.vfs_cache_pressure = 50" | sudo tee -a /etc/sysctl.conf
	echo "#tcp flaw workaround" | sudo tee -a /etc/sysctl.conf
	echo "net.ipv4.tcp_challenge_ack_limit = 999999999" | sudo tee -a /etc/sysctl.conf
	sudo sysctl -p

	#Block ICMP requests or Ping from foreign systems
	cat <<EOF
	We can also block ping requests. Ping requests coming from unknown sources can mean that people are
	potentially trying to locate/attack your network. If you need this functionality
	you can always comment this line out later. Chances are, this will not affect normal users.
EOF
	echo "Block ping requests from foreign systems?(Y/n)"
	read answer
	if [[ $answer == Y ]];
	then
		echo "net.ipv4.icmp_echo_ignore_all = 1" | sudo tee -a /etc/sysctl.conf
	sudo sysctl -p
	fi

	#This attempts to place noatime at the end of your drive entry in fstab
	echo "This can potentially make your drive unbootable, use with caution"
	echo "Would you like to improve hard drive performance with noatime?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		sudo sed -i 's/errors=remount-ro 0       1/errors=remount-ro,noatime 0        1/g ' /etc/fstab
	break
	done

	#This locks down ssh
	sudo sed -i -e '/#PermitRootLogin/c\PermitRootLogin no ' /etc/ssh/sshd_config

	#This removes that stupid gnome-keyring unlock error you get with chrome
	echo "Killing this might make your passwords less secure on chrome."
	echo "Do you wish to kill gnome-keyring? (Y/n)"
	read answer
	if [[ $answer == Y ]];
	then
		sudo mv /usr/bin/gnome-keyring-daemon /usr/bin/gnome-keyring-daemon-old; sudo killall gnome-keyring-daemon
	else
		echo "Proceeding"
	fi

	#This determines what type of drive you have, then offers to run trim or enable write-back caching
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
			cat <<EOF
			Trim is enabled already on most Ubuntu systems, however, it is not
			enabled on Debian. That said, enabling Trim is easy.
EOF
			distribution=$(cat /etc/issue | awk '{print $1}')
			while [ $distribution == Debian ];
			do
				touch fstrim
				cat > fstrim <<EOF
				#!/bin/sh
				sudo fstrim --all
EOF
				sudo mv fstrim /etc/cron.weekly; sudo chmod +x /etc/cron.weekly/fstrim
			break
			done

			echo "Alternatively you can run fstrim manually(Y/n)"
			read answer
			while [ $answer == Y ];
			do
				sudo fstrim -v --all
			break
			done

		fi
	done


	#This fixes gufw not opening in kde plasma desktop
	cat <<EOF
	This will attempt to determine if your desktop is kde and resolve the kde gufw not opening issue. This is only a plasma issue as far as I know.
EOF
	for env in $DESKTOP_SESSION;
	do
		if [[ $DESKTOP_SESSION == /usr/share/xsessions/plasma ]];
		then
			echo "kdesu python3 /usr/lib/python3.7/site-packages/gufw/gufw.py" | sudo tee -a /bin/gufw
		else
			echo "You do not need this fix"
		fi
	done

	CheckNetwork

	#Updates the system
	sudo apt update; sudo apt upgrade -yy; sudo apt dist-upgrade -yy

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
	CheckNetwork

	sudo apt update; sudo apt upgrade -yy

	clear
	Greeting
}

Systeminfo(){
	dpkg --list | grep wmctrl || sudo apt install -y wmctrl
	host=$(hostname)
	drive=$(df -P / | awk '{print $1}' | grep "/dev/")
	distribution=$(cat /etc/issue | awk '{print $1,$2}')
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
	echo "WINDOW MANAGER" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	wmctrl -m >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "DISPLAY MANAGER" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	grep'/usr/s\?bin' /etc/systemd/system/display-manager.service >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "SYSTEM INITIALIZATION" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	ps -p1 | awk 'NR!=1{print $4}' >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "SYSTEM INSTALL DATE" >> $host-sysinfo.txt
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
	echo "APT REPOSITORY INFORMATION" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	cat /etc/apt/sources.list.d/official-package-repositories.list >> $host-sysinfo.txt
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
	sudo apt list --installed >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "INSTALLED SNAPS" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	snap list >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "DEB PACKAGE MANAGER HISTORY" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	cat /var/log/dpkg.log >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "APT PACKAGE MANAGER HISTORY" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	cat /var/log/apt/history.log >> $host-sysinfo.txt
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
	echo "DISK READ SPEED" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	sudo hdparm -tT /dev/sda >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "DRIVER INFO" >> $host-sysinfo.txt
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
	echo "MEMORY INFORMATION" >> $host-sysinfo.txt
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

Reset(){
	#This resets the desktop
	if [[ $DESKTOP_SESSION == cinnamon ]];
	then
		echo "############################################################################"
		echo "This resets Cinnamon"
		echo "############################################################################"
		dconf dump /org/cinnamon/ > cinnamon-desktop-backup; dconf reset -f /
	elif [[ $DESKTOP_SESSION == gnome ]];
	then
		echo "############################################################################"
		echo "This resets Gnome Shell"
		echo "############################################################################"
		dconf dump /org/gnome/ > gnome-desktop-backup; dconf reset -f /
	elif [[ $DESKTOP_SESSION == budgie ]];
	then
		echo "############################################################################"
		echo "This resets Budgie"
		echo "############################################################################"
		dconf dump /org/budgie/ > /budgie-desktop-backup; dconf reset -f /
	elif [[ $DESKTOP_SESSION == xfce ]];
	then
		echo "############################################################################"
		echo "This resets XFCE"
		echo "############################################################################"
		mv ~/.config/xfce4 ~/.config/xfce4.bak
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

MakeSwap(){
	#This attempts to create a swap file in the event the system doesn't have swap
	cat /etc/fstab | grep "swap"
	if [ $? -eq 0 ];
	then
		sudo fallocate --length 4G /swapfile; sudo chmod 600 /swapfile; sudo mkswap /swapfile; sudo swapon /swapfile; echo "/swapfile swap swap sw 0 0" | sudo tee -a /etc/fstab
	else
		echo "Swap was already there so there is nothing to do"
	fi
	cat /proc/swaps >> swaplog.txt; free -h >> swaplog.txt

	Restart
}

HELP(){
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
Welcome to Ubuntu-Toolbox. This is a useful little utility that
tries to setup, maintain, and keep up to date with the latest
software on your system. Ubuntu-Toolbox is delivered as is and thus,
I can not be held accountable if something goes wrong. This software is
freely given under the GPL license and is distributable and changeable
as you see fit, I only ask that you give the author the credit for the
original work. Ubuntu-Toolbox has been tested and should work on your
device assuming that you are running an Ubuntu-based system.
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
https://usn.ubuntu.com/
https://ubuntuforums.org/
https://forums.linuxmint.com/
https://wiki.ubuntu.com/
https://wiki.manjaro.org/index.php?title=Main_Page
https://wiki.archlinux.org
https://forum.manjaro.org
https://kaosx.us/docs/
https://averagelinuxuser.com/

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
can be set in the grub commandline for the kernel by using security = tomoyo
KaOS has a basic wiki in docs to get you started with setting it up, however,
if you wish to get more in depth you will be required to go to the tomoyo
wiki.

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
needs. See 10-monitor.conf. 10-monitor.conf will go in
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
APT/DPKG AND PACKAGE MANAGERS IN GENERAL
##########################################################################
Aptitude has been around in one form or another since Ubuntu and Ubuntu-
based systems began. Apt covers a wide range of applications, however,
the applications in Ubuntu repositories can sometimes be outdated or
scarce. Enter DPKG. DPKG handles files in a .deb format which can package
multiple files together in a tighter and smaller sized bundle. This bundle
can then be unarchived and assembled easily by a Debian-based system.
Ubuntu is built on Debian code, so this being carried over was only
natural. .deb packages still do not handle dependencies very well, This
is one of the reasons for some applications moving to Snap. Snap is yet
another package management system that is coming installed into newer
Ubuntu systems along with Flatpak. Between these two, the idea is that
dependency resolutions and more updated software would come faster and easier
to the user and developers with just one package. It would be easier to
maintain a Linux system or any other system if they were all using the
same package across multiple platforms and distributions getting the same
version updates at the same time. While a step in the right direction, it
will be a while before they fully catch on.

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
on next boot. The user is then asked if the user would like to run clean
up as well. Cleaning handles things like removing all cache and thumbnails
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
services.

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
I have set up of palemoon that will extract the browser and send it to the opt
directory while allowing the user to set up a symbolic link to the usr
bin directory. This will allow you to use the browser by typing the name
into a terminal much like any other application. For more tips and details
see his website. Also, due to recently working with a friend on her
laptop, I have found the need for Wine and so I added a simple command
way to install wine on newer systems. Will work on this further.

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

Screenfix(){
	xrandr
	echo "Choose a resolution from the list above"
	read resolution
	xrandr -s $resolution
}

InstallAndConquer(){
	CheckNetwork

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
		echo "8 - terminal"
		echo "9 - video and audio editing"
		echo "10 - preload"
		echo "11 - Webcam application"
		echo "12 - bleachbit cleaning software and gtkorphan"
		echo "13 - proprietary fonts"
		echo "14 - THEMES"
		echo "15 - GAMES"
		echo "16 - Virtualbox"
		echo "17 - Wine and or PlayonLinux"
		echo "18 - Dropbox"
		echo "19 - get out of this menu"
		read software;
		case $software in
			1)
			echo "1 - Geany"
			echo "2 - Sublime"
			echo "3 - atom"
			echo "4 - meld"
			echo "5 - Visual Studio"
			echo "6 - all"
			read package
			if [[ $package == 1 ]];
			then
				sudo apt install -y geany
			elif [[ $package == 2 ]];
			then
				sudo snap install sublime-text
			elif [[ $package == 3 ]];
			then
				sudo snap install atom
			elif [[ $package == 4 ]];
			then
				sudo apt install -y meld
			elif [[ $package == 5 ]];
			then
				sudo snap install vscodium
			elif [[ $package == 6 ]];
			then
				sudo apt install -y geany meld; sudo snap install sublime-text atom vscodium
			fi
			;;
			2)
			echo "1 - rkhunter"
			echo "2 - clamav"
			echo "3 - chkrootkit"
			echo "4 - all of the above"
			read package
			if [[ $package == 1 ]];
			then
				sudo apt install -y rkhunter
			elif [[ $package == 2 ]];
			then
				sudo apt install -y clamav && sudo freshclam
			elif [[ $package == 3 ]];
			then
				sudo apt install -y chkrootkit
			elif [[ $package == 4 ]];
			then
				sudo apt install -y rkhunter && sudo rkhunter --propupd && sudo rkhunter --update
				sudo apt install -y clamav && sudo freshclam; sudo apt install -y chkrootkit
			fi
			;;
			3)
			sudo apt install -y hddtemp hdparm ncdu nmap hardinfo traceroute tlp grsync p7zip zip software-properties-gtk
			sudo apt install -y gnome-disk-utility htop iotop atop inxi powertop file-roller xdg-user-dirs build-essential
			sudo apt install -y xsensors lm-sensors gufw gparted smartmontools keepassxc unrar curl unzip ffmpeg
			sudo snap install youtube-dl
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
			echo "3 - Falkon"
			echo "4 - Midori"
			echo "5 - Google-Chrome"
			echo "6 - Pale Moon"
			echo "7 - Vivaldi"
			echo "8 - Opera"
			echo "9 - Lynx"
			echo "10 - Dillo"
			echo "11 - Waterfox"
			echo "12 - Basilisk"
			echo "13 - Brave"
			read browser
			if [[ $browser == 1 ]];
			then
				sudo snap install chromium
			elif [[ $browser == 2 ]];
			then
				sudo apt install -y epiphany
			elif [[ $browser == 3 ]];
			then
				sudo apt install -y falkon
			elif [[ $browser == 4 ]];
			then
				sudo apt install -y midori
			elif [[ $browser == 5 ]];
			then
				cd /tmp; wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb; sudo dpkg -i *.deb; sudo apt install -f
			elif [[ $browser == 6 ]];
			then
				wget https://linux.palemoon.org/datastore/release/palemoon-29.2.0.linux-x86_64-gtk3.tar.xz; tar -xvf palemoon-29.2.0.linux-x86_64-gtk3.tar.xz; sudo ln -s ~/palemoon/palemoon /usr/bin/palemoon
				wget https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/palemoon.desktop; sudo mv palemoon.desktop /usr/share/applications/palemoon.desktop
			elif [[ $browser == 7 ]];
			then
				wget https://downloads.vivaldi.com/stable/vivaldi-stable_3.7.2218.58-1_amd64.deb; sudo apt install -f
			elif [[ $browser == 8 ]];
			then
				sudo snap install opera
			elif [[ $browser == 9 ]];
			then
				sudo apt install -y lynx
			elif [[ $browser == 10 ]];
			then
				sudo apt install -y dillo
			elif [[ $browser == 11 ]];
			then
				wget https://cdn.waterfox.net/releases/linux64/installer/waterfox-G3.2.1.en-US.linux-x86_64.tar.bz2; waterfox-G3.2.1.en-US.linux-x86_64.tar.bz2; sudo ln -s ~/waterfox/waterfox /usr/bin/waterfox; sudo mv waterfox /opt && sudo ln -s /opt/waterfox/waterfox /usr/bin/waterfox
				wget https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/waterfox.desktop; sudo mv waterfox.desktop /usr/share/applications/waterfox.desktop
			elif [[ $browser == 12 ]];
			then
				wget https://us.basilisk-browser.org/release/basilisk-latest.linux64.tar.xz; tar -xvf basilisk-latest.linux64.tar.xz; sudo mv basilisk /opt && sudo ln -s /opt/basilisk/basilisk /usr/bin/basilisk
				wget https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/basilisk.desktop; sudo mv basilisk.desktop /usr/share/applications/basilisk.desktop
			elif [[ $browser == 13 ]];
			then
				sudo snap install brave
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
			echo "8 - celluloid"
			echo "9 - kodi"
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
				sudo apt install -y mplayer
			elif [[ $player == 7 ]];
			then
				sudo apt install -y smplayer smplayer-themes
			elif [[ $player == 8 ]];
			then
				sudo apt install -y celluloid
			elif [[ $player == 9 ]];
			then
				sudo apt install -y kodi
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
				sudo apt install -y transmission-gtk
			elif [[ $client == 2 ]];
			then
				sudo apt install -y deluge
			elif [[ $client == 3 ]];
			then
				sudo apt install -y qbittorrent
			fi
			;;
			8)
			echo "1 - Guake"
			echo "2 - Terminator"
			echo "3 - both"
			if [[ $package == 1 ]];
			then
				sudo apt install -y Guake
			elif [[ $package == 2 ]];
			then
				sudo apt install -y Terminator
			elif [[ $package == 3 ]];
			then
				sudo apt install -y Guake Terminator
			fi
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
			sudo apt install -y bleachbit deborphan
			;;
			13)
			sudo apt install -y ttf-mscorefonts-installer
			;;
			14)
			echo "THEMES"
			sudo add-apt-repository ppa:noobslab/icons; sudo add-apt-repository ppa:noobslab/icons
			sudo add-apt-repository ppa:noobslab/icons; sudo add-apt-repository ppa:papirus/papirus
			sudo add-apt-repository ppa:moka/daily; sudo apt-get update
			sudo apt install -y mate-themes faenza-icon-theme obsidian-1-icons dalisha-icons shadow-icon-theme moka-icon-theme papirus-icon-theme
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
				sudo apt install -y supertuxkart
			elif [[ $package == 2 ]];
			then
				sudo apt install -y gnome-mahjongg
			elif [[ $package == 3 ]];
			then
				sudo apt install -y aisleriot
			elif [[ $package == 4 ]];
			then
				sudo apt install -y ace-of-penguins
			elif [[ $package == 5 ]];
			then
				sudo apt install -y gnome-sudoku
			elif [[ $package == 6 ]];
			then
				sudo apt install -y gnome-mines
			elif [[ $package == 7 ]];
			then
				sudo apt install -y chromium-bsu
			elif [[ $package == 8 ]];
			then
				sudo apt install -y supertux
			elif [[ $package == 9 ]];
			then
				sudo apt install -y supertuxkart gnome-mahjongg aisleriot ace-of-penguins gnome-sudoku gnome-mines chromium-bsu supertux steam
			else
				echo "You have entered an invalid number, please come back later and try again."
			fi
			;;
			16)
			echo "Virtualbox"
			sudo apt update && sudo apt install -y virtualbox
			;;
			17)
			echo "Wine and Play On Linux"
			sudo apt update && sudo apt install -y wine playonlinux
			;;
			18)
			echo "Dropbox"
			sudo apt install -y dropbox
			;;
			19)
			echo "Alrighty then!"
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
		echo "screenfetch" | sudo tee -a ~/.bashrc
	break
	done

	#Microcode installer
	cpu=$(lscpu | grep "Vendor ID:" | awk '{print $3}')
	for c in $cpu;
	do
		if [[ $cpu == GenuineIntel ]];
		then
			apt list | grep intel-microcode || sudo apt install -y intel-microcode && sudo update-initramfs -u 
		elif [[ $cpu == AuthenticAMD ]];
		then
			apt list | grep amd64-microcode || sudo apt install -y amd64-microcode && sudo update-initramfs -u
		fi
	done

	#This tries to install codecs
	echo "This will install codecs. These depend upon your environment. Would you like me to continue?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		for env in $DESKTOP_SESSION;
		do
			if [[ $DESKTOP_SESSION == unity ]];
			then
				sudo apt install -y ubuntu-restricted-extras libdvdnav4 libdvd-pkg gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly 
			elif [[ $DESKTOP_SESSION == xfce ]];
			then
				sudo apt install -y xubuntu-restricted-extras libdvdnav4 libdvd-pkg gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly 
				sudo apt install -y xfce4-goodies
			elif [[ $DESKTOP_SESSION == /usr/share/xsessions/plasma ]];
			then
				sudo apt install -y kubuntu-restricted-extras libdvdnav4 libdvd-pkg gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly 
			elif [[ $DESKTOP_SESSION == lxde ]];
			then
				sudo apt install -y lubuntu-restricted-extras libdvdnav4 libdvd-pkg gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly 
			elif [[ $DESKTOP_SESSION == mate ]];
			then
				sudo apt install -y ubuntu-restricted-extras libdvdnav4 libdvd-pkg gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly 
			elif [[ $DESKTOP_SESSION == gnome ]];
			then
				sudo apt install -y ubuntu-restricted-extras libdvdnav4 libdvd-pkg gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly
				sudo apt install -y gnome-session gnome-tweak-tool gnome-shell-extensions 
			elif [[ $DESKTOP_SESSION == enlightenment ]];
			then
				sudo apt install -y ubuntu-restricted-extras libdvdnav4 libdvd-pkg gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly 
			elif [[ $DESKTOP_SESSION == Budgie ]];
			then
				sudo apt install -y ubuntu-restricted-extras libdvdnav4 libdvd-pkg gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly 
			elif [[ $DESKTOP_SESSION == cinnamon ]];
			then
				sudo apt install -y ubuntu-restricted-extras libdvdnav4 libdvd-pkg gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly 
			elif [[ $DESKTOP_SESSION == ubuntu ]];
			then
				sudo apt install -y ubuntu-restricted-extras libdvdnav4 libdvd-pkg gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly 
				sudo apt install -y gnome-tweak-tool dconf-editor chrome-gnome-shell gnome-shell-extensions
			else
				echo "You're running some other window manager I haven't tested yet."
				sleep 1
			fi
		done

		echo "If you're running Mint, it's a good idea to install the mint meta package"
		distribution=$(cat /etc/issue | awk '{print $2}')
		if [[ $distribution == Mint ]];
		then
			sudo apt install -y mint-meta-codecs
		fi
	break
	done

	clear
	Greeting
}

RAMBack(){
	#This clears the cached RAM
	sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches"

	clear
	Greeting
}

Uninstall(){
	echo "Are there any other applications you wish to remove(Y/n)"
	read answer
	while [ $answer ==  Y ];
	do
		echo "Please enter the name of the software you wish to remove"
  		read software
		sudo apt remove --purge -yy $software
	break
	done

	clear
	Greeting
}

AccountSettings(){
	echo "This is experimental(untested). Use at  your own risk."
	echo "What would you like to do today?"
	echo "1 - Create user account(s)"
	echo "2 - Delete user account(s)"
	echo "3 - Lock pesky user accounts"
	echo "4 - Look for empty password users on the system"
	echo "5 - See a list of accounts and groups on the system"
	echo "6 - skip this menu"
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

CheckNetwork(){
	for c in computer;
	do
		ping -c4 google.com
		if [[ $? -eq 0 ]];
		then
			echo "Connection successful"
		else
			read -p "Check hardware cable status and press enter..."
			interface=$(ip -o -4 route show to default | awk '{print $5}')
			sudo dhclient -v -r && sudo dhclient; sudo /etc/init.d/network-manager stop
			sudo /etc/init.d/network-manager disable; sudo /etc/init.d/network-manager enable
			sudo /etc/init.d/network-manager start; sudo ip link set $interface up
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

cleanup(){
	#This flushes apt cache
	sudo apt autoremove -y; sudo apt autoclean -y; sudo apt clean -y

	#This removes older config files left by no longer installed applications
	OLDCONF=$(dpkg -l | grep '^rc' | awk '{print $2}')
	sudo apt remove --purge $OLDCONF

	#This optionally removes old kernels
	cat <<EOF
	It is encouraged that you leave at least one older kernel on your system
EOF
	OldKernels=$(dpkg -l | tail -n +6 | grep -E 'linux-image-[0-9]+' | grep -Fv $(uname -r))
	echo $OldKernels
	sleep 1
	echo "Would you like to remove older kernels to save disk space?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		echo "Please enter the Image you wish to remove"
		read Image
		sudo apt-get remove --purge $Image
	break
	done

	#cleans old kernel crash logs
	sudo find /var -type f -name "core" -print -exec rm {} \;

	#This removes the apt list
	sudo rm -r /var/lib/apt/lists/*

	#This clears the cache and thumbnails and other junk
	sudo rm -r .cache/*
	sudo rm -r .thumbnails/*
	sudo rm -r ~/.local/share/Trash/files/*
	sudo rm -r ~/.nv/*
	sudo rm -r ~/.npm/*
	sudo rm -r ~/.w3m/*
	sudo rm ~/.esd_auth
	sudo rm ~/.local/share/recently-used.xbel
	#sudo rm -r /tmp/*
	history -c && rm ~/.bash_history

	#This removes old configurations for software
	sudo rm -r ~/.config/*-old

	#This clears the cached RAM
	sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches; swapoff -a && swapon -a"

	#This could clean your Video folder and Picture folder based on a set time
	TRASHCAN=~/.local/share/Trash/files/
	find ~/Downloads/* -mtime +30 -exec mv {} $TRASHCAN \;
	find ~/Video/* -mtime +30 -exec mv {} $TRASHCAN \;
	find ~/Pictures/* -mtime +30 -exec mv {} $TRASHCAN \;

	#search and remove broken symlinks
	find -xtype l -delete

	#clean some unneccessary files leftover by applications at home directory
	find $HOME -type f -name "*~" -print -exec rm {} \;

	#This trims the journal logs
	sudo journalctl --vacuum-size=25M

	#This uninstalls unwanted apps
	Uninstall

	#We can reboot if you want
	echo "Reboot?(Y/n)"
	read answer
	if [[ $answer == Y ]];
	then
		Restart
	else
		clear
		Greeting
	fi
}

BrowserRepair(){
	cat <<EOF
	This can fix a lot of the usual issues with a few of the bigger browsers.
	These can include performance hitting issues. If your browser needs a tuneup,
	it is probably best to do it in the browser itself, but when you just want something
	fast, this can do it for you. More browsers and options are coming.
EOF
	browser1="$(find /usr/bin/firefox)"
	browser2="$(find /usr/bin/vivaldi*)"
	browser3="$(find /usr/bin/palemoon)"
	browser4="$(find /usr/bin/google-chrome*)"
	browser5="$(find /usr/bin/chromium-browser)"
	browser6="$(find /usr/bin/opera)"
	browser7="$(find /usr/bin/waterfox)"
	browser8="$(find /usr/bin/falkon)"
	browser9="$(find /usr/bin/epiphany)"
	browser10="$(find /usr/bin/midori)"

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

	sleep 1

	echo "choose the browser you wish to reset"
	echo "1 - Firefox"
	echo "2 - Vivaldi"
	echo "3 - Pale Moon"
	echo "4 - Chrome"
	echo "5 - Chromium"
	echo "6 - Opera"
	echo "7 - Waterfox"
	echo "8 - Midori"
	echo "9 - Falkon"
	echo "10 - Epiphany"
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
		sudo cp -r ~/.config/chromium ~/.config/chromium-old; sudo rm -rf ~/.config/chromium/*
		echo "Your browser has now been reset"
		sleep 1
		;;
		6)
		sudo cp -r ~/.config/opera ~/.config/opera-old; sudo rm -rf ~/.config/opera/*
		echo "Your browser has now been reset"
		sleep 1
		;;
		7)
		sudo cp -r ~/.waterfox ~/.waterfox-old; sudo rm -rf ~/.waterfox/*
		echo "Your browser has now been reset"
		sleep 1
		;;
		8)
		sudo cp -r ~/.config/midori ~/.config/midori-old; sudo rm -rf ~/.config/midori/*
		echo "Your browser has now been reset"
		sleep 1
		;;
		9)
		sudo cp -r ~/.config/falkon ~/.config/falkon-old; sudo rm -rf ~/.config/falkon/*
		echo "Your browser has now been reset"
		sleep 1
		;;
		10)
		sudo cp -r ~/.config/epiphany ~/.config/epiphany-old; sudo rm -rf ~/.config/epiphany/*
		echo "Your browser has now been reset"
		sleep 1
		;;
		*)
		echo "No browser for that entry exists, please try again"
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
		sudo update-alternatives --set x-www-browser /usr/bin/$browser
	break
	done

	clear
	Greeting
}

SystemMaintenance(){
	CheckNetwork

	#This updates your system
	sudo dpkg --configure -a; sudo apt install -f; sudo apt update; sudo apt upgrade -yy; sudo snap refresh

	#This restarts systemd daemon. This can be useful for different reasons.
	sudo systemctl daemon-reload #For systemd releases

	#It is recommended that your firewall is enabled
	sudo systemctl restart ufw; sudo ufw enable; sudo ufw reload

	#This runs update db for index cache and cleans the manual database
	sudo updatedb; sudo mandb

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

ServiceManager(){
	cat <<EOF
	This is usually better off left undone, only disable services you know
	you will not need or miss. I can not be held responsible if you brick
	your system. Handle with caution. Also, may only take effect once you
	reboot your machine. Services can be turned back on with a good backup
	and possibly by chrooting into the device via live cd and reversing the
	process by running this again and reenabling the service.
EOF
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
				echo "Optionally we can create an override which will keep this setting. Would you like to retain this setting after reboot?(Y/n)"
				read answer
				while [ $answer == Y ];
				do
					echo manual | sudo tee /etc/init/$service.override
				break
				done
				;;
				3)
				echo "################################################################" >> services.txt
				echo "SERVICE MANAGER" >> services.txt
				echo "################################################################" >> services.txt
				service --status-all >> services.txt
				systemctl list-unit-files --type=service >> services.txt
				echo "################################################################" >> services.txt
				echo "END OF FILE" >> services.txt
				echo "################################################################" >> services.txt
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
				sudo systemctl enable $service; sudo systemctl start $service
				;;
				2)
				echo "Enter the name of the service you wish to disable"
				read service
				sudo systemctl stop $service; sudo systemctl disable $service
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

Restart(){
	sudo sync; sudo systemctl reboot
}

Backup(){
	echo "What would you like to do?"
	echo "1 - Backup home folder and user files"
	echo "2 - Backup entire drive and root partition(skipping unnecessary items)"

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
			sudo mount $device /mnt; sudo rsync -aAXv --delete --exclude={"*.cache/*","*.thumbnails/*","*/.local/share/Trash/*"} /home/$USER /mnt/$host-backups; sudo sync
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
			sudo mount $device /mnt; sudo rsync -aAXv --delete --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} / /mnt/$host-backups; sudo sync
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
	cat <<EOF
	This tries to restore the home folder and nothing else, if you want to
	restore the entire system,  you will have to do that in a live environment.
	This can, however, help in circumstances where you have family photos and
	school work stored in the home directory. This also assumes that your home
	directory is on the drive in question. This can also restore browser settings
	including unwanted toolbars so be warned.
EOF
	Mountpoint=$(lsblk | awk '{print $7}' | grep /run/media/$USER/*)
	if [[ $Mountpoint != /run/media/$USER/* ]];
	then
		read -p "Please insert the backup drive and hit enter..."
		echo $(lsblk | awk '{print $1}')
		sleep 1
		echo "Please select the device from the list"
		read device
		sudo mount $device /mnt; sudo rsync -aAXv --delete /mnt/$host-$date-backups/* /home/$USER; sudo sync; Restart
	elif [[ $Mountpoint == /run/media/$USER/* ]];
	then
		read -p "Found a block device at designated coordinates... If this is the preferred device, try umounting it, leaving it plugged in, and then running this again. Press enter to continue..."
	fi

	clear
	Greeting
}

Greeting(){
	echo "Enter a selection from the following list"
	echo "1 - Setup your system"
	echo "2 - Add/Remove user accounts"
	echo "3 - Install software"
	echo "4 - Uninstall software"
	echo "5 - Setup a hosts file"
	echo "6 - Backup your system"
	echo "7 - Restore your system"
	echo "8 - Manage system services"
	echo "9 - Collect System Information"
	echo "10 - Screenfix"
	echo "11 - Make Swap"
	echo "12 - Help"
	echo "13 - Cleanup"
	echo "14 - RAMBack"
	echo "15 - System Maintenance"
	echo "16 - Browser Repair"
	echo "17 - Update"
	echo "18 - Restart"
	echo "19 - Reset the desktop"
	echo "20 - exit"
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
		Screenfix
		;;
		11)
		MakeSwap
		;;
		12)
		HELP
		;;
		13)
		cleanup
		;;
		14)
		RAMBack
		;;
		15)
		SystemMaintenance
		;;
		16)
		BrowserRepair
		;;
		17)
		Update
		;;
		18)
		Restart
		;;
		19)
		Reset
		;;
		20)
		echo $'\n'$"Thank you for using Ubuntu-Toolbox... Goodbye!"
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

cat <<EOF
##########################################################################
Hello! Thank you for using Ubuntu Toolbox. Within this script is a multi-
tude of potential solutions for every day tasks such as maintenance,
all the way to setting up a new system. This script is meant for new
users, but anyone can read, change and use this script to their liking.
This script is to be placed under the GPLv3 and is to be redistributable,
however, if you are distributing, I would appreciate it if you gave the
credit back to the original author. I should also add that I have a few
blog articles which may or may not be of benefit for newbies on occasion.
The link will be placed here. In the blog I write about typical scenarios
that I face on a day to day basis as well as add commentary and my
opinions about software and technology. You may copy and paste the
following link into your browser: https://techiegeek123.blogspot.com/
Again, Thank you!
##########################################################################
EOF
Greeting
