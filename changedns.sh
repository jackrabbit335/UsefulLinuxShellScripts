#!/bin/bash

#Ask user if they wanna install an alternative and easier to work with Network manager
cat <<_EOF_
If you don't install wicd, this may or may not work for you. 
Most Manjaro or Arch systems using NetworkManager won't work with /etc/resolv.conf.head.
Haven't tested this in Ubuntu yet.
_EOF_
echo "What would you like to do today?"
echo "1 - Install wicd and change dns"
echo "2 - remove old network management software"

read operation;

	case $operation in 
		1)
        echo "Are you sure you want to do this?(Y/n)"
        read answer
        while [ $answer == Y ];
        do
		    if [ -d /etc/pacaman.d ]
		    then
			    sudo pacman -S --noconfirm wicd wicd-gtk python2-notify
			    sudo systemctl stop NetworkManager
			    sudo systemctl disable NetworkManager
			    sudo systemctl enable wicd
			    sudo systemctl start wicd 
			    echo "Now we need your username, enter it now"
			    read username
			    cat /etc/passwd | awk -F: '{print $1}' | grep $username
		    fi
		    if [ -d /etc/apt ]
		    then
		    	sudo apt install -d --reinstall network-manager network-manager-gnome
			    sudo apt update && sudo apt install -y wicd
		    	sudo /etc/init.d/network-manager stop
		    	sudo /etc/init.d/network-manager disable 
		    	sudo /etc/init.d/wicd enable
		    	sudo /etc/init.d/wicd start
		    fi

		    #create file /etc/resolv.conf.head 
		    sudo touch /etc/resolv.conf.head

		    #Create an optional set of name servers to choose from
		    echo "1 - this nameserver package is cloudflare's privacy centric set"
		    echo "2 -  This set of nameservers is for google"
		    echo "3 - This set of name servers belongs to Opendns"
		    read package
		    if [[ $package == 1 ]];
		    then
			    echo "name_servers='1.1.1.1 1.0.0.1'" | sudo tee -a /etc/resolv.conf.head
	    	elif [[ $package == 2 ]];
		    then
			    echo "name_servers='8.8.8.8 8.8.4.4'" | sudo tee -a /etc/resolv.conf.head
		    elif [[ $package == 3 ]];
		    then
		    	echo "name_servers='208.67.222.222 208.67.220.220'" | sudo tee -a /etc/resolv.conf.head
		    else
		    	echo "You entered an invalid package please try again"
		    	sleep 1
			    exit
		    fi

		    #For good measure
		    sudo resolvconf -u

		    #Check /etc/resolv.conf
		    cat /etc/resolv.conf
		    sleep 1
        break
        done 
	;;
		2)
        find /etc/wicd
        while [ $? -eq 0 ];
        do
		    if [ -d /etc/pacman.d ]
		    then
		    	sudo pacman -Rs networkmanager
		    fi
		    if [ -d /etc/apt ]
		    then
		    	sudo apt remove network-manager network-manager-gnome
		    	sudo dpkg --purge network-manager network-manager-gnome
		    fi
        break
        done
	;;
		*)
		echo "This is an invalid option... Please try again."
	;;
	esac

#Suggest that user reboot their machine
echo "You should probably reboot now... Reboot?(Y/n)"
read answer
if [[ $answer == Y ]];
then
	sudo systemctl reboot
else
	echo "You should really reboot soon for all changes to take effect!"
	sleep 1
	exit
fi
