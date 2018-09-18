#!/bin/bash
# set -vx

thisDir=$(dirname $(readlink -f $0))
cd $thisDir
if ps -aef | grep -v grep | grep perl | grep -q "getAutoscout24.at.pl"; then
	echo "$(date) getAutoscout24.at.pl is running:" | tee -a $thisDir/watch.log
 	ps -aef | head -1                      | tee -a $thisDir/watch.log
 	ps -aef | grep -v grep | grep perl | grep "getAutoscout24.at.pl" | tee -a $thisDir/watch.log
else
	echo "$(date) getAutoscout24.at.pl is not running, restart it" | tee -a $thisDir/watch.log
	perl ./getAutoscout24.at.pl >> ./getAutoscout24.at.log &
fi
