#!/bin/bash
sudo iptables -L
sleep 1

echo "What do you want to do?"
echo "1 - setup iptables with ssh and telnet blocked"
echo "2 - setup iptables with regular and basic settings"
echo "3 - flush all iptable rules"
echo "4 - Load previously set rules from rule data file"
			
read operation;
			
case $operation in
	1)
	sudo iptables --policy FORWARD DROP
	sudo iptables -A INPUT -i lo -j ACCEPT
	sudo iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
	sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
	sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
	sudo iptables -A INPUT -p tcp --dport 143 -j ACCEPT
	sudo iptables -A INPUT -p tcp --dport 993 -j ACCEPT
	sudo iptables -A INPUT -p tcp --dport 110 -j ACCEPT
	sudo iptables -A INPUT -p tcp --dport 995 -j ACCEPT
	sudo iptables -A INPUT -p tcp --dport 20 -j ACCEPT
	sudo iptables -A INPUT -p tcp --dport 21 -j ACCEPT
	sudo iptables -A INPUT -p tcp --dport 25 -j ACCEPT
	sudo iptables -A INPUT -p tcp --dport 465 -j ACCEPT
	sudo iptables -A INPUT -p tcp --dport 22 -j DROP
	sudo iptables -A INPUT -p tcp --dport 23 -j DROP
	sudo iptables  --policy INPUT DROP
	sudo iptables-save > first-iptables-rules.dat
;;
	2)
	sudo iptables --policy FORWARD DROP
	sudo iptables -A INPUT -i lo -j ACCEPT
	sudo iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
	sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
	sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
	sudo iptables -A INPUT -p tcp --dport 143 -j ACCEPT
	sudo iptables -A INPuT -p tcp --dport -993 -j ACCEPT
	sudo iptables -A INPUT -p tcp --dport 110 -j ACCEPT
	sudo iptables -A INPUT -p tcp --dport 995 -j ACCEPT
	sudo iptables -A INPUT -p tcp --dport 20 -j ACCEPT
	sudo iptables -A INPUT -p tcp --dport 21 -j ACCEPT
	sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
	sudo iptables -A INPUT -p tcp --dport 23 -j ACCEPT
	sudo iptables -A INPUT -p tcp --dport 25 -j ACCEPT
	sudo iptables -A INPUT -p tcp --dport 465 -j ACCEPT
	sudo iptables -A INPUT -p icmp -j ACCEPT #Accepts all incoming pings may wanna fix that later.
	sudo iptables --policy INPUT DROP
    sudo iptables-save > first-iptables-rules.dat
;;
	3)
	sudo iptables -F
;;
	4)
	sudo iptables-restore < first-iptables-rules.dat
;;
	*)
	echo "This is an invalid request"
;;
esac
