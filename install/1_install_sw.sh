#!/bin/bash
set -euo pipefail
set -vx

# call with user sanyi


# install:
this=https://raw.githubusercontent.com/BercziSandor/hasznaltAutoWatcher/master/install/0_install_sw.sh
git config --global user.email "Berczi.Sandor@gmail.com"
git config --global user.name "Berczi Sándor"

# git clone https://github.com/BercziSandor/hasznaltAutoWatcher.git
# ~/hasznaltAutoWatcher/install/0_install_sw.sh
# curl -L $this -o /tmp/$(basename $this)
# OR bash <(curl -s $this)


apt -y update
apt -y upgrade
apt -y autoremove

# SWAP
if [ ! -e ~/install_OK_swap ]; then
  swapon -s
  free -m
  fallocate -l 4G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  sh -c "echo '/swapfile   none    swap    sw    0   0' >> /etc/fstab"
  touch ~/install_OK_swap
fi

# system tools
apt -y install gcc make libssl-dev mailutils mc vim htop
apt -y install perl-openssl-defaults
timedatectl set-timezone Europe/Budapest

# PERL
curl -L https://cpanmin.us | perl - --sudo App::cpanminus
cpanm --sudo install HTTP::CookieJar
cpanm --sudo install HTTP::Date
cpanm --sudo install HTML::TreeBuilder
cpanm --sudo install HTML::TreeBuilder::XPath
cpanm --sudo install HTML::Parser
cpanm --sudo install Log::Log4perl
cpanm --sudo install LWP::UserAgent
cpanm --sudo install LWP::Protocol::https
cpanm --sudo install WWW::Mechanize
cpanm --sudo install Email::Sender::Simple
