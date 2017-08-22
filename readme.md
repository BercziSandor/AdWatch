Goal of the script: alerting about new ads via email

# TODO, open issues
 - fix date 'utolsó állapot'
 - die function: report all failure in mail
 - fix format problems of the mail: the links are sometimes formatted wrong

# Prerequisits

## System config

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
sudo apt install gcc make perl-openssl-defaults libssl-dev mailutils
sudo apt install mc
sudo dpkg-reconfigure tzdata
~~~~

### Perl packages
~~~~bash
cpanm --sudo install HTTP::CookieJar
cpanm --sudo install HTTP::Date
cpanm --sudo install HTML::TreeBuilder
#    Hack if not working:
#    replace in /home/sanyi/.cpanm/work/latest-build/HTML-Tree-5.06/Build.PL this:
#        use lib '.'
#    with this:
#        use File::Spec;
#        use File::Basename;
#        use File::Copy;
#        use lib dirname( File::Spec->rel2abs(__FILE__) );
#
#    Install:
#    perl Build.PL
#    ./Build
#    ./Build test
#    sudo ./Build install

cpanm --sudo install HTML::TreeBuilder::XPath
cpanm --sudo install HTML::Parser
cpanm --sudo install Log::Log4perl
cpanm --sudo install LWP::UserAgent
cpanm --sudo install LWP::Protocol::https
cpanm --sudo install WWW::Mechanize
cpanm --sudo install Email::Sender::Simple
~~~~
### Mail configuration
~~~~bash
#!/bin/bash
# wget https://gist.githubusercontent.com/sshtmc/3952294/raw/7b5b230a04994ab387538b118d7a32dda54eb757/ubuntu-configure-sendmail-with-gmail/ -O- | bash

HOST=$(hostname)
GMAIL_USER=
# Hint: create app password: https://myaccount.google.com/apppasswords
GMAIL_PASS=

if [ -z "$GMAIL_USER" ]; then
    read -p "Gmail username: " GMAIL_USER
fi


if [ -z "$GMAIL_PASS" ]; then
    read -sp "Gmail password: " GMAIL_PASS
fi

function install_postfix() {
echo | sudo debconf-set-selections <<__EOF
postfix postfix/root_address    string
postfix postfix/rfc1035_violation   boolean false
postfix postfix/mydomain_warning    boolean
postfix postfix/mynetworks  string  127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
postfix postfix/mailname    string  $HOST
postfix postfix/tlsmgr_upgrade_warning  boolean
postfix postfix/recipient_delim string  +
postfix postfix/main_mailer_type    select  Internet with smarthost
postfix postfix/destinations    string  $HOST, localhost.localdomain, localhost
postfix postfix/retry_upgrade_warning   boolean
# Install postfix despite an unsupported kernel?
postfix postfix/kernel_version_warning  boolean
postfix postfix/not_configured  error
postfix postfix/sqlite_warning  boolean
postfix postfix/mailbox_limit   string  0
postfix postfix/relayhost   string  [smtp.gmail.com]:587
postfix postfix/procmail    boolean false
postfix postfix/bad_recipient_delimiter error
postfix postfix/protocols   select  all
postfix postfix/chattr  boolean false
__EOF

echo "Postfix should be configured as Internet site with smarthost"
sudo apt-get install -q -y postfix
}

if ! dpkg -s postfix >/dev/null;
then
  install_postfix
else
  echo "Postfix is already installed."
  echo "You may consider removing it before running the script."
  echo "You may do so with the following command:"
  echo "sudo apt-get purge postfix"
  echo
fi


echo # an empty line

if [ -z "$GMAIL_USER" ]; then echo "No gmail username given. Exiting."; exit -1; fi
if [ -z "$GMAIL_PASS" ]; then echo "No gmail password given. Exiting."; exit -1; fi

if ! [ -f /etc/postfix/main.cf.original ]; then
  sudo cp /etc/postfix/main.cf /etc/postfix/main.cf.original
fi

sudo tee /etc/postfix/main.cf >/dev/null <<__EOF
relayhost = [smtp.gmail.com]:587
smtp_use_tls = yes
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_tls_loglevel = 1
smtp_tls_per_site = hash:/etc/postfix/tls_per_site
smtp_tls_CAfile = /etc/ssl/certs/Equifax_Secure_CA.pem
smtp_tls_session_cache_database = btree:/var/lib/postfix/smtp_tls_session_cache
__EOF

echo "[smtp.gmail.com]:587 $GMAIL_USER:$GMAIL_PASS" | sudo tee /etc/postfix/sasl_passwd >/dev/null
sudo chmod 400 /etc/postfix/sasl_passwd
sudo postmap /etc/postfix/sasl_passwd
echo "smtp.gmail.com MUST" | sudo tee /etc/postfix/tls_per_site >/dev/null
sudo chmod 400 /etc/postfix/tls_per_site
sudo postmap /etc/postfix/tls_per_site

sudo service postfix restart
echo "Configuration done"

mail -s "Email relaying configured at ${HOST}" $GMAIL_USER@gmail.com <<__EOF
The postfix service has been configured at host '${HOST}'.
Thank you for using this postfix configuration script.
__EOF

echo "I have sent you a mail to $GMAIL_USER@gmail.com"
echo "This will confirm that the configuration is good."
echo "Please check your inbox at gmail."

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




