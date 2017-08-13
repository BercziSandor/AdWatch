#!/bin/bash

thisDir=$(dirname $(readlink -f $0))
cd $thisDir
if ! pgrep get.pl >/dev/null; then 
	echo "$(date) get.pl is not running, restart it" | tee -a $thisDir/watch.log
	perl ./get.pl >> ./get.log &
else
	echo "$(date) get.pl is running." | tee -a $thisDir/watch.log
fi


