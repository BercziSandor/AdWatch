#!/bin/bash
# set -vx
fileToStart=getAutoscout24.at.pl
thisDir=$(dirname $(readlink -f $0))
cd $thisDir
if ps -aef | grep -v grep | grep perl | grep -q "$fileToStart"; then
	echo "$(date) Nothing to do, $fileToStart is already running:" | tee -a $thisDir/watch.log
 	ps -aef | head -1                      | tee -a $thisDir/watch.log
 	ps -aef | grep -v grep | grep perl | grep "$fileToStart" | tee -a $thisDir/watch.log
else
	echo "$(date) $fileToStart is not running, starting it" | tee -a $thisDir/watch.log
	perl ./$fileToStart >> /dev/null & 
fi
