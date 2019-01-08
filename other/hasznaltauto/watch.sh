#!/bin/bash
# set -vx

thisDir=$(dirname $(readlink -f $0))
cd $thisDir
if ps -aef | grep -v grep | grep perl | grep -q "get.pl"; then 
	echo "$(date) get.pl is running:" | tee -a $thisDir/watch.log
 	ps -aef | head -1                      | tee -a $thisDir/watch.log
 	ps -aef | grep -v grep | grep perl | grep "get.pl" | tee -a $thisDir/watch.log
else
	echo "$(date) get.pl is not running, restart it" | tee -a $thisDir/watch.log
	perl ./get.pl >> ./get.log &
fi


