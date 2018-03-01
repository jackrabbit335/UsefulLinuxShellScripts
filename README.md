#########################################################################
README!!!!!!!!!!!
#########################################################################
To use Linux-Toolbox, you must first ensure that the scripts are
executable, to do this, you have to type chmod +x Arch-Toolbox.sh in a 
command line, I know, it can be scary at first, but trust me, aside from 
actually calling this script, that's all you will have to do. To call this
script you have to type the name in the terminal like this:
./Arch-Utilities.sh. That should do it. This script easily handles all 
the hard work for you. Each function has a number in the list associated 
with it, just type the number of the chore you need done and this handy 
utility goes right to work. Some root privilege may be required
(You may have to put in your password). These scripts are named based on 
the Operating system(distribution) they are meant to work on.

########################################################################
ACKNOWLEDGEMENTS
########################################################################
I wrote these scripts and of course, I had to learn to 
do some of the things in this work. Much of the ideas and information came
from various other linux users. Without their massive contributions to the 
community, this project of mine would not be possible. A list of acknowledge-
ments below:
Joe Collins
Quidsup
SwitchedtoLinux
Matthew Moore
Steven Black
The creator of the other hosts lists I utilize on my own machines. 
Many others... 

########################################################################
WELCOME AND RAMBLE ABOUT LICENSING
########################################################################
Welcome to Linux-Toolbox. This is a useful little utility that 
tries to setup, maintain, and keep up to date with the latest 
software on your system. Linux-Toolbox is delivered as is and thus, 
I can't be held accountable if something goes wrong. This software is 
freely given under the GPL license and is distributable and changeable 
as you see fit, I only ask that you give the author the credit for the 
original work. Linux-Toolbox has been tested and should work on your 
device assuming that you are running an Arch-based or Ubuntu-based system.
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
For sending me hate mail, for inquiring assistance and for sending me 
feedback and suggestions, email me at jackharkness444@protonmail.com
or js185r@gmail.com Send your inquiries and suggestions with a 
corresponding subject line.