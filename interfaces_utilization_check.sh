#!/bin/bash
## This script requires ifconfig and ethtool
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin

#interval between samples in seconds:
testTime=10 
#utilization threshold in percentage
threshold=50 

ifconfig | grep -B6 'RX bytes' | grep -E 'Link encap|RX bytes' | paste - - | grep -v lo > stats1.txt
echo "Took first sample. now waiting $testTime seconds before second sample"
sleep $testTime
ifconfig | grep -B6 'RX bytes' | grep -E 'Link encap|RX bytes' | paste - - | grep -v lo > stats2.txt

while read line
do
	iface=`echo $line | awk '{print $1}'`
	speed=`ethtool $iface | grep Speed | grep -oP '\d+'`
	if [ -z "$speed" ]
	then
		continue
	fi
	bandwidth=$((speed*1000*$testTime))
	rx1=`grep $iface stats1.txt | grep -oP 'RX bytes:\d+' | cut -d: -f2`
	tx1=`grep $iface stats1.txt | grep -oP 'TX bytes:\d+' | cut -d: -f2`
	rx2=`grep $iface stats2.txt | grep -oP 'RX bytes:\d+' | cut -d: -f2`
	tx2=`grep $iface stats2.txt | grep -oP 'TX bytes:\d+' | cut -d: -f2`
	rxThroughput=$((($rx2-$rx1)/1000)); txThroughput=$((($tx2-$tx1)/1000))
	rxBandwidthUsage=$(((100*$rxThroughput)/$bandwidth))
	txBandwidthUsage=$(((100*$txThroughput)/$bandwidth))
	echo "Interface $iface - RX throughput $rxThroughput kBps with $rxBandwidthUsage% utilization , TX throughput $txThroughput kBps with $txBandwidthUsage% utilization."
	if [ "$rxBandwidthUsage" -gt "$threshold" ]
	then
		echo "Interface $iface RX bandwidth utilization above $threshold%"
	fi
	if [ "$txBandwidthUsage" -gt "$threshold" ]
	then
		echo "Interface $iface TX bandwidth utilization above $threshold%"
	fi
done < stats1.txt

rm -f stats1.txt stats2.txt
