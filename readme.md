Goal of the script: alerting about new ads via email

** TODO **
 -

** Prerequisits **

apt-get install gcc make perl-openssl-defaults libssl-dev

curl -L https://cpanmin.us | perl - --sudo App::cpanminus

cpanm --sudo install HTTP::CookieJar
cpanm --sudo install HTTP::Date
cpanm --sudo install HTML::TreeBuilder
	Hack if not working:
	replace this:
		use lib '.'
	with this:
		use File::Spec;
		use File::Basename;
		use File::Copy;
		use lib dirname( File::Spec->rel2abs(__FILE__) );
	in file Build.PL
	Install:
	perl Build.PL
	./Build
	./Build test
	./Build install

cpanm --sudo install HTML::TreeBuilder::XPath
cpanm --sudo install HTML::Parser
cpanm --sudo install Log::Log4perl
cpanm --sudo install LWP::UserAgent
cpanm --sudo install LWP::Protocol::https
cpanm --sudo install WWW::Mechanize


* Cloud services
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




