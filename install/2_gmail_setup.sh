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

if ! dpkg -s postfix >/dev/null; then
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

# https://www.curvve.com/blog/servers/2013/fixing-postfix-certificate-verification-failed-for-gmail-untrusted-issuer-error-message/
sudo tee /etc/postfix/ssl/Equifax_Secure_CA.pem >/dev/null <<__EOF
-----BEGIN CERTIFICATE-----
MIIDIDCCAomgAwIBAgIENd70zzANBgkqhkiG9w0BAQUFADBOMQswCQYDVQQGEwJVUzEQMA4GA1UE
ChMHRXF1aWZheDEtMCsGA1UECxMkRXF1aWZheCBTZWN1cmUgQ2VydGlmaWNhdGUgQXV0aG9yaXR5
MB4XDTk4MDgyMjE2NDE1MVoXDTE4MDgyMjE2NDE1MVowTjELMAkGA1UEBhMCVVMxEDAOBgNVBAoT
B0VxdWlmYXgxLTArBgNVBAsTJEVxdWlmYXggU2VjdXJlIENlcnRpZmljYXRlIEF1dGhvcml0eTCB
nzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEAwV2xWGcIYu6gmi0fCG2RFGiYCh7+2gRvE4RiIcPR
fM6fBeC4AfBONOziipUEZKzxa1NfBbPLZ4C/QgKO/t0BCezhABRP/PvwDN1Dulsr4R+AcJkVV5MW
8Q+XarfCaCMczE1ZMKxRHjuvK9buY0V7xdlfUNLjUA86iOe/FP3gx7kCAwEAAaOCAQkwggEFMHAG
A1UdHwRpMGcwZaBjoGGkXzBdMQswCQYDVQQGEwJVUzEQMA4GA1UEChMHRXF1aWZheDEtMCsGA1UE
CxMkRXF1aWZheCBTZWN1cmUgQ2VydGlmaWNhdGUgQXV0aG9yaXR5MQ0wCwYDVQQDEwRDUkwxMBoG
A1UdEAQTMBGBDzIwMTgwODIyMTY0MTUxWjALBgNVHQ8EBAMCAQYwHwYDVR0jBBgwFoAUSOZo+SvS
spXXR9gjIBBPM5iQn9QwHQYDVR0OBBYEFEjmaPkr0rKV10fYIyAQTzOYkJ/UMAwGA1UdEwQFMAMB
Af8wGgYJKoZIhvZ9B0EABA0wCxsFVjMuMGMDAgbAMA0GCSqGSIb3DQEBBQUAA4GBAFjOKer89961
zgK5F7WF0bnj4JXMJTENAKaSbn+2kmOeUJXRmm/kEd5jhW6Y7qj/WsjTVbJmcVfewCHrPSqnI0kB
BIZCe/zuf6IWUrVnZ9NA2zsmWLIodz2uFHdh1voqZiegDfqnc1zqcPGUIWVEX/r87yloqaKHee95
70+sB3c4
-----END CERTIFICATE-----
__EOF

cat /etc/postfix/ssl/Equifax_Secure_CA.pem        >> /etc/postfix/ssl/cacert.pem
echo                                              >> /etc/postfix/ssl/cacert.pem

sudo tee /etc/postfix/ssl/Thawte_Premium_Server_CA.pem >/dev/null <<__EOF
-----BEGIN CERTIFICATE-----
MIIDJzCCApCgAwIBAgIBATANBgkqhkiG9w0BAQQFADCBzjELMAkGA1UEBhMCWkExFTATBgNVBAgT
DFdlc3Rlcm4gQ2FwZTESMBAGA1UEBxMJQ2FwZSBUb3duMR0wGwYDVQQKExRUaGF3dGUgQ29uc3Vs
dGluZyBjYzEoMCYGA1UECxMfQ2VydGlmaWNhdGlvbiBTZXJ2aWNlcyBEaXZpc2lvbjEhMB8GA1UE
AxMYVGhhd3RlIFByZW1pdW0gU2VydmVyIENBMSgwJgYJKoZIhvcNAQkBFhlwcmVtaXVtLXNlcnZl
ckB0aGF3dGUuY29tMB4XDTk2MDgwMTAwMDAwMFoXDTIwMTIzMTIzNTk1OVowgc4xCzAJBgNVBAYT
AlpBMRUwEwYDVQQIEwxXZXN0ZXJuIENhcGUxEjAQBgNVBAcTCUNhcGUgVG93bjEdMBsGA1UEChMU
VGhhd3RlIENvbnN1bHRpbmcgY2MxKDAmBgNVBAsTH0NlcnRpZmljYXRpb24gU2VydmljZXMgRGl2
aXNpb24xITAfBgNVBAMTGFRoYXd0ZSBQcmVtaXVtIFNlcnZlciBDQTEoMCYGCSqGSIb3DQEJARYZ
cHJlbWl1bS1zZXJ2ZXJAdGhhd3RlLmNvbTCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEA0jY2
aovXwlue2oFBYo847kkEVdbQ7xwblRZH7xhINTpS9CtqBo87L+pW46+GjZ4X9560ZXUCTe/LCaIh
Udib0GfQug2SBhRz1JPLlyoAnFxODLz6FVL88kRu2hFKbgifLy3j+ao6hnO2RlNYyIkFvYMRuHM/
qgeN9EJN50CdHDcCAwEAAaMTMBEwDwYDVR0TAQH/BAUwAwEB/zANBgkqhkiG9w0BAQQFAAOBgQAm
SCwWwlj66BZ0DKqqX1Q/8tfJeGBeXm43YyJ3Nn6yF8Q0ufUIhfzJATj/Tb7yFkJD57taRvvBxhEf
8UqwKEbJw8RCfbz6q1lu1bdRiBHjpIUZa4JMpAwSremkrj/xw0llmozFyD4lt5SZu5IycQfwhl7t
UCemDaYj+bvLpgcUQg==
-----END CERTIFICATE-----
__EOF

cat /etc/postfix/ssl/Thawte_Premium_Server_CA.pem >> /etc/postfix/ssl/cacert.pem

sudo tee /etc/postfix/main.cf >/dev/null <<__EOF
relayhost = [smtp.gmail.com]:587
smtp_use_tls = yes
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_tls_loglevel = 1
smtp_tls_per_site = hash:/etc/postfix/tls_per_site
smtp_tls_CAfile = /etc/postfix/ssl/cacert.pem
smtp_tls_CApath = /etc/postfix/ssl
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
