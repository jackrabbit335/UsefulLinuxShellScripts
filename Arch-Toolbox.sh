#!/bin/bash

Setup(){
	#Sets default editor to nano in bashrc
	echo "export EDITOR=nano" | sudo tee -a /etc/bash.bashrc

	#This backs up very important system files for your sanity
	sudo cp /etc/systemd/journald.conf /etc/systemd/journald.conf.bak
	sudo cp /etc/systemd/system.conf /etc/systemd/system.conf.bak
	sudo cp /etc/systemd/logind.conf /etc/systemd/logind.conf.bak
	sudo cp /etc/default/grub /etc/default/grub.bak
	sudo cp /etc/systemd/coredump.conf /etc/systemd/coredump.conf.bak
	sudo cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.bak
	sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
	sudo cp /etc/login.defs /etc/login.defs.bak
	sudo cp /etc/sudoers /etc/sudoers.bak
	sudo cp /etc/profile /etc/profile.bak
	sudo cp /etc/pacman.conf /etc/pacman.conf.bak
	sudo cp /etc/bash.bashrc /etc/bash.bashrc.bak
	sudo cp /etc/environment /etc/environment.bak
	sudo cp /etc/host.conf /etc/host.conf.bak
	sudo cp /etc/passwd /etc/passwd.bak
	sudo cp /etc/shadow /etc/shadow.bak
	sudo cp /etc/fstab /etc/fstab.bak
	sudo cp -r /boot /boot-old
	cp .bashrc .bashrc.bak
	cp .xsession-errors .xsession-errors.bak

	#This fixes screen Resolution
	echo "Would you like to choose a more accurate resolution?(Y/n)"
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

	#This sets up your locale
	echo "Would you like to set a locale?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		echo "Enter your preferred locale"
		read locale
		sudo localectl set-locale LANG=$locale; locale -a
	break
	done

	#This restricts coredumps and tweaks system
	sudo sed -i -e '/#Storage=external/c\Storage=none ' /etc/systemd/coredump.conf
	sudo sed -i -e '/#PermitRootLogin/c\PermitRootLogin no ' /etc/ssh/sshd_config
	sudo touch /etc/sysctl.d/50-dmesg-restrict.conf
	sudo touch /etc/sysctl.d/50-kptr-restrict.conf
	sudo touch /etc/sysctl.d/99-sysctl.conf
	echo "kernel.dmesg_restrict = 1" | sudo tee -a /etc/sysctl.d/50-dmesg-restrict.conf
	echo "kernel.kptr_restrict = 1" | sudo tee -a /etc/sysctl.d/50-kptr-restrict.conf
	echo "vm.swappiness = 10" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
	echo "vm.vfs_cache_pressure = 50" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
	sudo sysctl --system
	sudo sysctl -p

	#WE can block ICMP requests from the kernel if you'd like
	echo "Block icmp ping requests?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		sudo touch /etc/syctl.d/60-network-hardening.conf
		echo "net.ipv4.icmp_echo_ignore_all = 1" | sudo tee -a /etc/sysctl.d/60-network-hardening.conf; sudo sysctl -p
	break
	done

	#This disables ipv6
	echo "Sometimes ipv6 can cause network issues. Would you like to disable it?(Y/n)"
	read answer
	if [[ $answer == Y ]];
	then
		sudo sed -i -e 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="ipv6.disable=1"/g' /etc/default/grub; sudo grub-mkconfig -o /boot/grub/grub.cfg
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
		sudo sed -i -e '/#SystemMaxUse=/c\SystemMaxUse=50M ' /etc/systemd/journald.conf
		break
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
		echo "#Alias to edit fstab" >> ~/.bashrc
		echo 'alias fstabed="sudo nano /etc/fstab"' >> ~/.bashrc
		echo "#Alias to edit grub" >> ~/.bashrc
		echo 'alias grubed="sudo nano /etc/default/grub"' >> ~/.bashrc
		echo "#Alias to update grub" >> ~/.bashrc
		echo 'alias grubup="sudo grub-mkconfig -o /boot/grub/grub.cfg"' >> ~/.bashrc
		echo "#Alias to update the system" >> ~/.bashrc
		echo 'alias update="yay -Syu --noconfirm"' >> ~/.bashrc
		echo "#Alias to clean pacman cache" >> ~/.bashrc
		echo 'alias clean="sudo pacman -Scc"' >> ~/.bashrc
		echo "#Alias to clean all but the latest three versions of packages in cache" >> ~/.bashrc
		echo 'alias cut="sudo paccache -rk3"' >> ~/.bashrc
		echo "#Alias to remove uninstalled packages from the cache" >> ~/.bashrc
		echo 'alias purge="sudo paccache -ruk0"' >> ~/.bashrc
		echo "#Alias to remove orphaned packages" >> ~/.bashrc
		echo 'alias orphan="sudo pacman -Rsn $(pacman -Qqdt)"' >> ~/.bashrc
		echo "#Alias to Free Up RAM" >> ~/.bashrc
		echo 'alias boost="sudo sysctl -w vm.drop_caches=3"' >> ~/.bashrc
		echo "#Alias to trim journal size" >> ~/.bashrc
		echo 'alias vacuum="sudo journalctl --vacuum-size=25M"' >> ~/.bashrc
		echo "#Alias to trim ssd" >> ~/.bashrc
		echo 'alias trim="sudo fstrim -v --all"' >> ~/.bashrc
		echo "#Alias to show memory info" >> ~/.bashrc
		echo 'alias meminfo="cat /proc/meminfo"' >> ~/.bashrc
		echo "#Alias to show cpu info" >> ~/.bashrc
		echo 'alias cpu="lscpu"' >> ~/.bashrc
		echo "#Alias to monitor sensor information" >> ~/.bashrc
		echo 'alias temp="watch sensors"' >> ~/.bashrc
		echo "#Alias to monitor live memory usage" >> ~/.bashrc
		echo 'alias mem="watch free -lh"' >> ~/.bashrc
		echo "#Alias to show swaps info" >> ~/.bashrc
		echo 'alias swaps="cat /proc/swaps"' >> ~/.bashrc

		#Determines your os in order to apply correct alias
		distribution=$(cat /etc/issue | awk '{print $1}')
		if [[ $distribution == Manjaro ]];
		then
			echo "#Alias to update the mirrors" >> ~/.bashrc; echo 'alias mirrors="sudo pacman-mirrors -f 5 && sudo pacman -Syy"' >> ~/.bashrc
		elif [[ $distribution == Arch ]];
		then
			echo "#Alias to update the mirrors" >> ~/.bashrc; echo 'alias mirrors="sudo reflector --verbose -l 50 -f 20 --save /etc/pacman.d/mirrorlist; sudo pacman -Syy"' >> ~/.bashrc
		fi
	fi

	CheckNetwork

	#This tries to update and rate mirrors if it fails it refreshes the keys
	distribution=$(cat /etc/issue | awk '{print $1}')
	for n in $distribution;
	do
		if [[ $distribution == Manjaro ]];
		then
			sudo pacman-mirrors --fasttrack 5 && sudo pacman -Syyu --noconfirm
			if [[ $? -eq 0 ]];
			then
				echo "Update successful"
			else
				sudo rm -r /var/lib/pacman/sync/*; sudo rm /var/lib/pacman/db.lck; sudo rm -r /etc/pacman.d/gnupg; sudo pacman -Sy --noconfirm gnupg archlinux-keyring manjaro-keyring; sudo pacman-key --init; sudo pacman-key --populate archlinux manjaro; sudo pacman-key --refresh-keys; sudo pacman -Scc; sudo pacman -Syyu --noconfirm
			fi
		elif [[ $distribution == KaOS ]];
		then
			echo "Ranking mirrors is no longer required for this distribution."
			sudo pacman -Syyu --noconfirm
			if [[ $? -eq 0 ]];
			then
				echo "update successful"
			fi
		else
			pacman -Q | grep reflector || sudo pacman -S reflector; sudo reflector --verbose -l 50 -f 20 --save /etc/pacman.d/mirrorlist; sudo pacman -Syyu --noconfirm
			if [[ $? -eq 0 ]];
			then
				echo "update successful"
			else
				sudo rm -r /var/lib/pacman/sync/*; sudo rm /var/lib/pacman/db.lck; sudo rm -r /etc/pacman.d/gnupg; sudo pacman -Sy --noconfirm gnupg archlinux-keyring; sudo pacman-key --init; sudo pacman-key --populate archlinux; sudo pacman-key --refresh-keys; sudo pacman -Scc; sudo pacman -Syyu --noconfirm
			fi
		fi
	done

	#This pins the kernel in Arch Linux
	sudo sed -i 's/#IgnorePkg   =/IgnorePkg   =linux linux-headers linux-lts linux-lts-headers/g' /etc/pacman.conf

	#This sets up your Bluetooth
	echo "Would you like to enable bluetooth?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		pacman -Q | grep bluez || sudo pacman -S --noconfirm bluez bluez-utils; sudo modprobe btusb; sudo systemctl enable bluetooth.service; sudo systemctl start bluetooth.service; break
	done

	#This starts your firewall
	pacman -Q | grep ufw || sudo pacman -S --noconfirm ufw; sudo systemctl enable ufw; sudo ufw default allow outgoing; sudo ufw default deny incoming; sudo ufw enable
	echo "Would you like to deny ssh and telnet for security?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		sudo ufw deny ssh; sudo ufw deny telnet; sudo ufw reload; break
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

	sudo pacman -Syyu --noconfirm

	clear
	Greeting
}

Systeminfo(){
	pacman -Q | grep lsb-release || sudo pacman -S --noconfirm lsb-release
	pacman -Q | grep wmctrl || sudo pacman -S --noconfirm wmctrl
	pacman -Q | grep hwinfo || sudo pacman -S --noconfirm hwinfo
	host=$(hostname)
	drive=$(df -P / | awk '{print $1}' | grep "/dev/")
	distribution=$(cat /etc/issue | awk '{print $1}')
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
	wmctrl -m | grep "Name:" | awk '{print $2}' >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "DISPLAY MANAGER" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	grep '/usr/s\?bin' /etc/systemd/system/display-manager.service >> $host-sysinfo.txt
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
	echo "UPDATE CHANNEL" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	cat /etc/pacman-mirrors.conf | grep "Branch" >> $host-sysinfo.txt
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
	echo "PACMAN REPOSITORY INFORMATION" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	cat /etc/pacman.conf >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "INSTALLED PACKAGE COUNT" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	pacman -Q | wc -l >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "INSTALLED PACKAGE LIST" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	pacman -Q >> $host-sysinfo.txt
	echo "" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	echo "PACKAGE MANAGER HISTORY" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	cat /var/log/pacman.log >> $host-sysinfo.txt
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
	echo "SIGH" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	hwinfo --short >> $host-sysinfo.txt
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
	CheckNetwork

	echo "Would you like to install software?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		echo "1 - Utility suite/Monitoring Software"
		echo "2 - DESKTOP SPECIFIC"
		echo "3 - Package Manager"
		echo "4 - Terminals"
		echo "5 - Alternate shells"
		echo "6 - IDE or text/code editor"
		echo "7 - Cleaning software"
		echo "8 - prelauncher"
		echo "9 - Download managers"
		echo "10 - Dropbox"
		echo "11 - Torrent clients"
		echo "12 - AUR Helpers"
		echo "13 - Web browser from a list"
		echo "14 - Media/home theater software"
		echo "15 - Messenger Apps"
		echo "16 - Virtual machine client"
		echo "17 - Wine and play on linux"
		echo "18 - quvcview"
		echo "19 - Manipulate config files"
		echo "20 - GAMES!"
		echo "21 - Video editing/encoding"
		echo "22 - Plank"
		echo "23 - Backup"
		echo "24 - THEMES!"
		echo "25 - Desktops"
		echo "26 - Neofetch"
		echo "27 - Office software"
		echo "28 - Proprietary Fonts"
		echo "29 - Security checkers/scanners"
		echo "30 - Stellarium constellation and space observation"
		echo "31 - Microcode"
		echo "32 - Exit out of this menu"
		read software;
		case $software in
			1)
			echo "This installs a series of utility software"
			sudo pacman -S --needed --noconfirm dnsutils traceroute hdparm gparted smartmontools expac file-roller curl
			sudo pacman -S --needed --noconfirm hddtemp htop iotop atop nmap xsensors ncdu fwupd base-devel xdg-user-dirs
			sudo pacman -S --needed --noconfirm gnome-disk-utility hardinfo lshw net-tools pastebinit p7zip unrar mesa-demos
			sudo pacman -S --needed --noconfirm pacman-contrib grsync tlp powertop youtube-dl keepassxc unzip zip gstreamer aspell-en libmythes mythes-en languagetool
			wget https://aur.archlinux.org/cgit/aur.git/snapshot/inxi.tar.gz; gunzip inxi.tar.gz; tar -xvf inxi.tar; cd inxi && makepkg -si
			wget https://aur.archlinux.org/cgit/aur.git/snapshot/ulauncher.tar.gz; gunzip ulauncher.tar.gz; tar -xvf ulauncher.tar; cd ulauncher && makepkg -si
			;;
			2)
			echo "This installs Desktop Specific utilities"
			for env in $DESKTOP_SESSION;
			do
				if [[ $DESKTOP_SESSION == xfce ]];
				then
					sudo pacman -S --needed --noconfirm xfce4-goodies
				elif [[ $DESKTOP_SESSION == gnome ]];
				then
					sudo pacman -S --needed --noconfirm gnome-tweaks
				elif [[ $DESKTOP_SESSION == mate ]];
				then
					sudo pacman -S --needed --noconfirm mate-tweaks
				fi
			done
			;;
			3)
			echo "This installs an option in Package Managers"
			echo "1 - Pamac"
			echo "2 - Octopi"
			echo "3 - Packagekit"
			read package
			if [[ $package == 1 ]];
			then
				wget https://aur.archlinux.org/cgit/aur.git/snapshot/pamac-all.tar.gz; gunzip pamac-all.tar.gz; tar -xvf pamac-all.tar; cd pamac-all && makepkg -si
			elif [[ $package == 2 ]];
			then
				wget https://aur.archlinux.org/cgit/aur.git/snapshot/octopi.tar.gz; gunzip octopi.tar.gz; tar -xvf octopi.tar; cd octopi && makepkg -si
			elif [[ $package == 3 ]];
			then
				sudo pacman -S gnome-packagekit --noconfirm
			else
				echo "You've entered an invalid number"
				InstallAndConquer
			fi
			;;
			4)
			echo "This installs your choice of terminals If you already have one, don't worry"
			echo "1 - terminator"
			echo "2 - termite"
			echo "3 - lxterminal"
			echo "4 - xterm"
			read package
			if [[ $package == 1 ]];
			then
				sudo pacman -S --noconfirm terminator
			elif [[ $package == 2 ]];
			then
				sudo pacman -S --noconfirm termite
			elif [[ $package == lxterminal ]];
			then
				sudo pacman -S --noconfirm lxterminal
			elif [[ $package == 4 ]];
			then
				sudo pacman -S --noconfirm xterm
			else
				echo "You've entered an invalid number"
				InstallAndConquer
			fi
			;;
			5)
			echo "This installs alternate shells You will have to configure these yourself"
			echo "1 - zsh"
			echo "2 - fish"
			read selection
			if [[ $selection == 1 ]];
			then
				sudo pacman -S --noconfirm zsh zsh-completions
			elif [[ $selection == 2 ]];
			then
				sudo pacman -S --needed --noconfirm fish pkgfile inetutils
				#echo "exec fish" ~/.bashrc
			fi
			;;
			6)
			echo "This installs a light weight editor(text/code editor/IDE)"
			echo "1 - geany"
			echo "2 - sublime text editor"
			echo "3 - bluefish"
			echo "4 - atom"
			echo "5 - gedit"
			echo "6 - kate"
			echo "7 - leafpad"
			echo "8 - notepadqq"
			echo "9 - Visual Studio"
			read package
			if [[ $package == 1 ]];
			then
				sudo pacman -S --noconfirm geany
			elif [[ $package == 2 ]];
			then
				wget https://download.sublimetext.com/sublime_text_3_build_3211_x64.tar.bz2; tar -xvf sublime_text_3_build_3211_x64.tar.bz2; cd sublime_text_3; makepkg -si
			elif [[ $package == 3 ]];
			then
				sudo pacman -S --noconfirm bluefish
			elif [[ $package == 4 ]];
			then
				sudo pacman -S --noconfirm atom
			elif [[ $package == 5 ]];
			then
				sudo pacman -S --noconfirm gedit
			elif [[ $package == 6 ]];
			then
				sudo pacman -S --noconfirm kate
			elif [[ $editor == 7 ]];
			then
				sudo pacman -S --noconfirm leafpad
			elif [[ $package == 8 ]];
			then
				sudo pacman -S --noconfirm notepadqq
			elif [[ $editor == 9 ]];
			then
				sudo pacman -S --noconfirm code
			else
				echo "You've entered an invalid number"
				InstallAndConquer
			fi
			;;
			7)
			echo "This installs cleaning software for Arch Linux Systems"
			echo "1 - bleachbit and rmlint"
			echo "2 - kde sweeper"
			echo "3 - stacer"
			read package
			if [[ $package == 1 ]];
			then
				sudo pacman -S --noconfirm bleachbit rmlint
			elif [[ $package == 2 ]];
			then
				sudo pacman -S sweeper
			elif [[ $packaage == 3 ]];
			then
				wget https://aur.archlinux.org/cgit/aur.git/snapshot/stacer.tar.gz; gunzip stacer.tar.gz; tar -xvf stacer.tar; cd stacer && makepkg -si
			else
				echo "You've entered an invalid number"
				InstallAndConquer
			fi
			;;
			8)
			echo "This installs a prelauncher"
			sudo pacman -S --noconfirm preload
			;;
			9)
			echo "This installs a choice in download managers"
			echo "1 - wget"
			echo "2 - uget"
			echo "3 - aria2"
			read software
			if [[ $software == 1 ]];
			then
				sudo pacman -S --noconfirm wget
			elif [[ $software == 2 ]];
			then
				sudo pacman -S --noconfirm uget
			elif [[ $software == 3 ]];
			then
				sudo pacman -S --noconfirm aria2
			else
				echo "You have entered an invalid number"
				InstallAndConquer
			fi
			;;
			10)
			echo "This installs Dropbox"
			wget https://aur.archlinux.org/cgit/aur.git/snapshot/dropbox.tar.gz; gunzip dropbox.tar.gz; tar -xvf dropbox.tar; cd dropbox && makepkg -si
			;;
			11)
			echo "This installs your choice of torrent clients"
			echo "1 - transmission-gtk"
			echo "2 - deluge"
			echo "3 - qbittorrent"
			read client
			if [[ $client == 1 ]];
			then
				sudo pacman -S --noconfirm transmission-gtk
			elif [[ $client == 2 ]];
			then
				sudo pacman -S --noconfirm deluge
			elif [[ $client == 3 ]];
			then
				sudo pacman -S --noconfirm qbittorrent
			else
				echo "You have entered an invalid number"
				InstallAndConquer
			fi
			;;
			12)
			echo "1 - pacaur"
			echo "2 - trizen"
			echo "3 - yay"
			echo "4 - paru"
			read helper
			if [[ $helper == 1 ]];
			then
				wget https://aur.archlinux.org/cgit/aur.git/snapshot/pacaur.tar.gz; gunzip pacaur.tar.gz; tar -xvf pacaur.tar; cd pacaur && makepkg -si
			elif [[ $helper == 2 ]];
			then
				wget https://aur.archlinux.org/cgit/aur.git/snapshot/trizen.tar.gz; gunzip trizen.tar.gz; tar -xvf trizen.tar; cd trizen && makepkg -si
			elif [[ $helper == 3 ]];
			then
				wget https://aur.archlinux.org/cgit/aur.git/snapshot/yay.tar.gz; gunzip yay.tar.gz; tar-xvf yay.tar; cd yay && makepkg -si
			elif [[ $helper == 4 ]];
			then
				sudo pacman -S --needed --noconfirm base-devel; git clone https://aur.archlinux.org/paru.git; cd paru && makepkg -si
			else
				echo "You have entered an invalid number"
				InstallAndConquer
			fi
			;;
			13)
			echo "This installs your choice in browsers"
			echo "1 - Chromium"
			echo "2 - Epiphany"
			echo "3 - Falkon"
			echo "4 - Midori"
			echo "5 - Opera"
			echo "6 - Vivaldi"
			echo "7 - Vivaldi-Snapshot"
			echo "8 - Pale Moon"
			echo "9 - Seamonkey"
			echo "10 - Dillo"
			echo "11 - Lynx"
			echo "12 - Google-chrome"
			echo "13 - Waterfox"
			echo "14 - Basilisk"
			echo "15 - Slimjet"
			echo "16 - Brave"
			echo "17 - Qutebrowser"
			echo "18 - Otter-Browser"
			echo "19 - Iridium"
			echo "20 - Ungoogled-Chromium"
			read browser
			if [[ $browser == 1 ]];
			then
				sudo pacman -S --noconfirm chromium
			elif [[ $browser == 2 ]];
			then
				sudo pacman -S --noconfirm epiphany
			elif [[ $browser == 3 ]];
			then
				sudo pacman -S --noconfirm falkon
			elif [[ $browser == 4 ]];
			then
				sudo pacman -S midori
			elif [[ $browser == 5 ]];
			then
				sudo pacman -S --noconfirm opera opera-ffmpeg-codecs
			elif [[ $browser == 6 ]];
			then
				sudo pacman -S vivaldi
			elif [[ $browser == 7 ]];
			then
				wget https://aur.archlinux.org/cgit/aur.git/snapshot/vivaldi-snapshot.tar.gz; gunzip vivaldi-snapshot.tar.gz; tar -xvf vivaldi-snapshot.tar; cd vivaldi-snapshot && makepkg -si
			elif [[ $browser == 8 ]];
			then
				wget https://linux.palemoon.org/datastore/release/palemoon-29.2.1.linux-x86_64-gtk3.tar.xz; tar -xvf palemoon-29.2.1.linux-x86_64-gtk3.tar.xz; sudo ln -s ~/palemoon/palemoon /usr/bin/palemoon
				wget https://raw.githubusercontent.com/jackrabbit335/BrowserAndDesktop/main/palemoon.desktop; sudo mv palemoon.desktop /usr/share/applications/palemoon.desktop
			elif [[ $browser == 9 ]];
			then
				sudo pacman -S --noconfirm seamonkey
			elif [[ $browser == 10 ]];
			then
				sudo pacman -S --noconfirm dillo
			elif [[ $browser == 11 ]];
			then
				sudo pacman -S --noconfirm lynx
			elif [[ $browser == 12 ]];
			then
				wget https://aur.archlinux.org/cgit/aur.git/snapshot/google-chrome.tar.gz; gunzip google-chrome.tar.gz; tar -xvf google-chrome.tar; cd google-chrome && makepkg -si
			elif [[ $browser == 13 ]];
			then
				wget https://cdn.waterfox.net/releases/linux64/installer/waterfox-G3.2.2.en-US.linux-x86_64.tar.bz2; gunzip waterfox-G3.2.2.en-US.linux-x86_64.tar.bz2; tar -xvf waterfox-G3.1.0.en-US.linux-x86_64.tar; sudo ln -s ~/waterfox/waterfox /usr/bin/waterfox
				wget https://raw.githubusercontent.com/jackrabbit335/BrowserAndDesktop/main/waterfox.desktop; sudo mv waterfox.desktop /usr/share/applications/waterfox.desktop
			elif [[ $browser == 14 ]];
			then
				wget https://us.basilisk-browser.org/release/basilisk-latest.linux64.tar.xz; tar -xvf basilisk-latest.linux64.tar.xz; sudo mv basilisk /opt; sudo touch /usr/share/applications/basilisk.desktop; sudo ln -s /opt/basilisk/basilisk /usr/bin/basilisk
				wget https://raw.githubusercontent.com/jackrabbit335/BrowserAndDesktop/main/basilisk.desktop; sudo mv basilisk.desktop /usr/share/applications/basilisk.desktop
			elif [[ $browser == 15 ]];
			then
				wget https://aur.archlinux.org/cgit/aur.git/snapshot/slimjet.tar.gz; gunzip slimjet.tar.gz; tar -xvf slimjet.tar; cd slimjet && makepkg -si
			elif [[ $browser == 16 ]];
			then
				wget https://aur.archlinux.org/cgit/aur.git/snapshot/brave-bin.tar.gz; gunzip brave-bin.tar.gz; tar -xvf brave-bin.tar; cd brave-bin; makepkg -si
			elif [[ $browser == 17 ]];
			then
				sudo pacman -S --noconfirm qutebrowser python-adblock
			elif [[ $browser == 18 ]];
			then
				sudo pacman -S --noconfirm otter-browser
			elif [[ $browser == 19 ]];
			then
				wget https://aur.archlinux.org/cgit/aur.git/snapshot/iridium-rpm.tar.gz; gunzip iridium-rpm.tar.gz; tar -xvf iridium-rpm.tar; cd iridium-rpm && makepkg -si
			elif [[ $browser == 20 ]];
			then
				wget https://aur.archlinux.org/cgit/aur.git/snapshot/ungoogled-chromium.tar.gz; gunzip ungoogled-chromium.tar.gz; tar -xvf ungoogled-chromium.tar; cd ungoogled-chromium && makepkg -si
			else
				echo "You have entered an invalid number"
				InstallAndConquer
			fi
			;;
			14)
			echo "This installs a choice in media players"
			echo "1 - xplayer"
			echo "2 - parole"
			echo "3 - kodi"
			echo "4 - quodlibet"
			echo "5 - Spotify"
			echo "6 - rhythmbox"
			echo "7 - mpv"
			echo "8 - smplayer"
			echo "9 - VLC"
			echo "10 - totem"
			echo "11 - pragha"
			echo "12 - clementine"
			echo "13 - gnome-mplayer"
			echo "14 - celluloid"
			echo "15 - lollypop"
			echo "16 - strawberry"
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
				sudo pacman -S --noconfirm quodlibet
			elif [[ $player == 5 ]];
			then
				wget https://aur.archlinux.org/cgit/aur.git/snapshot/spotify.tar.gz; gunzip spotify.tar.gz; tar -xvf spotify.tar; cd spotify && makepkg -si
			elif [[ $player == 6 ]];
			then
				sudo pacman -S --noconfirm rhythmbox
			elif [[ $player == 7 ]];
			then
				sudo pacman -S --noconfirm mpv
			elif [[ $player == 8 ]];
			then
				sudo pacman -S --noconfirm smplayer smplayer-skins
			elif [[ $player == 9 ]];
			then
				sudo pacman -S --noconfirm vlc
			elif [[ $player == 10 ]];
			then
				sudo pacman -s --noconfirm totem
			elif [[ $player == 11 ]];
			then
				sudo pacman -S --noconfirm pragha
			elif [[ $player == 12 ]];
			then
				sudo pacman -S --noconfirm clementine
			elif [[ $player == 13 ]];
			then
				sudo pacman -S --noconfirm gnome-mplayer
			elif [[ $player == 14 ]];
			then
				sudo pacman -S celluloid
			elif [[ $player == 15 ]];
			then
				sudo pacman -S --noconfirm lollypop
			elif [[ $player == 16 ]];
			then
				sudo pacman -S --noconfirm strawberry
			else
				echo "You have entered an invalid number"
				InstallAndConquer
			fi
			;;
			15)
			echo "This installs a Messenger or chat client"
			echo "1 - Pidgin"
			echo "2 - Hexchat"
			echo "3 - Skype"
			echo "4 - Signal"
			echo "5 - Telegram"
			echo "6 - Discord-Canary"
			read client
			if [[ $client == 1 ]];
			then
				sudo pacman -S pidgin
			elif [[ $client == 2 ]];
			then
				sudo pacman -S hexchat
			elif [[ $client == 3 ]];
			then
				wget https://aur.archlinux.org/cgit/aur.git/snapshot/skypeforlinux-stable-bin.tar.gz; gunzip skypeforlinux-stable-bin.tar.gz; tar -xvf skypeforlinux-stable-bin.tar
			elif [[ $client == 4 ]];
			then
				wget https://aur.archlinux.org/cgit/aur.git/snapshot/signal-desktop-beta.tar.gz; gunzip signal-desktop-beta.tar.gz; tar -xvf signal-desktop-beta.tar; cd signal-desktop-beta && makepkg -si
			elif [[ $client == 5 ]];
			then
				sudo pacman -S telegram-desktop
			elif [[ $client == 6 ]];
			then
				wget https://aur.archlinux.org/cgit/aur.git/snapshot/discord-canary.tar.gz; gunzip discord-canary.tar.gz; tar -xvf discord-canary.tar; cd discord-canary && makepkg -si
			fi
			;;
			16)
			echo "This installs a virtualbox client"
			sudo pacman -S --noconfirm virtualbox virtualbox-guest-iso
			;;
			17)
			echo "This installs Wine or Windows emulation software"
			echo "1 - Wine"
			echo "2 - playonlinux"
			echo "3 - Both"
			read software;
			case $software in
				1)
				sudo pacman -S --noconfirm wine ;;
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
			18)
			echo "This installs a webcam application for laptops"
			sudo pacman -S --noconfirm guvcview
			;;
			19)
			echo "etc-update can help you manage pacnew files and other configuration files after system updates."
			sudo pacman -S --needed base-devel; wget https://aur.archlinux.org/cgit/aur.git/snapshot/etc-update.tar.gz; gunzip etc-update.tar.gz && tar -xvf etc-update.tar; cd etc-update && makepkg -si; wget https://aur.archlinux.org/cgit/aur.git/snapshot/downgrade.tar.gz; gunzip downgrade.tar.gz; tar -xvf downgrade.tar; cd downgrade && makepkg -si
			;;
			20)
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
				echo "You have entered an invalid number"
				InstallAndConquer
			fi
			;;
			21)
			echo "This installs video/audio decoding/reencoding software"
			sudo pacman -S --noconfirm kdenlive audacity
			echo "Would you also like obs-studio?(Y/n)"
			read answer
			while [ $answer == Y ];
			do
				sudo pacman -S --noconfirm obs-studio
				break
			done
			;;
			22)
			echo "This installs a dock application"
			sudo pacman -S --noconfirm plank
			;;
			23)
			echo "This installs your backup software"
			echo "1 - deja-dup"
			echo "2 - timeshift"
			read package
			if [[ $package == 1 ]];
			then
				sudo pacman -S --noconfirm deja-dup
			elif [[ $package == 2 ]];
			then
				sudo pacman -S --noconfirm timeshift
			else
				echo "You have entered an invalid number"
				InstallAndConquer
			fi
			;;
			24)
			echo "This installs a few common themes"
			sudo pacman -S --noconfirm adapta-gtk-theme arc-icon-theme evopop-icon-theme arc-gtk-theme papirus-icon-theme materia-gtk-theme paper-icon-theme
			wget https://aur.archlinux.org/cgit/aur.git/snapshot/numix-gtk-theme.tar.gz; gunzip numix-gtk-theme.tar.gz; tar -xvf numix-gtk-theme.tar; cd numix-gtk-theme && makepkg -si
			wget https://aur.archlinux.org/cgit/aur.git/snapshot/numix-icon-theme-git.tar.gz; gunzip numix-icon-theme-git.tar.gz; tar -xvf numix-icon-theme-git.tar; cd numix-icon-theme-git && makepkg -si
			wget https://aur.archlinux.org/cgit/aur.git/snapshot/sardi-icons.tar.gz; gunzip sardi-icons.tar.gz; tar -xvf sardi-icons.tar; cd sardi-icons &&  makepkg -si
			;;
			25)
			echo "1 - Openbox"
			echo "2 - XFCE"
			echo "3 - Gnome"
			echo "4 - Mate"
			echo "5 - i3"
			read option;
			case $option in
			1) sudo pacman -S --noconfirm --needed openbox obconf obmenu nitrogen tint2 lxappearance picom;;
			2) sudo pacman -S --noconfirm --needed xfce4 xfwm4-themes xfce4-goodies;;
			3) sudo pacman -S --noconfirm --needed gnome;;
			4) sudo pacman -S --noconfirm --needed mate;;
			5) sudo pacman -s --noconfirm --needed i3;;
			*) echo "You've selected an invalid number please try again"
			esac
			;;
			26)
			echo "This installs neofetch"
			sudo pacman -S --noconfirm neofetch; echo "neofetch" ~/.bashrc
			;;
			27)
			echo "This installs office software"
			echo "1 - Libreoffice"
			echo "2 - Libreoffice-fresh"
			echo "3 - Abiword/Gnumeric"
			echo "4 - Onlyoffice"
			read software
			if [[ $software == 1 ]];
			then
				sudo pacman -S --noconfirm libreoffice
			elif [[ $software == 2 ]];
			then
				pacman -Q | grep libreoffice || sudo pacman -S --noconfirm libreoffice-fresh
			elif [[ $software == 3 ]];
			then
				sudo pacman -S --noconfirm abiword gnumeric
			elif [[ $software == 4 ]];
			then
				wget https://aur.archlinux.org/cgit/aur.git/snapshot/onlyoffice-bin.tar.gz; gunzip onlyoffice-bin.tar.gz; tar -xvf onlyoffice-bin.tar
			else
				echo "You've entered an invalid number"
				InstallAndConquer
			fi
			;;
			28)
			wget https://aur.archlinux.org/cgit/aur.git/snapshot/ttf-ms-fonts.tar.gz; wget https://aur.archlinux.org/cgit/aur.git/snapshot/ttf-mac-fonts.tar.gzgunzip ttf-ms-fonts.tar.gz; gunzip ttf-mac-fonts.tar.gz; tar -xvf ttf-ms-fonts.tar; tar -xvf ttf-mac-fonts.tar; cd ttf-ms-fonts; makepkg -si; pushd ttf-mac-fonts; makepkg -si; cd
			;;
			29)
			echo "This installs possible security software and virus checker if you wish"
			echo "KaOS doesn't have these by default(has tomoyo) and clam av can be installed as flatpak"
			echo "1 - Rkhunter"
			echo "2 - Clamav"
			echo "3 - Lynis"
			echo "4 - Arch Audit"
			echo "5 - All"
			read software;
			case $software in
				1)
				sudo pacman -S --noconfirm rkhunter ;;
				2)
				sudo pacman -S --noconfirm clamav ;;
				3)
				sudo pacman -S --noconfirm lynis;;
				4)
				sudo pacman -S --noconfirm arch-audit;;
				5)
				sudo pacman -S --noconfirm rkhunter clamav lynis arch-audit ;;
				*)
				echo "You have entered an invalid number"
				InstallAndConquer;;
			esac
			;;
			30)
			echo "This installs stellarium incase you are a night sky observer"
			sudo pacman -S --noconfirm stellarium
			;;
			31)
			echo "This installs Microcode based on your architecture"
			cpu=$(lscpu | grep "Vendor ID:" | awk '{print $3}')
			for c in $cpu;
			do
				if [[ $cpu == GenuineIntel ]];
				then
					sudo pacman -Q | grep intel-ucode || sudo pacman -S --noconfirm intel-ucode
				else
					sudo pacman -Q | grep amd-ucode || sudo pacman -S --noconfirm amd-ucode
				fi
			done
			;;
			32)
			echo "Ok, well, I'm here if you change your mind"
			break
			;;
		esac
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
EF LINUX MADE SIMPLE
Many others...

##########################################################################
WELCOME AND RAMBLE WITH LICENSING
##########################################################################
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
https://kaosx.us/docs/
https://averagelinuxuser.com/
https://endeavouros.com/wiki/

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
DRIVERS
##########################################################################
Drivers are important for acting as an intermediary between the kernel and
hardware. Drivers are firmwaare that tell peripherals what to do; Modules
that install directly to the Kernel. Drivers help with graphics, keyboard,
mouse, Sata, etc. If you need full hardware support, you might consider
installing the nonfree drivers, especially for video and big tasks like
video encoding. If you are just using your computer for simple tasks like
email, browsing the web, writing text documents and so on, the free and
open source drivers should work for you in most cases. Nvidia is a diff-
erent animal and much of what you need can not be done properly in Nouveau
at this time. The most current drivers are in the repository, but if your
card is older and needs more specific drivers or Legacy support which is no
longer supported, you will likely have to go to the driver vendors site
and search for it, thus installing it manually. I am addinig a Driver manager
function to help with installing the current kernel modules or open source
versions. It is not finished yet, but will soon be added to Arch-Toolbox.

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
ALTERNATE SHELLS
##########################################################################
When installing an alternate shell it is important to note that other
shells might not work with the current Arch-Toolbox script. Nevertheless
If you would like to use these alternate shell programs I have added two
such applications in the InstallandConquer function. To enable the fish
shell you will have to manually edit this script and uncomment the
line which adds an exec command to the end of bashrc file. It is also
important to note that manual configuration is required at this time.
Some sites of import: https://wiki.archlinux.org/index.php/Fish
https://wiki.archlinux.org/index.php/zsh

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
Linux now that can help you accomplish this. The software I am referring
to is Meld. Still, it is good practice when modifying or setting up your
Linux system to keep a back up copy of many of these and so I have added
it in to this script automatically on Setup function. I would also suggest
backing up the display manager configuration which can be found in etc under
the display manager folder your system is using.

##########################################################################
PACMAN/OCTOPI AND PACKAGE MANAGERS IN GENERAL
##########################################################################
There are two big points that set Arch Linux and its package management
apart and those are the support for AUR or Arch User Repository and
control over individual mirrors. Pamac or Pacman has many ways to
interact with the AUR and to control the mirrors or servers that it
uses to download updated software. Most are third party tools, however,
recently, pamac received an update which better supported the AUR in
its own backend. The further improves the manager overall and limits
the necessity to using third party tools to octopi. Another big point,
the mirrors control is usually handled by reflector or another script
held within pacman-contrib dependent on the distribution. If you don not
have pacman-contrib package or another load of scripts on your device,
it is easy in Manjaro to run sudo pacman -Sy --noconfirm pacman-contrib.
Octopi is, in my opinion, a better and more straight forward package
manager which utilizes pamac at its core, however, it does not handle
the AUR very well graphically, for this, using a tool such as Trizen
becomes a necessity. Having access to the AUR grants the user access to
all kinds of software previously unavailable. Arch can run more Software
that can also be ran on Windows than any other Linux system without using
Wine. For all this, it is as simple as running a few short commands which
are covered in this script. To learn them, just read the script and study
it. It is a simpler method than Apt and Debian package management
as these are so separated with several commands each.

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
services. Manjaro specifically has their own tool for managing Kernels
and drivers. This tool helps immensely and is what I utilize in this
scripts kernel manager. This tool will not be in other Arch-based
distributions. Read the documentation for your distribution before
attempting to install or uninstall other kernels. The Arch wiki is a
valuable resource.

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

Uninstall(){
	echo "Would you like to remove any unwanted applications?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		echo "Please enter the name of any software you wish to remove"
		read software
		sudo pacman -Rsn --noconfirm $software
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

cleanup(){
	#This will clean the cache
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
	sudo rm -r /var/tmp/*

	#This removes old configurations for software
	sudo rm -r ~/.config/*-old

	#This could clean your Video folder and Picture folder based on a set time
	TRASHCAN=~/.local/share/Trash/files/
	find ~/Downloads/* -mtime +30 -exec mv {} $TRASHCAN \;
	find ~/Video/* -mtime +30 -exec mv {} $TRASHCAN \;
	find ~/Pictures/* -mtime +30 -exec mv {} $TRASHCAN \;

	#Sometimes it's good to check for and remove broken symlinks
	find -xtype l -delete

	#clean some unneccessary files leftover by applications in home directory
	find $HOME -type f -name "*~" -print -exec rm {} \;

	#cleans old kernel crash logs
	sudo find /var -type f -name "core" -print -exec rm {} \;

	#This helps get rid of old archived log entries
	sudo journalctl --vacuum-size=25M

	#This will remove orphan packages from pacman
	sudo pacman -Rsn --noconfirm $(pacman -Qqdt)

	#Optional This will remove the pacman cached applications and older versions
	#sudo pacman -Scc

	#This removes unwanted apps
	Uninstall
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
	browser5="$(find /usr/bin/chromium)"
	browser6="$(find /usr/bin/opera)"
	browser7="$(find /usr/bin/waterfox)"
	browser8="$(find /usr/bin/falkon)"
	browser9="$(find /usr/bin/epiphany)"
	browser10="$(find /usr/bin/midori)"
	browser11="$(find /usr/bin/basilisk)"
	browser12="$(find /usr/bin/brave)"
	browser13="$(find /usr/bin/iridium)"
	browser14="$(find /usr/bin/otter-browser)"
	browser15="$(find /usr/bin/ungoogled-chromium)"

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
	echo $browser13
	echo $browser14
	echo $browser15

	sleep 1

	echo "choose the browser you wish to reset"
	echo "1 - Firefox"
	echo "2 - Vivaldi"
	echo "3 - Pale Moon"
	echo "4 - Chrome"
	echo "5 - Chromium"
	echo "6 - Opera"
	echo "7 - Waterfox"
	echo "8 - Falkon"
	echo "9 - Epiphany"
	echo "10 - Midori"
	echo "11 - Basilisk"
	echo "12 - Brave"
	echo "13 - Iridium"
	echo "14 - Otter-browser"
	echo "15 - Ungoogled-chromium"
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
		sudo cp -r ~/.config/falkon ~/.config/falkon-old; sudo rm -rf ~/.config/falkon/*
		echo "Your browser has now been reset"
		sleep 1
		;;
		9)
		sudo cp -r ~/.config/epiphany ~/.config/epiphany-old; sudo rm -rf ~/.config/epiphany/*
		echo "Your browser has now been reset"
		sleep 1
		;;
		10)
		sudo cp -r ~/.config/midori ~/.config/midori-old; sudo rm -rf ~/.config/midori/*
		echo "Your browser has now been reset"
		sleep 1
		;;
		11)
		sudo cp -r ~/'.moonchild productions'/'basilisk' ~/'.moonchild productions'/'basilisk'-old; sudo rm -rf ~/'.moonchild productions'/'basilisk'/*
		echo "Your browser has now been reset"
		sleep 1
		;;
		12)
		sudo cp -r ~/.config/BraveSoftware ~/.config/BraveSoftware-old; sudo rm -rf ~/.config/BraveSoftware/*
		echo "Your browser has now been reset"
		sleep 1
		;;
		13)
		sudo cp -r ~/.config/iridium ~/.config/iridium-old; sudo rm -rf ~/.config/iridium/*
		echo "Your browser has now been reset"
		sleep 1
		;;
		14)
		sudo cp -r ~/.config/otter-browser ~/.config/otter-browser-old; sudo rm -rf ~/.config/otter-browser/*
		echo "Your browser has been reset"
		sleep 1
		;;
		15)
		sudo cp -r ~/.config/ungoogled-chromium ~/.config/ungoogled-chromium-old; sudo rm -rf ~/.config/ungoogled-chromium/*
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

SystemMaintenance(){
	CheckNetwork

	#This attempts to rank mirrors and update your system
	distribution=$(cat /etc/issue | awk '{print $1}')
	if [[ $distribution == Manjaro ]];
	then
		sudo pacman-mirrors --fasttrack 5 && sudo pacman -Syyu --noconfirm
	elif [[ $distribution == KaOS ]];
	then
		sudo pacman -Syyu --noconfirm
	else
		sudo pacman -Q | grep reflector || sudo pacman -S --noconfirm reflector; sudo reflector --verbose -l 50 -f 20 --save /etc/pacman.d/mirrorlist; sudo pacman -Syyu --noconfirm
	fi

	#This refreshes systemd in case of corrupt or changed unit configurations
	sudo systemctl daemon-reload

	#This will ensure the firewall is enabled
	sudo systemctl restart ufw; sudo ufw enable

	#This refreshes index cache
	sudo updatedb; sudo mandb

	#Checks for pacnew files and other extra configuration file updates
	pacman -Q | grep etc-update; sudo etc-update
	if [[ $? -gt 0 ]];
	then
		wget https://aur.archlinux.org/cgit/aur.git/snapshot/etc-update.tar.gz; gunzip etc-update.tar.gz; tar -xvf etc-update.tar; cd etc-update && makepkg -si; sudo etc-update
	fi

	#update the grub
	sudo grub-mkconfig -o /boot/grub/grub.cfg

	#This runs a disk checkup and attempts to fix filesystem
	sudo touch /forcefsck

	#Handles trim or defragmentation based on drive rotation
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
		mv ~/.config/xfce4 ~/.config/xfce4-bak
	elif [[ $DESKTOP_SESSION == mate ]];
	then
		echo "############################################################################"
		echo "This resets MATE"
		echo "############################################################################"
		dconf dump /org/mate/ > mate-desktop-backup; dconf reset -f /
	else
		echo "You're running a desktop/Window Manager that we do not yet support... Come back later."
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

DriverManager(){
	echo "COMING SOON!!!!"
	sleep 1

	clear
	Greeting
}

MakeSwap(){
	#This attempts to create a swap file in the event the system doesn't have swap
	grep -q "swap" /etc/fstab
	if [ $? -eq 0 ];
	then
		sudo cp /etc/fstab /etc/fstab.old; sudo fallocate --length 2G /swapfile; sudo chmod 600 /swapfile; sudo mkswap /swapfile; sudo swapon /swapfile; echo "/swapfile swap swap sw 0 0" | sudo tee -a /etc/fstab
	else
		echo "Swap was already there so there is nothing to do"
	fi
	cat /proc/swaps >> swaplog.txt; free -h >> swaplog.txt

	Restart
}

Restart(){
	sudo sync && sudo systemctl reboot
}

KernelManager(){
	cat <<EOF
	Kernels are an essential part of the operating system. Failure to use precaution
	could inadvertently screw up system functions. The kernel is the main engine behind
	the scenes making everything operate within normal parameters, changing kernel settings
	or installing/uninstalling a bad updated version could give undesirable results.
EOF
	pacman -Q linux linux-lts linux-hardened linux-zen
	echo "What would you like to do?"
	echo "1 - Install lts"
	echo "2 - Install current"
	echo "3 - Install hardened"
	echo "4 - Install zen"
	echo "5 - Remove lts"
	echo "6 - Remove current"
	echo "7 - Remove hardened"
	echo "8 - Remove zen"
	echo "9 - Get out of this menu"
	read operation;
	case $operation in
		1)
		sudo pacman -S linux-lts linux-lts-headers;;
		2)
		sudo pacman -S linux-current linux-current-headers;;
		3)
		sudo pacman -S linux-hardened linux-hardened-headers;;
		4)
		sudo pacman -S linux-zen linux-zen-headers;;
		5)
		sudo pacman -Rsn linux-lts linux-lts-headers;;
		6)
		sudo pacman -Rsn linux-current linux-current-headers;;
		7)
		sudo pacman -Rsn linux-hardened linux-hardened-headers;;
		8)
		sudo pacman -Rsn linux-zen linux-zen-headers;;
		9)
		echo "You've chosen not to mess with the kernel, a good idea in most cases";;
	esac

	clear
	Greeting
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
			read -p "Found a block device at designated coordinates...If this is the preferred drive, unmount it, leave it plugged in, and then run this again. Press enter to continue..."
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
		sudo mount $device /mnt; sudo rsync -aAXv --delete --exclude={"*.cache/*","*.thumbnails/*"."*/.local/share/Trash/*"}  /mnt/$host-$date-backups/* /home; sudo sync
		Restart
	elif [[ $Mountpoint == /run/media/$USER/* ]];
	then
		read -p "Found a block device at designated coordinates... If this is the preferred drive, try unmounting the device, leaving it plugged in, and running this again. Press enter to continue..."
	fi

	clear
	Greeting
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
	echo "9 - Install or uninstall kernels"
	echo "10 - Install and manage drivers"
	echo "11 - Collect system information"
	echo "12 - Screen Resolution Fix"
	echo "13 - Create Swap File"
	echo "14 - Cleanup"
	echo "15 - RAMBack"
	echo "16 - System Maintenance"
	echo "17 - Browser Repair"
	echo "18 - Update"
	echo "19 - Help"
	echo "20 - Restart"
	echo "21 - Reset the desktop"
	echo "22 - exit"
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
		KernelManager
		;;
		10)
		DriverManager
		;;
		11)
		Systeminfo
		;;
		12)
		ScreenFix
		;;
		13)
		MakeSwap
		;;
		14)
		cleanup
		;;
		15)
		RAMBack
		;;
		16)
		SystemMaintenance
		;;
		17)
		BrowserRepair
		;;
		18)
		Update
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
		echo $'\n'$"Thank you for using Arch-Toolbox... Goodbye!"
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
