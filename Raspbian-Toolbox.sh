#!/bin/bash

Setup(){
	#This backs up important system files for your convenience
	sudo cp /boot/cmdline.txt /boot/cmdline.txt.bak
	sudo cp /boot/config.txt /boot/config.txt.bak
	sudo cp -r /etc/sysctl.d /etc/sysctl.d-old
	sudo cp /etc/sysctl.conf /etc/sysctl.conf.bak
	sudo cp /etc/environment /etc/environment.bak
	sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
	sudo cp /etc/profile /etc/profile.bak
	sudo cp /etc/fstab /etc/fstab.bak
	sudo cp /etc/passwd /etc/passwd.bak
	sudo cp /etc/shadow /etc/shadow.bak
	sudo cp /etc/systemd/journald.conf /etc/systemd/journald.conf.bak
	cp ~/.bashrc ~/.bashrc.bak
	
	#Fix screen RESOLUTION
	echo "Would you like to choose a more accurate screen resolution?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		Screenfix
		break
	done
	
	#This activates the firewall
	dpkg --list | grep ufw || sudo apt install -y gufw
	echo "Would you like to deny ssh and telnet for security purposes?(Y/n)"
	read answer
	if [[ $answer == Y ]];
	then
		sudo ufw deny telnet; sudo ufw deny ssh; sudo ufw reload
	fi
	
	#This downloads the widevine library to stream netflix with chromium
	sudo apt install -y libwidevinecdm0
	sudo mv /opt/WidevineCdm/_platform_specific/linux_arm/libwidevinecdm.so /usr/lib/chromium-browser
	sudo chmod 644 /usr/lib/chromium-browser/libwidevinecdm.so
	
	#This disables ipv6
	echo "Sometimes ipv6 can cause network issues. Would you like to disable it?(Y/n)"
	read answer
	if [[ $answer == Y ]];
	then
		sudo sed -i -e 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="ipv6.disable=1"/g' /etc/default/grub; sudo update-grub2
	else
		echo "Okay!"
	fi
	
	#This adds aliases of import to Raspbian OS
	echo "#Alias to fix broken packages" >> .bashrc
	echo 'alias fix="sudo dpkg --configure -a && sudo apt install -f"' >> ~/.bashrc
	echo "#Alias to update system" >> ~/.bashrc
	echo 'alias update="sudo apt update && sudo apt full-upgrade -yy"' >> ~/.bashrc
	echo "#Alias to clean package cache" >> ~/.bashrc
	echo 'alias clean="sudo apt autoremove -y && sudo apt autoclean -y && sudo apt clean -y"' >> ~/.bashrc
	echo "#Alias to show disk usage and free space" >> ~/.bashrc
	echo 'alias disk="du -sh && df -h"' >> ~/.bashrc
	echo "#Alias to show cpu information" >> ~.bashrc
	echo 'alias cpuinfo="cat /proc/cpuinfo"' >> ~/.bashrc
	echo "#Alias to show memory information" >> ~/.bashrc
	echo 'alias meminfo="cat /proc/meminfo"' >> ~/.bashrc
	echo "#Alias to show free memory in realtime" >> ~/.bashrc
	echo 'alias mem="watch free -h"' >> ~/.bashrc
	echo "#Alias to free cached memory" >> ~/.bashrc
	echo 'alias boost="sudo sysctl -w vm.drop_caches=3"' >> ~/.bashrc
	echo "#Alias to show cpu temps" >> ~/.bashrc
	echo 'alias temp="watch vcgencmd measure_temp"' >> ~/.bashrc
	echo "#Alias to show cpu information" >> ~/.bashrc
	echo 'alias cpuinfo="cat /proc/cpuinfo"' >> ~/.bashrc
	echo "#Current CPU frequency" >> ~/.bashrc
	echo 'alias cur_freq="cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq"' >> ~/.bashrc
	echo "#Minimum CPU frequency" >> ~/.bashrc
	echo 'alias min_freq="cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq"' >> ~/.bashrc
	echo "#Maximum CPU frequency" >> ~/.bashrc
	echo 'alias max_freq="cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq"' >> ~/.bashrc
	echo "#Core Pi Voltage" >> ~/.bashrc
	echo 'alias volt="vcgencmd measure_voltage core"' >> ~/.bashrc
	echo "#Gpu Allocated memory" >> ~/.bashrc 
	echo 'alias gx="vcgencmd get_mem gpu"' >> ~/.bashrc
	echo "#Arm chip Allocated memory" >> ~/.bashrc
	echo 'alias armmem="vcgencmd get_mem arm"' >> ~/.bashrc
	echo "#Alias to show swap usage" >> ~/.bashrc
	echo 'alias swaps="cat /proc/swaps"' >> ~/.bashrc
	echo "#Alias to show uptime information" >> ~/.bashrc
	echo 'alias ut="uptime -p"' >> ~/.bashrc
	
	#Reduces space taken up by log file
	sudo sed -i -e '/#SystemMaxUse=/c\SystemMaxUse=50M ' /etc/systemd/journald.conf
	
	#Tweaks the sysctl config file
	sudo touch /etc/sysctl.d/50-dmesg-restrict.conf
	echo "kernel.dmesg_restrict = 1" | sudo tee -a /etc/sysctl.d/50-dmesg-restrict.conf
	echo "# Reduces the swap" | sudo tee -a /etc/sysctl.conf
	echo "vm.swappiness = 10" | sudo tee -a /etc/sysctl.conf
	echo "# Improve cache management" | sudo tee -a /etc/sysctl.conf
	echo "vm.vfs_cache_pressure = 50" | sudo tee -a /etc/sysctl.conf
	echo "vm.watermark_scale_factor = 200" | sudo tee -a /etc/sysctl.conf
	echo "vm.dirty_ratio = 3" | sudo tee -a /etc/sysctl.conf
	echo "#tcp flaw workaround" | sudo tee -a /etc/sysctl.conf
	echo "net.ipv4.tcp_challenge_ack_limit = 999999999" | sudo tee -a /etc/sysctl.conf
	sudo sysctl -p && sudo sysctl --system
	
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
		sudo sysctl -p && sudo sysctl --system
	fi
	
	#This locks down ssh
	#sudo sed -i -e '/#PermitRootLogin/c\PermitRootLogin no ' /etc/ssh/sshd_config

	CheckNetwork

	#Updates the system
	sudo apt update; sudo apt full-upgrade -yy; sudo apt install -y rpi-eeprom
	
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

InstallandConquer(){
	CheckNetwork
	
	echo "Would you like to install some useful apps?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		echo "1 - Browsers"
		echo "2 - Utility"
		echo "3 - Kodi"
		echo "4 - Individual programming apps"
		echo "5 - Rpi-imager"
		echo "6 - Claws mail"
		echo "7 - "
		echo "8 - Games"
		echo "9 - Get out of this menu"
		read software;
		case $software in
			1)
			echo "1 - Firefox"
			echo "2 - Midori"
			echo "3 - Epiphany"
			echo "4 - Vivaldi" 
			echo "5 - netsurf"
			echo "6 - lynx"
			echo "7 - luakit"
			read package
			if [[ $package == 1 ]];
			then
				sudo apt install -y firefox-esr
			elif [[ $package == 2 ]];
			then
				sudo apt install -y midori
			elif [[ $package == 3 ]];
			then
				sudo apt install -y epiphany-browser
			elif [[ $package == 4 ]];
			then
				wget https://downloads.vivaldi.com/stable/vivaldi-stable_4.3.2439.44-1_armhf.deb; sudo dpkg -i *.deb; sudo apt install -f
			elif [[ $package == 5 ]];
			then
				sudo apt install -y netsurf
			elif [[ $package == 6 ]];
			then
				sudo apt install -y lynx
			elif [[ $package == 7 ]];
			then
				sudo apt install -y luakit
			fi
			;;
			2)
			sudo apt install -y nmap iotop gparted gnome-disk-utility lm-sensors 
			;;
			3)
			sudo apt install -y kodi
			;;
			4)
			echo "1 - Geany"
			echo "2 - Mu-editor"
			echo "3 - Eclipse-rpm-editor"
			echo "4 - Bluefish"
			echo "5 - Code"
			echo "6 - Thonny"
			echo "7 - Sonic PI"
			echo "8 - Bluej"
			echo "9 - SmartSim"
			echo "10 - Scratch"
			echo "11 - arduino"
			echo "12 - Vnc Viewer"
			echo "13 - GreenFoot IDE"
			echo "14 - Meld"
			read software;
			case $software in
				1)
				sudo apt install -y geany
				;;
				2)
				sudo apt install -y mu-editor
				;;
				3)
				sudo apt install -y eclipse-rpm-editor
				;;
				4)
				sudo apt install -y bluefish
				;;
				5)
				sudo apt install -y code
				;;
				6)
				sudo apt install -y thonny
				;;
				7)
				sudo apt install -y sonic-pi
				;;
				8)
				sudo apt install -y bluej
				;;
				9)
				sudo apt install -y smartsim
				;;
				10)
				sudo apt install -y scratch scratch2 scratch3
				;;
				11)
				sudo apt install -y arduino
				;;
				12)
				sudo apt install -y vncjava
				;;
				13)
				sudo apt install -y greenfoot
				;;
				14)
				sudo apt install -y meld
				;;
				*)
				;;
			esac
			;;
			5)
			sudo apt install -y rpi-imager
			;;
			6)
			sudo apt install -y claws-mail
			;;
			7)
			;;
			8)
			echo "1 - Bsd-games"
			echo "2 - Gnome-games"
			echo "3 - Python-games"
			echo "4 - MineCraft"
			echo "5 - Code The Classics"
			read package
			if [[ $package == 1 ]];
			then
				sudo apt install -y bsdgames
			elif [[ $package == 2 ]];
			then
				sudo apt install -y gnome-games
			elif [[ $package == 3 ]];
			then
				sudo apt install -y python-games
			elif [[ $package == 4 ]];
			then
				sudo apt install -y minecraft-pi
			elif [[ $package == 5 ]];
			then
				sudo apt install -y code-the-classics
			fi
			;;
			*)
			;;
		esac
	done
	
	clear
	Greeting
}

