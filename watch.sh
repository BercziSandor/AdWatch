#!/bin/bash
# set -vx
fileToStart=adWatch.pl
[ -e $fileToStart ] || { echo "$fileToStart does not exist, aborting."; exit 1; }

thisDir=$(dirname $(readlink -f $0))
cd $thisDir

function watchFor
{
	site=$1
	shift
	if [ "$1" == "stop" ]; then
		if ps -aef | grep -v grep | grep perl | grep "$fileToStart" | grep -q "s $site" ; then
			pid=$(ps -aef | grep -v grep | grep perl | grep "$fileToStart" | grep -q "s $site" | awk '{print $2}')
			if [ ! -z $pid ]; then
				kill -9 $pid
			fi
		fi
	else
		if ps -aef | grep -v grep | grep perl | grep "$fileToStart" | grep -q "s $site" ; then
			echo "$(date) Nothing to do, $fileToStart for $site is already running:" | tee -a $thisDir/watch.log
		 	 ps -aef | head -1                      | tee -a $thisDir/watch.log
		 	 ps -aef | grep -v grep | grep perl | grep "$fileToStart" | grep -q "s $site" | tee -a $thisDir/watch.log
		else
			echo "$(date) $fileToStart does not run for $site, starting it" | tee -a $thisDir/watch.log
			set -vx
			perl ./$fileToStart -s $site $* 2>> ${site}.err.log 1> /dev/null &
			set +vx
		fi
	fi
}
watchFor willHaben $*
watchFor autoScout24 $*
