#!/bin/bash
# set -vx

thisDir=$(dirname $(readlink -f $0))
cd $thisDir
if ps -aef | grep -v grep | grep -q "get.pl"; then 
	echo "$(date) get.pl is running." | tee -a $thisDir/watch.log
else
	echo "$(date) get.pl is not running, restart it" | tee -a $thisDir/watch.log
	perl ./get.pl >> ./get.log &
fi