RAMBack(){
	sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches"

	clear
	Greeting
}

Cleanup(){
	#This removes the apt package cache
	sudo apt autoremove -y
	sudo apt autoclean -y 
	sudo apt clean -y
	
	#This removes the apt list
	sudo rm -r /var/lib/apt/lists/*

	#This cleans the cache and recently used apps list
	sudo rm -r ~/.cache/*
	sudo rm -r ~/.thumbnails/*
	sudo rm ~/.local/share/recently-used.xbel
	history -c && rm ~/.bash_history
	
	#This cleans the manual database
	sudo mandb
	
	#This removes old config files
	sudo rm -r ~/.config/*-old
	
	#This could clean your Video folder and Picture folder based on a set time
	TRASHCAN=~/.local/share/Trash/files/
	find ~/Downloads/* -mtime +30 -exec mv {} $TRASHCAN \;
	find ~/Video/* -mtime +30 -exec mv {} $TRASHCAN \;
	find ~/Pictures/* -mtime +30 -exec mv {} $TRASHCAN \;
	
	#cleans old kernel crash logs
	sudo find /var -type f -name "core" -print -exec rm {} \;
	
	#This removes left over files from apps uninstalled
	OLDCONF=$(dpkg -l | grep '^rc' | awk '{print $2}')
	sudo apt remove --purge $OLDCONF
	
	#This removes broken symlinks
	find -xtype l -delete
	
	#Remove unused files leftover in the home directory
	find $HOME -type f -name "*~" -print -exec rm {} \;

	#This reduces journal log size by removing old logs
	sudo journalctl --vacuum-size=25M
	
	#This uninstalls unwanted apps
	echo "Do you wish to uninstall apps?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		Uninstall
	done

	clear
	Greeting
}

Maintenance(){
	CheckNetwork

	#This fixes broken packages
	sudo dpkg --configure -a; sudo apt install -f

	#This updates your system
	sudo apt update && sudo apt full-upgrade -yy

	#This restarts systemd daemon. This can be useful for different reasons.
	sudo systemctl daemon-reload

	#It is recommended that your firewall is enabled
	#sudo systemctl enable ufw; sudo ufw enable

	#This updates grub
	sudo update-grub2

	#Checks disk for errors
	sudo touch /forcefsck

	#Optional
	echo "Would you like to run Cleanup?(Y/n)"
	read answer
	if [[ $answer == Y ]];
	then
		Cleanup
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
			echo "3 - Reset Failed"
			echo "4 - create a list of all services running on your system"
			echo "5 - Nothing just get me out of this menu"
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
				sudo systemctl reset-failed
				;;
				4)
				echo "################################################################" >> services.txt
				echo "SERVICE MANAGER" >> services.txt
				echo "################################################################" >> services.txt
				service --status-all >> services.txt
				systemctl list-unit-files --type=service >> services.txt
				echo "################################################################" >> services.txt
				echo "END OF FILE" >> services.txt
				echo "################################################################" >> services.txt
				;;
				5)
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

MakeSwap(){
	echo "Coming Soon!"
	
	clear
	Greeting
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
	browser6="$(find /usr/bin/waterfox)"
	browser7="$(find /usr/bin/epiphany)"
	browser8="$(find /usr/bin/midori)"

	echo $browser1
	echo $browser2
	echo $browser3
	echo $browser4
	echo $browser5
	echo $browser6
	echo $browser7
	echo $browser8

	sleep 1

	echo "choose the browser you wish to reset"
	echo "1 - Firefox"
	echo "2 - Vivaldi"
	echo "3 - Pale Moon"
	echo "4 - Chrome"
	echo "5 - Chromium"
	echo "6 - Waterfox"
	echo "7 - Midori"
	echo "8 - Epiphany"
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
		sudo cp -r ~/.waterfox ~/.waterfox-old; sudo rm -rf ~/.waterfox/*
		echo "Your browser has now been reset"
		sleep 1
		;;
		7)
		sudo cp -r ~/.config/midori ~/.config/midori-old; sudo rm -rf ~/.config/midori/*
		echo "Your browser has now been reset"
		sleep 1
		;;
		8)
		sudo cp -r ~/.config/epiphany ~/.config/epiphany-old; sudo rm -rf ~/.config/epiphany/*
		sudo cp -r ~/.local/share/epiphany ~/.local/share/epiphany-old; sudo rm -rf ~/.local/share/epiphany/*
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

Update(){
	sudo apt update && sudo apt full-upgrade -yy

	clear
	Greeting
}

SystemInfo(){
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
Welcome to Raspbian-Toolbox. This is a useful little utility that
tries to setup, maintain, and keep up to date with the latest
software on your system. Raspbian-Toolbox is delivered as is and thus,
I can not be held accountable if something goes wrong. This software is
freely given under the GPL license and is distributable and changeable
as you see fit, I only ask that you give the author the credit for the
original work. Ubuntu-Toolbox has been tested and should work on your
device assuming that you are running a Raspberry Pi, or Raspbian-based system.
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
00 20 * * * /bin/sh /home/USER/hostsupdater.sh.
I set it up under the root account by typing su followed by my password
in manjaro, sudo -i in Ubuntu systems and then typing crontab -e.
The maintenance scripts are ok to run manually each month.
It is recommended that you do not run these without being present.
Hoever, if you wish to run them as cron jobs then you can tweak the
cleaning routines as follows."sudo rm -r ./cache/*" should be changed to
"rm -r /home/USER/.cache/*" and etc. The setup script should only be
ran once to set the system up.
Some good reference sites are:
https://www.raspberrypi.org/
https://www.debian.org/
https://tutorials-raspberrypi.com
https://www.reddit.com/r/raspberry_pi/
https://raspbian.org

##########################################################################
INITIAL SET UP AND OTHER OPTIONS
##########################################################################
Initial setup with most installations of Raspbian/Raspberry Pi OS is 
automatically started on first boot, however, this is a modest array of 
settings shown to the user. For this reason, usually Raspi-config is 
installed as both a CLI and GUI. Noobs has this, however, they modify
the initial setup and add loads of extra software bloat to systems.
Flashing the software yourself gives you more control over what gets
installed on your flashy new mini-pc. In this script the user has access
to even more options that are not currently added to raspi-config or in 
the welcome screen. These settings have to do with ipv6 usage, memory tweaks,
firewall installation and enablement, etc. Most of these tweaks are safe
to implement, but some may not be needed as with regards to the memory side,
Raspberry Pi OS manages memory fairly competently on its own.

##########################################################################
OVER CLOCKING AND IMPROVING GPU PERFORMANCE
##########################################################################
Raspi-config also offers a couple of options with regards to managing 
overclocks for cpu chip and gpu memory allocation. Most online sources 
agree that gpu memory should be allocated to 128MB of memory for better
video performance. The command line version of the tool also offers
access to video driver options as well. The new video driver is meant to
help with certain conditions of screen tearing and hardware performance,
however, I have noticed that gpu acceleration on raspberry pi is sorely
lacking as of yet. The new video driver is helping, but even it is in its
infancy right now. Overclocking can also be administered in new Raspberry
Pi 4 systems through a file in the boot directory. This will allow the 
system to boot automatically with those settings. The file is called
config.txt and it has its own section for arm and gpu overclocking. 
Boards and chips will vary, but when setting these commands, it is 
imperative to not go too high at once and to offer adequate cooling
measures for your device. Canakit comes with heatsinks and a fan for just 
that. Furthermore, setting the board vertically with heatsinks can help with
cooling as long as it has plenty of air on both sides.

##########################################################################
GPIO & FAN INSTALLATION ON PI 4
##########################################################################
If you get a pi from Canakit, it will come with a booklet and a diagram of 
GPIO map and where each circuit leads to on the board. The Fan takes up
two such pins. If you're wiring up arduino it uses others. The pins are 
numbered on the graph and the graph will tell you what they do. I'll post
a link to a picture of said diagram later. 

##########################################################################
MEMORY TWEAKS & SWAP MANIPULATION
##########################################################################
Memory is a crucial part of working with any computer device. Memory
stores important information for running programs and opening documents
in a temporary capacity for the processor to read and "process". Having 
enough RAM is vital to getting work done and keeping the system from 
crashing prematurely. Memory acts in a similar manner to Flash storage,
but it only holds information until either the program is no longer in use
or the system is shutdown or rebooted. Raspberry Pi devices are no different, 
having access to 2,4, and 8GB in the new Raspberry Pi 4, Raspberry Pi devices
are now doing more than ever before. Some of these devices can serve as a
desktop replacement. Memory has many facets to keeping the system afloat. 
Some Memory is used for cache purposes in case programs or files are needed
at a later time. Some is used for buffering or holding information in the 
case of moving large files around or downloading torrents. This Memory gets 
slowly cleared later when it is written to disk. The Kernel manages Memory on
Raspberry Pi's in a similar manner to other operating systems, though it appears
that it is more frequently cleared as Memory usually comes in such short supply 
on these devices and the platform is smaller. Everything is optimized for your
new single board computer. However, for some systems this can be tweaked even 
further. This won't work on every system, but those with more Memory might
see a slight benefit. Changing the swap value, dirty ratio, watermark scale
factor, etc. These all try to free as much RAM as possible as fast as possible
to ensure that it is available for later use. This helps in situations where
the device is powered on for longer periods of time like in servers. I have
added many of these tweaks to my script, but these can be commented out to 
ignore them during setup. The default swap size is often too small for these 
devices as well, manipulating that is a more advanced procedure which I will
cover later on.

##########################################################################
GETTING WIDEVINE ON CHROMIUM FOR DRM & DISABLING JAVASCRIPT
##########################################################################
Chromium can be custom built to come with widevine enabled from the start, 
however, it is not the case in Raspberry Pi OS as this would cause legal
disputes for the open-source software. There is a script made for this 
purpose and libwidevine is still available in the repositories. Perhaps 
I will implement a function for grabbing and running this script later.
By default, Chromium comes with Ublock Origin and H264 installed as 
extensions. Javascript is still fully enabled, but just like using adblockers
can help with intense webpages, so too can disabling scripts and only allowing
scripts the user trusts or wishes to run. Considered rather extreme by many,
this concept is nigh essential to running bloated websites on a low end device,
however, this can brick sites, so users can allow sites they deem trustworthy.
There are Noscript like alternatives available, but nothing as good as using
what's already in the browser.

##########################################################################
ADBLOCKING THROUGH THE HOSTS FILE
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
RECOMMENDED SOFTWARE & PI IMAGER
##########################################################################
Recommended software is software chosen by the Raspbian Foundation to cover
the needs of everyone from children learning code, to advanced programmers
writing software for a living. Many pieces of this software come preloaded 
on Noobs loaded sd cards. Raspberry Pi OS, when loaded by you, comes with 
the bare minimum of software for moderate daily use. To do advanced 
coding one might desire the recommended packages which can be installed
later on by the user by opening a program titled "Recommended Software".
Aptly named, this software allows the user to easily check a box that will 
install the said pieces one by one or in a list. Pi imager is great software 
for loading Raspbian and formating said sd cards yourself, allowing you to 
build your own set up with a desktop or for a server in headless. rpi-imager 
allows you to choose which version of image you wish to install ranging from
Pure headless Raspbian to Full with other images including Librelec available.
To install this run apt install -y  rpi-imager or very soon this option will 
be available in my scripts.

##########################################################################
SD CARDS AND INSUFFICIENT POWER FOR PERFORMANCE
##########################################################################
Raspberry 3 and older versions use less power than raspberry pi 4.
Raspberry Pi uses a consistent stream of 5V power over a 2.5 to 3.5 Amp
power adapter. These adapters are crucial in getting the most out of the 
Pi. By default, the board itself uses around 800mAh to 1.2 Amps of power.
Adding usb drives increases this up to around 3 Amps depending on the
amount of drives plugged in, or the type of drives plugged in. This also
covers peripherals. This in turn also produces more heat which can impact
performance if the device is not properly cooled. SD cards rely on some 
of this juice to run. SD cards are much slower than USB on certain iop 
operations. While SD can read and write potentially faster at random, 
transfers and cached reads and writes can do a little better on USB, 
this is possibly why you may notice a slight lagginess on SD cards. 
Some SD cards are better for performance. Recommended SD cards by 
trusted carriers are important. Samsung and Sandisk are good brands 
to choose. SD card readers on Pi can be overclocked, but this is not 
recommended as it can have disasterous effects on the cards installed. 
SD cards also don't do as well after power interruptions. This might be 
something to avoid when running a Pi.

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
/etc/X11/xorg.conf.d/ On Raspbian systems, occassionally you will
notice black borders around the monitor. This is normal and can be fixed
by enabling overscanning. Overscanning is like Raspbian autocorrection. 
In the initial setup you might notice a box that is unchecked by default.
This enables overscanning.

##########################################################################
APT & DPKG
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
CLEANING AND MAINTENANCE
##########################################################################
Cleaning and maintaining Raspberry Pi OS is a good practice and is done in
much the same way it is done on regular Ubuntu, but being Debian minor 
differences appear here and there, so I have added a function for expediting 
and automating much of this process at the behest of the user. I recommend 
running this once a month at least unless on critical servers. This will re-
quire a reboot to take full effect. This will also check disk and filesystem
health on boot by running fsck. the desired method is using sudo shutdown -rF now,
but the old-fashioned way still exists by creating a file called
forcefsck in the root directory that will take precedence on next boot. I suggest
doing this as often as needed. 

##########################################################################
LOG FILES AND DISK WRITES
##########################################################################
Log files are a necessary part of troubleshooting for man techs, but
on some Pi's they are not really necessary as reloading is easier and faster
now than it ever was before. Also, backup cards are cheaper than ever. There 
are suggestions to move the log directory to RAM, but this will blow up your 
RAM and not be freed until you reboot your system. Turning off the service,
while this can free up resources, is just not a good idea either. While 
the log file can reduce the lifespan of the sd card, it's not as much of a
problem as it used to be. With journald, you can tweak the amount of space
taken up by the logs at any one given time. This helps the sd technology to 
automatically wear level more evenly. This in turn is the better option.

##########################################################################
TROUBLESHOOTING INFO
##########################################################################
This script has the ability to help with troubleshooting as well. It can
collect hardware and software information for troubleshooting issues
online as well as for reinstalling fresh in the future. This script
tries to make things as clear to read as possible by separating the
different information into categories. Each category pertains to things
such as hardware, software, login attempts and many more things. This
data will be saved to one rather large text file in the home folder of
the user who executes the script. Much of this will be useless to a new
user, so there are online forums for help.

##########################################################################
RPI-EEPROM BOOTLOADER CONFIGURATION
##########################################################################
The bootloader and chip firmware drivers are integral parts of the system.
They allow the Kernel and underlying software to talk to the board itself.
Updating Raspberry pi bootloaders and firmware drivers is a mixed bag on
dependability, however, many of the updates are very important for continued
smooth operation of the device. Installing these can help with compatibility
with newer wireless technologies, security and heat dissipation of the board, 
and even better support with newer kernels. Many of the firmware packages 
you might see are for Wireless, Audio, Bluetooth, etc, but RPI-EEPROM
is just as important. This package has to do with cooling and smooth 
operation of the board components and arm chip itself specifically. 
This is automatically updated now by default. In the early days it 
posed a risk, but now installing it is crucial and there are ways to
downgrade the configuration or roll it back to a previous date. 

##########################################################################
DIFFERENCE BETWEEN ARM AND X86 PLATFORMS
##########################################################################
The difference between the two platforms comes down to their instruction
sets. Instructions are written in machine and allow the processor to 
handle a given task. ask the same task of both devices and the
ARM device will take longer to do the same work. Arms can do the same
work with half the chip size and or transistors. Desktops are clunky and
less efficient, however, they have the real estate to work faster. Arm 
devices are much like Mobile which includes our cell phones. They can do
amazing things with less power draw in a given amount of time as compared 
to their larger cousins. Much of the same software can be optimized to work
on either platform, however, the OS choices are limited on the ARM. On 
the face of it, it becomes a matter of software optimization. How small a
footprint can you create software to do the same job faster will determine 
time constraints for the smaller device.

##########################################################################
WHY IS MY NETWORK SEEMINGLY SLOWER? AND ONBOARD WIFI/BLUETOOTH
##########################################################################
Raspberry Pi 4 and Raspberry Pi 3 often get far different internet speeds
despite the 4 being slightly more powerful as a device. The reasons aren't
at all apparent for many people and some boards are still different than others.
Best guess from looking at forums is that many Rasp-pi 4's suffer from
insufficient clearance of the different receivers from LAN and WLAN and 
Bluetooth. As raspberry pi 4 is the first one to offer wifi and bluetooth
already built in, this seems like it makes sense. Add this to the fact that
Raspberry Pi's have to process all data they receive through their cpu, 
much the way a desktop would. Desktops do it faster, while Rpi's take
slightly longer. There are work arounds for this at the hardware level, 
by adding a wifi dongle you might get better speeds over wifi for example.
But I haven't tested this yet.

##########################################################################
LIMITED SOFTWARE AVAILABILITY? BLAME DEBIAN
##########################################################################
Debian seeks to favor stability over new and flashy. Debian holds Open
source values to their highest when developing and selecting software for 
a device running it. Debian and Raspbian are similar, however there are
differences in the platforms serviced. Raspbian comes with Chromium as 
a web browser(was epiphany), and Geany as a programming IDE. VLC is the 
media player by default(I would have chosen something lighter, but vlc -
has all the features). Mousepad is the text editor which is funny as 
Raspbian uses LXDE for the desktop and openbox for Window Manager. Both 
rely on using mostly free and open source or FOSS. Though it should be noted 
that Raspbian uses closed source code for the firmware.

EOF
}

Screenfix(){
	xrandr
	echo "Choose a resolution from the list above"
	read resolution
	xrandr -s $resolution
}

Restart(){
	sudo sync; reboot
}

Backup(){
	echo "Coming Soon!"
	
	clear
	Greeting
}

Restore(){
	echo "Coming Soon!"
	
	clear
	Greeting
}

Uninstall(){
	echo "Are there any applications you wish to remove?(Y/n)"
	read answer
	while [ $answer == Y ];
	do
		read -a software
		sudo apt remove --purge -yy ${software[@]}
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
			echo "Connection Successful"
		else
			read -p "Check hardware cable status and press enter..."
			interface=$(ip -o -4 route show to default | awk '{print $5}')
			sudo dhclient -v -r && sudo dhclient; sudo /etc/init.d/networking stop
			sudo /etc/init.d/networking disable; sudo /etc/init.d/networking enable
			sudo /etc/init.d/networking start; sudo ip link set $interface up
		fi 

	done
}

Disclaimer(){
cat <<EOF
##########################################################################
Hello! Thank you for using Raspbian-Toolbox. Within this script is a multitu-
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
read -p  $'\n'$"Press enter to continue..."
}

Greeting(){
		echo $'\n'$"Enter a selection from the following list"
	echo "1 - Setup your system"
	echo "2 - Add/Remove user accounts"
	echo "3 - Install software"
	echo "4 - Uninstall software"
	echo "5 - Setup a hosts file"
	echo "6 - Backup your system"
	echo "7 - Restore your system"
	echo "8 - Manage system services"
	echo "9 - Troubleshooting Information"
	echo "10 - Screenfix"
	echo "11 - Make Swap"
	echo "12 - Help"
	echo "13 - Cleanup"
	echo "14 - RAMBack"
	echo "15 - System Maintenance"
	echo "16 - Browser Repair"
	echo "17 - Update"
	echo "18 - Restart"
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
		Cleanup
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
