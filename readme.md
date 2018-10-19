Goal of the script: alerting about new ads via email

# History
 - 2018.10.18: mobile.de: meg kell vizsgálni, mennyi idő elkészíteni
 - 2018.10.18: www.willhaben.at KELL - kb 8 óra
 - 2018.10.05: willhaben.at: meg kell vizsgálni, mennyi idő elkészíteni
 - 2018.10.02:
   - Max 6000€
   - Skoda, Seat, Volkswagen, Audi, Hyundai, Citroen, Mazda, Honda, Toyota, Nissan, Opel, Fiat, Ford.
   - 2007-
 - 2018.09.17: szűrő: 2006-; 500-7000€

# TODO, open issues
see [issues https://github.com/BercziSandor/hasznaltAutoWatcher/issues]

# Prerequisits

## System config
### Useful apps
~~~~bash
sudo apt update
sudo apt install mc
sudo apt install vim

~~~~

### User creation
~~~~bash

adduser sanyi
usermod -aG sudo sanyi
su - sanyi
~~~~


### Swap
https://www.digitalocean.com/community/tutorials/how-to-add-swap-on-ubuntu-14-04
~~~~bash
sudo swapon -s
free -m
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo sh -c "echo '/swapfile   none    swap    sw    0   0' >> /etc/fstab"
~~~~

### APT, cpanm, other system configs
~~~~bash
sudo apt update
sudo apt upgrade
sudo apt autoremove
curl -L https://cpanmin.us | perl - --sudo App::cpanminus
sudo apt install gcc make libssl-dev mailutils mc htop
sudo apt install perl-openssl-defaults # 2018.08.22: package not found
sudo dpkg-reconfigure tzdata
~~~~

### Perl packages
~~~~bash
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
~~~~

### Git clone
~~~~bash
cd ~
mkdir -p work
cd work
git clone https://github.com/BercziSandor/hasznaltAutoWatcher.git
cd hasznaltAutoWatcher
./get.pl
~~~~

### Mail configuration
see ~/work/config/mail.sh

### Cron
~~~~bash
# for app user: sanyi
*/10 * * * * cd ~/work/hasznaltAutoWatcher; ./watch.sh
~~~~


# Cloud services
Needed layer: Infrastructure as a Service (IAAS)

Some providers (found [here](http://www.techrepublic.com/blog/10-things/10-iaas-providers-who-provide-free-cloud-resources/))
 - https://aws.amazon.com/free/
 - https://www.datapipe.com/gogrid (100$ free credit)
 - https://www.hpe.com/us/en/solutions/cloud.html (90 days trial)
 - https://azure.microsoft.com/en-us/free/ (30 days trial)
 - https://www.cloudsigma.com/us/ (7 days trial)
 - https://www.elastichosts.com/ (5 days)
 - https://www.koding.com/features
 - https://azure.microsoft.com/en-us/pricing/details/app-service/
 - https://aws.amazon.com/?nc1=h_ls (IAAS)
