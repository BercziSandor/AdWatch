#!/bin/bash
set -euo pipefail
set -e

set -vx

# call with user sanyi

git config --global user.email "Berczi.Sandor@gmail.com"
git config --global user.name "Berczi Sándor"

# git clone https://github.com/BercziSandor/hasznaltAutoWatcher.git
# ~/hasznaltAutoWatcher/install/0_install_sw.sh
# curl -L $this -o /tmp/$(basename $this)
# OR bash <(curl -s $this)

if [ "`whoami`" == "root" ]; then
  echo "You must NOT use root for this, aborting."
  exit 1
fi

sudo apt -y update
sudo apt -y upgrade
sudo apt -y autoremove

# SWAP
if [ ! -e /swapfile ]; then
  swapon -s
  free -m
  fallocate -l 4G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  sh -c "echo '/swapfile   none    swap    sw    0   0' >> /etc/fstab"
fi

# system tools
sudo apt -y install gcc make libssl-dev mailutils mc vim htop perl-openssl-defaults zlib1g-dev
timedatectl set-timezone Europe/Budapest

# NOMACHINE
# https://www.vultr.com/docs/setup-nomachine-nx-on-ubuntu
# sudo apt-get install ubuntu-desktop
# sudo dpkg --purge ubuntu-desktop
# sudo apt-get install pulseaudio
# wget http://download.nomachine.com/download/6.4/Linux/nomachine_6.4.6_1_amd64.deb
# sudo dpkg -i nnomachine_6.4.6_1_amd64.deb
# sudo ufw allow 4000/tcp
# sudo ufw allow 4011:4999/udp
# sudo iptables -A INPUT -p tcp --dport 4000 -j ACCEPT
# sudo iptables -A INPUT -p udp --match multiport --dports 4011:4999 -j ACCEPT
################################################################################


# PERL
curl -L https://cpanmin.us | perl - --sudo App::cpanminus
cpanm --sudo install HTTP::CookieJar
cpanm --sudo install HTTP::Date
cpanm --sudo install HTML::TreeBuilder
cpanm --sudo install HTML::TreeBuilder::XPath
cpanm --sudo install HTML::Parser
cpanm --sudo install Log::Log4perl
cpanm --sudo install Log::Dispatch::FileRotate
# cpanm --sudo install Log::Dispatch::File::Rolling
cpanm --sudo install LWP::UserAgent
cpanm --sudo install LWP::Protocol::https
cpanm --sudo install WWW::Mechanize
cpanm --sudo install Email::Sender::Simple
sudo apt install libxml-libxml-perl libxml2-dev
cpanm --sudo install XML::LibXML
################################################################################



sudo apt -y upgrade
