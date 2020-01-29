#!/bin/bash

echo "##################################################################"
echo "Moving To Centralized Location"
echo "##################################################################"

cd /tmp

echo "##################################################################"
echo "Commensing Download And Extraction Sequence Now"
echo "##################################################################"
wget "http://list.iblocklist.com/?list=gihxqmhyunbxhbmgqrla&fileformat=p2p&archiveformat=gz" -O peerblock1.gz
wget "http://list.iblocklist.com/?list=dufcxgnbjsdwmwctgfuj&fileformat=p2p&archiveformat=gz" -O peerblock2.gz
wget "http://list.iblocklist.com/?list=ydxerpxkpcfqjaybcssw&fileformat=p2p&archiveformat=gz" -O peerblock3.gz
wget "http://list.iblocklist.com/?list=gyisgnzbhppbvsphucsw&fileformat=p2p&archiveformat=gz" -O peerblock4.gz
wget "http://list.iblocklist.com/?list=uwnukjqktoggdknzrhgh&fileformat=p2p&archiveformat=gz" -O peerblock5.gz
wget "http://list.iblocklist.com/?list=plkehquoahljmyxjixpu&fileformat=p2p&archiveformat=gz" -O peerblock6.gz
wget "http://list.iblocklist.com/?list=cwworuawihqvocglcoss&fileformat=p2p&archiveformat=gz" -O peerblock7.gz
wget "http://list.iblocklist.com/?list=xpbqleszmajjesnzddhv&fileformat=p2p&archiveformat=gz" -O peerblock8.gz
wget "http://list.iblocklist.com/?list=llvtlsjyoyiczbkjsxpf&fileformat=p2p&archiveformat=gz" -O peerblock9.gz
wget "http://list.iblocklist.com/?list=ijfqtofzixtwayqovmxn&fileformat=p2p&archiveformat=gz" -O peerblock10.gz

echo "##################################################################"
echo "Extracting"
echo "##################################################################"

gunzip peerblock*.gz

echo "##################################################################"
echo "Merging lists"
echo "##################################################################"

cat peerblock* >> blocklist.p2p

echo "##################################################################"
echo "Activating DeDuplication Algorithm"
echo "##################################################################"

sort blocklist.p2p | uniq | sort -r > blocklist.new && mv blocklist.new blocklist.p2p

echo "##################################################################"
echo "Finalizing"
echo "##################################################################"

mv blocklist.p2p ~/.config/transmission/blocklists/blocklist.bin

echo "##################################################################"
echo "Cleaning Up"
echo "##################################################################"

rm peerblock*

echo "##################################################################"
echo "Process Complete"
echo "##################################################################"

sleep 2
exit
