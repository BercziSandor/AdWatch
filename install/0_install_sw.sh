#!/bin/bash
set -euo pipefail

# call with root


# install:
this=https://raw.githubusercontent.com/BercziSandor/hasznaltAutoWatcher/master/install/0_install_sw.sh
# git clone https://github.com/BercziSandor/hasznaltAutoWatcher.git
# ~/hasznaltAutoWatcher/install/0_install_sw.sh
# curl -L $this -o /tmp/$(basename $this)
# OR bash <(curl -s $this)


apt update
apt install mc
apt install vim
