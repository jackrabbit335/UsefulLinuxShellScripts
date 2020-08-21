#!/bin/bash

Setup(){
	#Sets default editor to nano in bashrc
	echo "export EDITOR=nano" | sudo tee -a /etc/bash.bashrc

	#This sets up your system time.
	echo "Would you like to set ntp to true? (Y/n)"
	read answer
	while [ $answer == Y ];
	do
		echo "Enter your preferred timezone"
		read timezone; sudo timedatectl set-ntp true; sudo timedatectl set-timezone $timezone
	break
	done

	#This starts your firewall
	pacman -Q | grep ufw || sudo pacman -S --noconfirm ufw; sudo systemctl enable ufw; sudo ufw enable
	echo "Would you like to deny ssh and telnet for security?(Y/n)"
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
	echo "kernel.dmesg_restrict = 1" | sudo tee -a /etc/sysctl.d/50-dmesg-restrict.conf
	echo "kernel.kptr_restrict = 1" | sudo tee -a /etc/sysctl.d/50-kptr-restrict.conf
	echo "vm.swappiness = 10" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
	sudo sysctl --system
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
		echo "net.ipv4.icmp_echo_ignore_all = 1" | sudo tee -a /etc/sysctl.d/60-network-hardening.conf; sudo sysctl -p
	break
	done

	#This disables ipv6
	echo "Sometimes ipv6 can cause network issues. Would you like to disable it?(Y/n)"
	read answer
	if [[ $answer == Y ]];
	then
		sudo cp /etc/default/grub /etc/default/grub.bak
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

	#This removes that stupid gnome-keyring unlock error you get with chrome
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
		echo 'alias fstabed="sudo nano /etc/fstab"' >> ~/.bashrc
		echo "#Alias to edit grub" >> ~/.bashrc
		echo 'alias grubed="sudo nano /etc/default/grub"' >> ~/.bashrc
		echo "#Alias to update grub" >> ~/.bashrc
		echo 'alias grubup="sudo grub-mkconfig -o /boot/grub/grub.cfg"' >> ~/.bashrc
		echo "#Alias to update the system" >> ~/.bashrc
		echo 'alias update="sudo pacman -Syu --noconfirm"' >> ~/.bashrc
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

		#Determines your os in order to apply correct alias
		distribution=$(cat /etc/issue | awk '{print $1}')
		if [[ $distribution == Manjaro ]];
		then
			echo "#Alias to update the mirrors" >> ~/.bashrc
			echo 'alias mirrors="sudo pacman-mirrors -f 5 && sudo pacman -Syy"' >> ~/.bashrc
		elif [[ $distribution == Antergos ]];
		then
			echo "#Alias to update the mirrors" >> ~/.bashrc
			echo 'alias mirrors="sudo reflector-antergos --verbose -l 50 -f 20 --save /etc/pacman.d/antergos-mirrorlist; sudo reflector --verbose -l 50 -f 20 --save /etc/pacman.d/mirrorlist; sudo pacman -Syy"' >> ~/.bashrc
		fi

	fi

	checkNetwork

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
				sudo rm -r /var/lib/pacman/sync/*; sudo rm /var/lib/pacman/db.lck; sudo rm -r /etc/pacman.d/gnupg
				sudo pacman -Sy --noconfirm gnupg archlinux-keyring manjaro-keyring; sudo pacman-key --init
				sudo pacman-key --populate archlinux manjaro; sudo pacman-key --refresh-keys; sudo pacman -Scc
				sudo pacman -Syyu --noconfirm
			fi
		elif [[ $distribution == Arch ]];
		then
			sudo pacman -Sy --noconfirm reflector
			sudo reflector --verbose -l 50 -f 20 --save /etc/pacman.d/mirrorlist; sudo pacman -Syyu --noconfirm
			if [[ $? -eq 0 ]];
			then
				echo "update successful"
			else
				sudo rm -r /var/lib/pacman/sync/*; sudo rm /var/lib/pacman/db.lck; sudo rm -r /etc/pacman.d/gnupg
				sudo pacman -Sy --noconfirm gnupg archlinux-keyring; sudo pacman-key --init
				sudo pacman-key --populate archlinux; sudo pacman-key --refresh-keys; sudo pacman -Scc
				sudo pacman -Syyu --noconfirm
			fi
		fi
	done

#This fixes gufw not opening in kde plasma desktop
cat <<_EOF_
This will attempt to determine if your desktop is kde and resolve the kde gufw not opening issue.
This is only a plasma issue as far as I know.
_EOF_
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
	checkNetwork

	sudo pacman -Syyu --noconfirm

	clear
	Greeting

}

Systeminfo(){
	pacman -Q | grep lsb-release || sudo pacman -S --noconfirm lsb-release
	pacman -Q | grep wmctrl || sudo pacman -S --noconfirm wmctrl
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
	echo "NETWORK STATS" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	ss -tulpn >> $host-sysinfo.txt
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
	echo "INSTALLED PACKAGES" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	sudo pacman -Q >> $host-sysinfo.txt
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
	echo "DISK READ SPEED"
	echo "############################################################################" >> $host-sysinfo.txt
	sudo hdparm -tT /dev/sda >> $host-sysinfo.txt
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
	echo "MORE LOGS" >> $host-sysinfo.txt
	echo "############################################################################" >> $host-sysinfo.txt
	journalctl >> $host-sysinfo.txt
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

InstallAndConquer(){
	checkNetwork

	echo "Would you like to install software?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		echo "1 - Utility suite/Monitoring Software"
		echo "2 - Terminals"
		echo "3 - IDE or text/code editor"
		echo "4 - Cleaning software"
		echo "5 - prelauncher"
		echo "6 - Download managers"
		echo "7 - Torrent clients"
		echo "8 - AUR Helpers"
		echo "9 - Web browser from a list"
		echo "10 - Media/home theater software"
		echo "11 - Virtual machine client"
		echo "12 - Wine and play on linux"
		echo "13 - quvcview"
		echo "14 - Manipulate config files and switch between versions of software"
		echo "15 - GAMES!!!!!!!!!"
		echo "16 - Video editing/encoding"
		echo "17 - Plank"
		echo "18 - Backup"
		echo "19 - THEMES!!!!!!!!"
		echo "20 - screenfetch"
		echo "21 - office software"
		echo "22 - Proprietary Fonts"
		echo "23 - Security checkers/scanners"
		echo "24 - Stellarium constellation and space observation"
		echo "25 - exit out of this menu"

	read software;

	case $software in
		1)
		echo "This installs a series of utility software"
		sudo pacman -S --needed --noconfirm dnsutils traceroute hdparm gparted smartmontools
		sudo pacman -S --needed --noconfirm hddtemp htop iotop atop ntop nmap xsensors ncdu
		sudo pacman -S --needed --noconfirm gnome-disk-utility hardinfo lshw net-tools pastebinit
		sudo pacman -S --needed --noconfirm pacman-contrib yaourt grsync tlp powertop
	;;
		2)
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
		fi
	;;
		3)
		echo "This installs a light weight editor(text/code editor/IDE)"
		echo "1 - geany"
		echo "2 - sublime text editor"
		echo "3 - bluefish"
		echo "4 - atom"
		echo "5 - gedit"
		echo "6 - kate/kwrite"
		echo "7 - leafpad"
		read package
		if [[ $package == 1 ]];
		then
			sudo pacman -S --noconfirm geany
		elif [[ $package == 2 ]];
		then
			wget https://download.sublimetext.com/sublime_text_3_build_3211_x64.tar.bz2; tar -xvf sublime_text_3_build_3211_x64.tar.bz2
			cd sublime_text_3; makepkg -si
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
		elif [[ $package == 6 ]];
		then
			echo "1 - Kate"
			echo "2 - Kwrite"
			read editor
			if [[ $editor == 1 ]];
			then
				sudo pacman -S --noconfirm kate
			elif [[ $editor == 2 ]];
			then
				sudo pacman -S --noconfirm kwrite
			fi
		elif [[ $editor == 7 ]];
		then
			sudo pacman -S --noconfirm leafpad
		else
			echo "You've entered an invalid number"
		fi
	;;
		4)
		echo "This installs cleaning software for Arch Linux Systems"
		sudo pacman -S --noconfirm bleachbit rmlint
	;;
		5)
		echo "This installs a prelauncher"
		sudo pacman -S --noconfirm preload
	;;
		6)
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
		fi
	;;
		7)
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
		fi
	;;
		8)
cat <<_EOF_
It is important to note that while you can install many of the listed
applications through pamac or octopi, you will not be able to utilize the aur
for future updates of some of the software installed via tarballs without one of these...
You have been warned. These also might not work on EndeavourOS.
_EOF_
		echo "1 - pacaur"
		echo "2 - yaourt"
		echo "3 - trizen"
		echo "4 - yay"
		read helper
		if [[ $helper == 1 ]];
		then
			sudo pacman -S --noconfirm pacaur
		elif [[ $helper == 2 ]];
		then
			sudo pacman -S --noconfirm yaourt
		elif [[ $helper == 3 ]];
		then
			sudo pacman -S --noconfirm trizen
		elif [[ $helper == 4 ]];
		then
			sudo pacman -S --noconfirm yay
		else
			echo "You have entered an invalid number"
		fi
	;;
		9)
		echo "This installs your choice in browsers"
		echo "1 - Chromium"
		echo "2 - Epiphany"
		echo "3 - Falkon"
		echo "4 - Midori"
		echo "5 - Opera"
		echo "6 - Vivaldi"
		echo "7 - Pale Moon"
		echo "8 - Seamonkey"
		echo "9 - Dillo"
		echo "10 - Lynx"
		echo "11 - Google-chrome"
		echo "12 - Waterfox"
		echo "13 - Basilisk"
		echo "14 - Slimjet"
		echo "15 - Brave"
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
			cd /tmp
			wget https://aur.archlinux.org/cgit/aur.git/snapshot/vivaldi.tar.gz
			gunzip vivaldi.tar.gz; tar -xvf vivaldi.tar; cd vivaldi && makepkg -si
		elif [[ $browser == 7 ]];
		then
			wget linux.palemoon.org/datastore/release/palemoon-28.12.0.linux-x86_64.tar.xz; tar -xf palemoon-28.12.0.linux-x86_64.tar.xz; sudo ln -s ~/palemoon/palemoon /usr/bin/palemoon
			wget https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/palemoon.desktop; sudo mv palemoon.desktop /usr/share/applications/palemoon.desktop
		elif [[ $browser == 8 ]];
		then
			sudo pacman -S --noconfirm seamonkey
		elif [[ $browser == 9 ]];
		then
			sudo pacman -S --noconfirm dillo
		elif [[ $browser == 10 ]];
		then
			sudo pacman -S --noconfirm lynx
		elif [[ $browser == 11 ]];
		then
			cd /tmp
			wget https://aur.archlinux.org/cgit/aur.git/snapshot/google-chrome.tar.gz
			gunzip google-chrome.tar.gz; tar -xvf google-chrome.tar; cd google-chrome && makepkg -si
		elif [[ $browser == 12 ]];
		then
			wget https://storage-waterfox.netdna-ssl.com/releases/linux64/installer/waterfox-classic-2020.07.2.en-US.linux-x86_64.tar.bz2; tar -xvjf waterfox-classic-2020.07.2.en-US.linux-x86_64.tar.bz2
			sudo ln -s ~/waterfox-classic/waterfox /usr/bin/waterfox
			wget https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/waterfox.desktop && sudo mv waterfox.desktop /usr/share/applications/waterfox.desktop
		elif [[ $browser == 13 ]];
		then
			wget http://us.basilisk-browser.org/release/basilisk-latest.linux64.tar.xz; tar -xvf basilisk-latest.linux64.tar.xz
			sudo mv basilisk /opt; sudo touch /usr/share/applications/basilisk.desktop; sudo ln -s /opt/basilisk/basilisk /usr/bin/basilisk
			wget https://raw.githubusercontent.com/jackrabbit335/UsefulLinuxShellScripts/master/basilisk.desktop; sudo mv basilisk.desktop /usr/share/applications/basilisk.desktop
		elif [[ $browser == 14 ]];
		then
			cd /tmp
			wget https://aur.archlinux.org/cgit/aur.git/snapshot/slimjet.tar.gz
			gunzip slimjet.tar.gz; tar -xvf slimjet.tar; cd slimjet && makepkg -si
		elif [[ $browser == 15 ]];
		then
			wget https://aur.archlinux.org/cgit/aur.git/snapshot/brave-bin.tar.gz
			gunzip brave-bin.tar.gz; tar -xvf brave-bin.tar; cd brave-bin; makepkg -si; rm brave-bin.tar
		else
			echo "You have entered an invalid number"
		fi
	;;
		10)
		echo "This installs a choice in media players"
		echo "1 - xplayer"
		echo "2 - parole"
		echo "3 - kodi"
		echo "4 - Music"
		echo "5 - spotify"
		echo "6 - rhythmbox"
		echo "7 - mpv"
		echo "8 - smplayer"
		echo "9 - VLC"
		echo "10 - totem"
		echo "11 - pragha"
		echo "12 - clementine"
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
			cd /tmp
			wget https://aur.archlinux.org/cgit/aur.git/snapshot/spotify.tar.gz
			gunzip spotify.tar.gz; tar -xvf spotify.tar; cd spotify && makepkg -si
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
			distribution=$(cat /etc/issue | awk '{print $1}')
			if [[ $distribution == manjaro ]];
			then
				sudo pacman -Rs --noconfirm vlc && sudo pacman -S vlc-nightly clementine
			else
				sudo pacman -S --noconfirm vlc
			fi
		elif [[ $player == 10 ]];
		then
			sudo pacman -s --noconfirm totem
		elif [[ $player == 11 ]];
		then
			sudo pacman -S --noconfirm pragha
		elif [[ $player == 12 ]];
		then
			sudo pacman -S --noconfirm clementine
		else
			echo "You have entered an invalid number"
		fi
	;;
		11)
		echo "This installs a virtualbox client"
		sudo pacman -S --noconfirm virtualbox
	;;
		12)
		echo "This installs Wine or Windows emulation software"
		echo "1 - Wine"
		echo "2 - playonlinux"

		read software;

		case $software in
			1)
			sudo pacman -S --noconfirm wine ;;
			2)
			sudo pacman -S --noconfirm playonlinux ;;
			*)
			echo "You have entered an invalid number" ;;
		esac
	;;
		13)
		echo "This installs a webcam application for laptops"
		sudo pacman -S --noconfirm guvcview
	;;
		14)
		echo "etc-update can help you manage pacnew files and other configuration files after system updates."
		sleep 2
		sudo pacman -S --needed base-devel
		wget https://aur.archlinux.org/cgit/aur.git/snapshot/etc-update.tar.gz
		gunzip etc-update.tar.gz && tar -xvf etc-update.tar; cd etc-update && makepkg -si
		echo "Would you also like to install downgrade?(Y/n)"
		read answer
		while [ $answer ==  Y ];
		do
			sudo pacman -S --noconfirm downgrade
		break
		done
	;;
		15)
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
		fi

	;;
		16)
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
		17)
		echo "This installs a dock application"
		sudo pacman -S --noconfirm plank
	;;
		18)
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
		fi
	;;
		19)
		echo "This installs a few common themes"
		sudo pacman -S --noconfirm adapta-gtk-theme moka-icon-theme faba-icon-theme arc-icon-theme evopop-icon-theme arc-gtk-theme papirus-icon-theme materia-gtk-theme paper-icon-theme
	;;
		20)
		echo "This installs screenfetch"
		sudo pacman -S --noconfirm screenfetch
	;;
		21)
		echo "This installs office software"
		echo "1 - Libreoffice"
		echo "2 - Libreoffice-fresh"
		echo "3 - Abiword/Gnumeric"
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
		else
			echo "You've entered an invalid number"
		fi
	;;
		22)
		wget https://aur.archlinux.org/cgit/aur.git/snapshot/ttf-ms-fonts.tar.gz; wget https://aur.archlinux.org/cgit/aur.git/snapshot/ttf-mac-fonts.tar.gz
		gunzip ttf-ms-fonts.tar.gz; gunzip ttf-mac-fonts.tar.gz; tar -xvf ttf-ms-fonts.tar; tar -xvf ttf-mac-fonts.tar
		cd ttf-ms-fonts; makepkg -si; pushd ttf-mac-fonts; makepkg -si; cd
	;;
		23)
		echo "This installs possible security software and virus checker if you wish"
		echo "1 - rkhunter"
		echo "2 - clamav"
		echo "3 - both"

		read software;

		case $software in
			1)
			sudo pacman -S --noconfirm rkhunter ;;
			2)
			sudo pacman -S --noconfirm clamav ;;
			3)
			sudo pacman -S --noconfirm rkhunter clamav ;;
			*)
			echo "You have entered an invalid number" ;;
		esac
	;;
		24)
		echo "This installs stellarium incase you are a night sky observer"
		sudo pacman -S --noconfirm stellarium
	;;
		25)
		echo "Ok, well, I'm here if you change your mind"
		break
	;;
	esac
	done

	read -p "Press enter to continue..."

	#This installs xfce4-goodies package on xfce versions of Manjaro
	for env in $DESKTOP_SESSION;
	do
		if [[ $DESKTOP_SESSION == xfce ]];
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

	read -p "Press enter to continue..."

	#This installs intel or amd microcode assuming it isn't installed already
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

	clear
	Greeting
}

Help(){
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
Joshua Strobl of the Solus project
Steven Black,
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

########################################################################
PACMAN/OCTOPI AND PACKAGE MANAGERS IN GENERAL
########################################################################
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

########################################################################
ClEANING AND ROUTINE MAINTENANCE
########################################################################
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

########################################################################
SYSTEM INFORMATION
########################################################################
This script has the ability to help with troubleshooting as well. It can
collect hardware and software information for troubleshooting issues
online as well as for reinstalling fresh in the future. This script
tries to make things as clear to read as possible by separating the
different information into categories. Each category pertains to things
such as hardware, software, login attempts and many more things. This
data will be saved to one rather large text file in the home folder of
the user who executes the script. Many of this will be useless to a new
user, so there are online forums for help.

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
services. Manjaro specifically has their own tool for managing Kernels
and drivers. This tool helps immensely and is what I utilize in this
scripts kernel manager. This tool will not be in other Arch-based
distributions. Read the documentation for your distribution before
attempting to install or uninstall other kernels. The Arch wiki is a
valuable resource.

########################################################################
MICROCODE
########################################################################
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
Update: There is now an ability to backup the entire system using rsync.
With this new ability, in time there should be a way to restore the
system in the event of a catastrophic issue.

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
browser. Update: I have finally created the perfect script for automation.
Now users are able to create the perfect hosts file for them Without
being bothered to answer questions. The defaults I have chosen
cover a broad spectrum of Ads, Trackers and Malware, for your
convenience.

########################################################################
SWAP FILES
########################################################################
Swap files are an important asset to any Linux system. Swap files are
responsible for storing temporary data when there is no available memory
left on the device. Swap is also useful for storing system contents
during hibernation etc. These scripts will eventually all have the ability
to create one in the event that your system doesn not currently have
one. The blog article about this issue can be found here:
https://techiegeek123.blogspot.com/2019/02/swap-files-in-linux.html.
Please  email me at jackharkness444@protonmail.com for more info about
these scripts or any problems you have with Linux. I will be more than
happy to help. One further notice, the Swap file size is configurable
for users who are somewhat advanced enough to go into the code and
change the size from 2G to whatever they desire.

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
		sudo pacman -Rs --noconfirm $software
		break
	done

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
	sudo rm -r ~/.esd_auth #Best I can tell cookie for pulse audio
	sudo rm -r ~/.local/share/recently-used.xbel
	sudo rm -r /tmp/*
	history -c && rm ~/.bash_history
	sudo rm -r /var/tmp/*

	#This clears the cached RAM
	sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches"

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
	echo "Would you like to remove kernel crash logs?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		sudo find /var -type f -name "core" -print -exec rm {} \;
	break
	done

	#This helps get rid of old archived log entries
	sudo journalctl --vacuum-size=25M

	#This will remove orphan packages from pacman
	sudo pacman -Rsn --noconfirm $(pacman -Qqdt)

	#Optional This will remove the pacman cached applications and older versions
	cat <<_EOF_
	It is probably not a great idea to be cleaning this part of the system
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
		sleep 1
		;;
		2)
		sudo pacman -Sc
		sleep 1
		;;
		3)
		sudo pacman -Scc
		sleep 1
		;;
		4)
		echo "NICE!"
		;;
	esac

	#This removes unwanted apps
	Uninstall
}

BrowserRepair(){
cat <<_EOF_
This can fix a lot of the usual issues with a few of the bigger browsers.
These can include performance hitting issues. If your browser needs a tuneup,
it is probably best to do it in the browser itself, but when you just want something
fast, this can do it for you. More browsers and options are coming. This can also
clean undesired toolbars.
_EOF_

	#Look for the following browsers
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
	echo "5 - Chromium"
	echo "6 - Opera"
	echo "7 - Waterfox"
	echo "8 - Falkon"
	echo "9 - Epiphany"
	echo "10 - Midori"
	echo "11 - Basilisk"
	echo "12 - Brave"

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
		sudo cp -r ~/.config/chromium ~/.config/chromium-old
		sudo rm -rf ~/.config/chromium/*
		echo "Your browser has now been reset"
		sleep 1
	;;
		6)
		sudo cp -r ~/.config/opera ~/.config/opera-old
		sudo rm -rf ~/.config/opera/*
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
		sudo cp -r ~/.config/falkon ~/.config/falkon-old
		sudo rm -rf ~/.config/falkon/*
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
		11)
		sudo cp -r ~/'.moonchild productions'/'basilisk' ~/'.moonchild productions'/'basilisk'-old
		sudo rm -rf ~/'.moonchild productions'/'basilisk'/*
		echo "Your browser has now been reset"
		sleep 1
	;;
		12)
		sudo cp -r ~/.config/BraveSoftware ~/.config/BraveSoftware-old
		sudo rm -rf ~/.config/BraveSoftware/*
		echo "Your browser has now been reset"
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
	checkNetwork

	#This attempts to rank mirrors and update your system
	distribution=$(cat /etc/issue | awk '{print $1}')
	if [[ $distribution == Manjaro ]];
	then
		sudo pacman-mirrors --fasttrack 5 && sudo pacman -Syyu --noconfirm
	elif [[ $distribution == Arch ]];
	then
		sudo pacman -Q | grep reflector || sudo pacman -S --noconfirm reflector; sudo reflector --verbose -l 50 -f 20 --save /etc/pacman.d/mirrorlist; sudo pacman -Syyu --noconfirm
	elif [[ $distribution == KaOS ]];
	then
		sudo pacman -Syyu --noconfirm
	fi

	#This refreshes systemd in case of failed or changed units
	sudo systemctl daemon-reload

	#This will ensure the firewall is enabled
	sudo systemctl enable ufw; sudo ufw enable

	#This refreshes index cache
	sudo updatedb; sudo mandb

	#Checks for pacnew files and other extra configuration file updates
	find /usr/bin/etc-update
	if [ $? -eq 0 ];
	then
		sudo etc-update
	fi

	#update the grub
	sudo grub-mkconfig -o /boot/grub/grub.cfg

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
	echo "3 - mask service"
	echo "4 - save a copy of all the services on your system to a text file"
	echo "5 - Exit without doing anything"

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
		5)
		echo "Smart choice."
		sleep 2
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
		dconf dump /org/cinnamon/ > cinnamon-desktop-backup; dconf reset -f /org/cinnamon
	elif [[ $DESKTOP_SESSION == gnome ]];
	then
		echo "############################################################################"
		echo "This resets Gnome Shell"
		echo "############################################################################"
		dconf dump /org/gnome/ > gnome-desktop-backup; dconf reset -f /org/gnome
	elif [[ $DESKTOP_SESSION == budgie ]];
	then
		echo "############################################################################"
		echo "This resets Budgie"
		echo "############################################################################"
		dconf dump /org/budgie/ > /budgie-desktop-backup; dconf reset -f /org/budgie
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
		dconf dump /org/mate/ > mate-desktop-backup; dconf reset -f /org/mate
	else
		echo "You're running a desktop/Window Manager that we do not yet support... Come back later."
	fi
}

MakeSwap(){
	#This attempts to create a swap file in the event the system doesn't have swap
	grep -q "swap" /etc/fstab
	if [ $? -eq 0 ];
	then
		sudo cp /etc/fstab /etc/fstab.old; sudo fallocate --length 4G /swapfile; sudo chmod 600 /swapfile; sudo mkswap /swapfile; sudo swapon /swapfile
		echo "/swapfile swap swap sw 0 0" | sudo tee -a /etc/fstab
	else
		echo "Swap was already there so there is nothing to do"
	fi
	cat /proc/swaps >> swaplog.txt
	free -h >> swaplog.txt

	Restart
}

Restart(){
	sudo sync && sudo systemctl reboot
}

KernelManager(){
cat <<_EOF_
Kernels are an essential part of the operating system. Failure to use precaution
could inadvertently screw up system functions. The kernel is the main engine behind
the scenes making everything operate within normal parameters, changing kernel settings
or installing/uninstalling a bad updated version could give undesirable results. It should
also be noted that this works in Manjaro, but probably will not work in any other Arch-based operating system
at this time.
_EOF_
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
		break
		done

		echo "Restart?(Y/n)"
		read answer
		while [ $answer == Y ];
		do
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
		break
		done

		echo "Restart?(Y/n)"
		read answer
		while [ $answer == Y ];
		do
			Restart
		break
		done
	;;
		3)
		echo "############################################################################" >> kernels.txt
		echo "WELCOME TO THE ALL NEW MANJARO KERNEL MANAGER" >> kernels.txt
		echo "############################################################################" >> kernels.txt
		sudo mhwd-kernel -l >> kernels.txt
		echo "****************************************************************************" >> kernels.txt
		sudo mhwd-kernel -li >> kernels.txt
		echo "############################################################################" >> kernels.txt
		echo "END OF FILE" >> kernels.txt
		echo "############################################################################" >> kernels.txt
	;;
		4)
		echo "Skipping"
	;;
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
			sudo mount $device /mnt
			sudo rsync -aAXv --delete --exclude={"*.cache/*","*.thumbnails/*","*/.local/share/Trash/*"} /home/$USER /mnt/$host-backups
			sudo sync
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
			sudo sync
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

Restore(){
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
		sudo rsync -aAXv --delete /mnt/$host-backups/* /home
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

Greeting(){
	echo "Enter a selection from the following list:"
	echo "1 - Setup your system"
	echo "2 - Add/Remove user accounts"
	echo "3 - Install software"
	echo "4 - Uninstall software"
	echo "5 - Setup a hosts file"
	echo "6 - Backup your important files and photos"
	echo "7 - Restore your important files and photos"
	echo "8 - Manage system services"
	echo "9 - Install or uninstall kernels"
	echo "10 - Collect system information"
	echo "11 - Create Swap File"
	echo "12 - Cleanup"
	echo "13 - System Maintenance"
	echo "14 - Browser Repair"
	echo "15 - Update"
	echo "16 - Help"
	echo "17 - Restart"
	echo "18 - Reset the desktop"
	echo "19 - exit"

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
		Systeminfo
	;;
		11)
		MakeSwap
	;;
		12)
		cleanup
	;;
		13)
		SystemMaintenance
	;;
		14)
		BrowserRepair
	;;
		15)
		Update
	;;
		16)
		Help
	;;
		17)
		Restart
	;;
		18)
		Reset
	;;
		19)
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

cat <<_EOF_
########################################################################
Hello! Thank you for using Arch Toolbox. Within this script is a multitu-
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
