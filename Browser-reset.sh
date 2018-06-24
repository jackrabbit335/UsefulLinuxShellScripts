#!/bin/bash

cat << _EOF_
This can fix a lot of the usual issues with a few of the bigger browsers. 
These can include performance hitting issues. If your browser needs a tuneup,
it is probably best to do it in the browser itself, but when you just want something
fast, this can do it for you. More browsers and options are coming.
_EOF_

echo "choose the browser you wish to reset"
echo "1 - Firefox"
echo "2 - Vivaldi" 
echo "3 - Pale Moon"
echo "4 - Chrome"
echo "5 - Opera"

read operation;

case $operation in
	1)
	sudo cp -r ~/.mozilla/firefox ~/.mozilla/firefox-old
	sudo rm -r ~/.mozilla/firefox/profile.ini 
	echo "Your browser has now been reset"
	sleep 1
;;
	2)
	sudo cp -r ~/.config/vivaldi ~/.config/vivaldi-old
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
	sudo cp -r ~/.config/opera ~/.config/opera-old
	sudo rm -r ~/.config/opera/* 
	echo "Your browser has now been reset"
	sleep 1
;;
esac
	
