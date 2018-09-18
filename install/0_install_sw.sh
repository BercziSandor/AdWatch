#!/bin/bash
set -euo pipefail
set -vx

# call with root


# install:
this=https://raw.githubusercontent.com/BercziSandor/hasznaltAutoWatcher/master/install/0_install_sw.sh
git config --global user.email "Berczi.Sandor@gmail.com"
git config --global user.name "Berczi Sándor"

# git clone https://github.com/BercziSandor/hasznaltAutoWatcher.git
# ~/hasznaltAutoWatcher/install/0_install_sw.sh
# curl -L $this -o /tmp/$(basename $this)
# OR bash <(curl -s $this)


apt -y update > /dev/null
apt -y install mc
apt -y install vim
