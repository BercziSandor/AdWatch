#!/bin/bash
# set -vx
fileToStart=adWatch.pl
[ -e $fileToStart ] || { echo "$fileToStart does not exist, aborting."; exit 1; }

thisDir=$(dirname $(readlink -f $0))
cd $thisDir

function watchFor
{
	site=$1
	if ps -aef | grep -v grep | grep perl | grep "$fileToStart" | grep -q "s $site" ; then
		echo "$(date) Nothing to do, $fileToStart for $site is already running:" | tee -a $thisDir/watch.log
	 	 ps -aef | head -1                      | tee -a $thisDir/watch.log
	 	 ps -aef | grep -v grep | grep perl | grep "$fileToStart" | grep -q "s $site" | tee -a $thisDir/watch.log
	else
		echo "$(date) $fileToStart isn't running for $site, starting it" | tee -a $thisDir/watch.log
		perl ./$fileToStart -s $site >> /dev/null &
	fi
}

watchFor willHaben
sleep 15
watchFor autoScout24
