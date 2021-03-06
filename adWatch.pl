#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use Data::Dumper;
use Data::Dump;
$Data::Dumper::Sortkeys = 1;
use Log::Log4perl;

# use Log::Dispatch::File::Rolling;

use FindBin;
use lib "$FindBin::Bin/lib";

# Http engines
use HTTP::Tiny;
use WWW::Mechanize;
use LWP::UserAgent;
use LWP::Protocol::https;

use Getopt::Long;

# Cookie stuff
use HTTP::Cookies;
use HTTP::CookieJar;
use HTTP::CookieJar::LWP;

# http://search.cpan.org/~mirod/HTML-TreeBuilder-XPath-0.14/lib/HTML/TreeBuilder/XPath.pm
use XML::LibXML;
use MIME::Base64;

# use utf8;
use Text::Unidecode;
use Encode;

use List::Util qw[min max];
use Storable;
use Time::HiRes qw( time );

# use POSIX;
use POSIX qw(strftime);
use File::Basename;
use Cwd 'abs_path';

use Email::Sender::Simple qw(sendmail);
use Email::Simple::Creator;

require stopWatch;

our $SITE_WILLHABEN   = 'willHaben';
our $SITE_AUTOSCOUT24 = 'autoScout24';

our $thisYear;

# my $urls;

my $SW_DOWNLOAD        = 'Letoltes';
my $SW_FULL_PROCESSING = 'Teljes futás';
my $SW_PROCESSING      = 'Feldolgozás';

# variables from config file
our $G_DATA;

my $OPTION_OFFLINE       = 0;
my $OPTION_SAVEHTMLFILES = 0;
my $OPTION_NO_LOOP       = 0;
my $DEBUG                = 0;

my $dataFileDate;
my $G_ITEMS_IN_DB;
my $G_HTML_TREE;
my $g_stopWatch;
my $G_ITEMS_PROCESSED = 0;
my $G_ITEMS_PER_PAGE  = 20;    # default:10 max:100
my $G_LAST_GET_TIME   = 0;
our $log;
my $httpEngine;
my $collectionDate;
my $SCRIPTDIR;

our $makerString;

my $G_ITEMS_TO_PROCESS_MAX     = 0;    # 0: unlimited
my $G_WAIT_BETWEEN_GETS_IN_SEC = 1;

our ( $SITE, $QUIET, $VERBOSE, $HELP, ) = ( $SITE_WILLHABEN, undef, 0, undef );

# CONSTANTS
my ( $STATUS_EMPTY, $STATUS_CHANGED, $STATUS_NEW, $STATUS_VERKAUFT ) = ( 'undef', 'megváltozott', 'új', 'eladva' );

sub get_SearchInfo {
  $G_DATA->{searchInfo} = "A keresés feltételei:\n";
  $G_DATA->{searchInfo} .= " Oldal: $SITE\n";

  my @ts;

  # $log->info("makerString: $makerString\n");
  # print Dumper( $G_DATA->{sites} );
  foreach my $t ( sort keys %{ $G_DATA->{sites}->{$SITE}->{searchConfig}->{$makerString} } ) {
    next if ( not defined( $G_DATA->{sites}->{$SITE}->{searchConfig}->{$makerString}->{$t}->{maxAge} ) );
    push( @ts, $t );
  }
  $G_DATA->{searchInfo} .= " Típusok: " . join( ', ', @ts ) . "\n";

  $G_DATA->{searchInfo}
    .= " Évjárat: " . ( $thisYear - $G_DATA->{searchDefaults}->{maxAge} ) . " - " . $thisYear . " (max. $G_DATA->{searchDefaults}->{maxAge} év)\n";
  $G_DATA->{searchInfo} .= " Ár: $G_DATA->{searchDefaults}->{price_from} - $G_DATA->{searchDefaults}->{price_to} €\n";
  return $G_DATA->{searchInfo};

} ### sub get_SearchInfo

sub ini {
  $SCRIPTDIR = dirname( abs_path($0) );
  $thisYear = strftime "%Y", localtime;

  # Reading Parameters
  GetOptions(
    'site|s=s'  => \$SITE,
    'noLoop|nl' => \$OPTION_NO_LOOP,
    'help|?|h'  => \$HELP,
    'verbose|v' => \$VERBOSE,
  );
  die "ERROR: Invalid site: [$SITE]\n Valid sites are: [$SITE_WILLHABEN], [$SITE_AUTOSCOUT24]\n"
    if ( $SITE ne $SITE_WILLHABEN and $SITE ne $SITE_AUTOSCOUT24 );

  $DEBUG                = 1 if $VERBOSE;
  $OPTION_SAVEHTMLFILES = 1 if $VERBOSE;

  # Logging
  # http://ddiguru.com/blog/126-eight-loglog4perl-recipes
  my $logConf = q(
            log4perl.rootLogger                                 = DEBUG, Logfile, Screen

            log4perl.appender.Logfile                           = Log::Dispatch::FileRotate
            log4perl.appender.Logfile.filename                  = AutoScout24.log
            log4perl.appender.Logfile.mode                      = append
            log4perl.appender.Logfile.autoflush                 = 1
            log4perl.appender.Logfile.size                      = 10485760
            log4perl.appender.Logfile.max                       = 5
            log4perl.appender.Logfile.layout                    = Log::Log4perl::Layout::PatternLayout
            log4perl.appender.Logfile.layout.ConversionPattern  = %d %r [%-5p] %F %4L - %m%n
            log4perl.appender.Logfile.Threshold                 = DEBUG

            log4perl.appender.Screen                            = Log::Log4perl::Appender::Screen
            log4perl.appender.Screen.stderr                     = 0
            log4perl.appender.Screen.layout                     = Log::Log4perl::Layout::PatternLayout
            log4perl.appender.Screen.layout.ConversionPattern   = %m
            log4perl.appender.Screen.Threshold                  = DEBUG
          );

  Log::Log4perl::init( \$logConf );
  $log = Log::Log4perl->get_logger();
  if ($VERBOSE) {
    print "VERBOSE mode on.\n";
    $Log::Log4perl::Logger::APPENDER_BY_NAME{'Logfile'}->threshold('DEBUG');
    $Log::Log4perl::Logger::APPENDER_BY_NAME{'Screen'}->threshold('INFO');
  } else {
    print "VERBOSE mode off.\n";
    $Log::Log4perl::Logger::APPENDER_BY_NAME{'Logfile'}->threshold('INFO');
    $Log::Log4perl::Logger::APPENDER_BY_NAME{'Screen'}->threshold('INFO');
  }

  $log->info("ini(): entering\n");
  $log->info("ini(): site: $SITE\n");
  $log->info( "ini(): noLoop: " . ( $OPTION_NO_LOOP ? 'ON' : 'OFF' ) . "\n" );

  if ( !-e "$SCRIPTDIR/mails" )     { `mkdir $SCRIPTDIR/mails` }
  if ( !-e "$SCRIPTDIR/work/html" ) { `mkdir -p $SCRIPTDIR/work/html` }

  # $G_HTML_TREE = HTML::TreeBuilder::XPath->new;

  my ( $name, $path, $suffix ) = fileparse( $0, qr{\.[^.]*$} );

  dataLoad();
  $log->info("ini(): dataLoad ok\n");

  my $cnfFile = "${path}${name}.cfg.pl";
  unless ( my $return = require $cnfFile ) {
    die "'$cnfFile' does not exist, aborting.\n" if ( not -e $cnfFile );
    die "couldn't parse $cnfFile: $@\n" if $@;
    die "couldn't include $cnfFile: $!\n" unless defined $return;
    die "couldn't run $cnfFile\n" unless $return;
  } ### unless ( my $return = require...)
  $log->info("ini(): cfg read\n");
  if ($DEBUG) {
    $G_DATA->{G_WAIT_BETWEEN_FULL_PROCESS_IN_SEC} = 100;
    $G_DATA->{sendMail}                           = 1;
    $G_DATA->{mailRecipients}                     = [ '"Sanyi" <berczi.sandor@gmail.com>' ];
    my $default_price_from = 550;
    my $default_price_to   = 7000;

    # $G_DATA->{sites}->{willHaben}->{searchConfig}->{defaults}->{PRICE_FROM}  = $default_price_from;
    # $G_DATA->{sites}->{willHaben}->{searchConfig}->{defaults}->{PRICE_TO}    = $default_price_to;
    # $G_DATA->{sites}->{autoScout24}->{searchConfig}->{defaults}->{pricefrom} = $default_price_from;
    # $G_DATA->{sites}->{autoScout24}->{searchConfig}->{defaults}->{priceto}   = $default_price_to;
  } ### if ($DEBUG)
  $log->info( get_SearchInfo() . "\n" );
  $log->info( "ini(): G_DATA: " . Dumper( $G_DATA->{sites}->{$SITE} ) );

  # Checking config
  if ( not defined $G_DATA->{CONSTANTS}->{DOWNLOADMETHODS}
    or not defined $G_DATA->{mail}->{sendMail}
    or not defined $G_DATA->{mailRecipients}
    or not defined $G_DATA->{downloadMethod} ) {
    die "G_DATA is not ok, aborting\n";
  } ### if ( not defined $G_DATA...)

  if ( not defined $G_DATA->{sites}->{$SITE}->{searchConfig}->{defaults}->{page} ) {
    $log->info( $SITE . "\n" );
    $log->info( Dumper( $G_DATA->{sites}->{$SITE}->{searchConfig}->{defaults} ) . "\n" );
    $log->logdie("A G_DATA->{sites}->{$SITE}->{searchConfig}->{defaults}->{page} nincs definiálva.\n");
  }
  if ( not defined $G_DATA->{sites}->{$SITE}->{XPATHS} ) {
    $log->logdie("A G_DATA->{sites}->{$SITE}->{XPATHS} nincs definiálva.\n");
  }


  $dataFileDate = $G_DATA->{lastChange} ? ( strftime( "%Y.%m.%d %H:%M", localtime( $G_DATA->{lastChange} ) ) ) : "";
  my $cmd = "ps -aef | grep -v grep | grep ${name}.pl | grep ' $SITE' | wc -l";
  my $cnt = `$cmd`;
  if ( $cnt > 1 ) {
    die "Már fut másik $name folyamat '$SITE'-re, ez leállítva.\n";
  } else {
    $log->info("ini(): nincs másik futó folyamat - OK\n");
  }

  my $cookieJar_HttpCookieJar    = HTTP::CookieJar->new;
  my $cookieJar_HttpCookieJarLWP = HTTP::CookieJar::LWP->new;
  my $agent = 'Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36';

  # Specific code
  getUrls();

  if ( "$SITE" eq "hasznaltauto.hu" ) {
    $cookieJar_HttpCookieJar->add( "http://hasznaltauto.hu", "visitor_telepules=3148 Path=/; Domain=.hasznaltauto.hu" )
      or die "$!";
    $cookieJar_HttpCookieJarLWP->add( "http://hasznaltauto.hu", "visitor_telepules=3148 Path=/; Domain=.hasznaltauto.hu" )
      or die "$!";
  } ### if ( "$SITE" eq "hasznaltauto.hu")

  # Generic
  $G_ITEMS_IN_DB = ( $G_DATA->{ads}->{$SITE} ? scalar( keys %{ $G_DATA->{ads}->{$SITE} } ) : 0 );
  if ($G_DATA) {

    # $log->debug( Dumper($G_DATA) );
  }

  $log->info( "Ini: Eddig beolvasott hirdetések száma: " . $G_ITEMS_IN_DB . "\n" );

  $log->info("Ini: Http motor: $G_DATA->{downloadMethod}\n");
  if ( $G_DATA->{downloadMethod} eq $G_DATA->{CONSTANTS}->{DOWNLOADMETHODS}->{httpTiny} ) {
    $httpEngine = HTTP::Tiny->new(
      timeout    => 30,
      cookie_jar => $cookieJar_HttpCookieJar,
      agent      => $agent
    ) or $log->logdie($!);
  } elsif ( $G_DATA->{downloadMethod} eq $G_DATA->{CONSTANTS}->{DOWNLOADMETHODS}->{lwp} ) {
    $httpEngine = LWP::UserAgent->new(
      timeout    => 30,
      cookie_jar => $cookieJar_HttpCookieJarLWP,
      agent      => $agent
    ) or $log->logdie("zzz: $!");
  } elsif ( $G_DATA->{downloadMethod} eq $G_DATA->{CONSTANTS}->{DOWNLOADMETHODS}->{wwwMech} ) {
    $httpEngine = WWW::Mechanize->new(
      timeout    => 30,
      cookie_jar => $cookieJar_HttpCookieJarLWP,
      agent      => $agent
    );
  } else {
    $log->logdie("TODO: Please implement this html engine");
  }

  $log->info("ini(): returning\n");
} ### sub ini

sub getUrls {

  $log->info("getUrls(): entering\n");
  die "Run ini() before getUrls, aborting.\n" if ( not defined $thisYear );

  $log->info("getUrls -> [${SITE}] - [$SITE_AUTOSCOUT24]\n");
  if ( $SITE eq $SITE_AUTOSCOUT24 ) {
    $log->info( "getUrls(): 1: $makerString: " . Dumper( $G_DATA->{sites}->{$SITE} ) );

    # $G_DATA->{sites}->{autoScout24}->{searchConfig}->{$makerString}
    foreach my $maker ( sort keys %{ $G_DATA->{sites}->{$SITE}->{searchConfig}->{$makerString} } ) {
      $log->info("maker: [$maker]\n");
      my $out = "https://www.autoscout24.at/ergebnisse?";

      # $log->info( Dumper( $G_DATA ) );
      $out .= "$makerString=" . $G_DATA->{sites}->{$SITE}->{makers}->{$maker};

      # $log->info( "out=$out\n" );

      if ( not defined $G_DATA->{sites}->{$SITE}->{searchConfig}->{$makerString}->{$maker}->{maxAge} ) {
        $log->logdie( $G_DATA->{sites}->{$SITE}->{searchConfig}->{$makerString}->{$maker}->{maxAge} . " is not defined. Aborting." );
      }
      $out .= "&fregfrom=" . ( $thisYear - ( $G_DATA->{sites}->{$SITE}->{searchConfig}->{$makerString}->{$maker}->{maxAge} ) );

      # $log->info( "out=$out\n" );

      foreach my $k ( sort keys %{ $G_DATA->{sites}->{$SITE}->{searchConfig}->{defaults} } ) {
        my $val;
        $log->debug("Default: $k\n");
        if ( defined $G_DATA->{sites}->{$SITE}->{searchConfig}->{$makerString}->{$maker}->{$k} ) {
          $val = $G_DATA->{sites}->{$SITE}->{searchConfig}->{$makerString}->{$maker}->{$k};
        } else {
          $val = $G_DATA->{sites}->{$SITE}->{searchConfig}->{defaults}->{$k};
        }
        if ( index( $val, ',' ) > 0 ) {
          my @vals = split( ',', $val );
          foreach my $v (@vals) {
            $out .= "&$k=$v";
            $log->debug("out=[$out]\n");
          }
        } else {
          $out .= "&$k=$val";
          $log->debug("out=[$out]\n");
        }
      } ### foreach my $k ( sort keys %...)

      $log->debug( "\$G_DATA->{sites}->{$SITE}->{urls}->{" . $maker . "}=" . $out . "\n" );
      $G_DATA->{sites}->{$SITE}->{urls}->{$maker} = $out;
    } ### foreach my $maker ( sort keys...)

  } elsif ( $SITE eq $SITE_WILLHABEN ) {

    my $makerString = 'CAR_MODEL/MAKE';
    foreach my $maker ( sort keys %{ $G_DATA->{sites}->{$SITE}->{searchConfig}->{$makerString} } ) {
      $log->info("maker: [$maker]\n");
      next if ( not defined $G_DATA->{sites}->{$SITE}->{searchConfig}->{$makerString}->{$maker}->{maxAge} );
      my $out = $G_DATA->{sites}->{$SITE}->{searchUrlRoot};

      # $log->debug( Dumper( $G_DATA ) );
      die "Define G_DATA->{$SITE}->{makers}->{$maker}, it isn't, aborting." if not defined $G_DATA->{sites}->{$SITE}->{makers}->{$maker};
      $out .= "$makerString=" . $G_DATA->{sites}->{$SITE}->{makers}->{$maker};

      $out .= "&YEAR_MODEL_FROM=" . ( $thisYear - ( $G_DATA->{sites}->{$SITE}->{searchConfig}->{$makerString}->{$maker}->{maxAge} ) );

      # $log->info( "out=$out\n" );

      foreach my $k ( sort keys %{ $G_DATA->{sites}->{$SITE}->{searchConfig}->{defaults} } ) {
        my $val;
        $log->debug("Default: $k\n");
        if ( defined $G_DATA->{sites}->{$SITE}->{searchConfig}->{$makerString}->{$maker}->{$k} ) {
          $val = $G_DATA->{sites}->{$SITE}->{searchConfig}->{$makerString}->{$maker}->{$k};
        } else {
          $val = $G_DATA->{sites}->{$SITE}->{searchConfig}->{defaults}->{$k};
        }
        if ( index( $val, ',' ) > 0 ) {
          my @vals = split( ',', $val );
          foreach my $v (@vals) {
            $out .= "&$k=$v";
          }
        } else {
          $out .= "&$k=$val";
        }
      } ### foreach my $k ( sort keys %...)

      # $log->debug( "\$G_DATA->{sites}->{$SITE}->{urls}->{" . $maker . "}=" . $out . "\n" );
      $G_DATA->{sites}->{$SITE}->{urls}->{$maker} = $out;
    } ### foreach my $maker ( sort keys...)
  } ### elsif ( $SITE eq $SITE_WILLHABEN)

  # $log->debug( Dumper( $G_DATA->{sites}->{$SITE}->{urls} ) );

} ### sub getUrls

sub getHtml {
  my ( $url, $page, $maker ) = @_;
  $page = 1 if not defined $page;

  # $G_HTML_TREE->delete() if defined $G_HTML_TREE;
  $G_HTML_TREE = undef;

  $url =~ s/$G_DATA->{sites}->{$SITE}->{searchConfig}->{defaults}->{page}/$page/g;
  $log->debug("getHtml($url, $page, $maker)\n");

  my $html    = '';
  my $content = '';

  # Specific code
  if ( $url !~ m|$SITE|i ) {
    $log->logdie("Mi ez az url?? [$url]");
  }

  # Generic code
  # $log->debug(" reading remote\n");
  stopWatch::continue($SW_DOWNLOAD);
  my $wtime = int( ( $G_LAST_GET_TIME + $G_WAIT_BETWEEN_GETS_IN_SEC ) - time );

  # $log->debug("getHtml() #2\n");
  if ( $wtime > 0 ) {

    # $log->debug("getHtml() #2.1\n");
    $log->debug("$wtime másodperc várakozás (két lekérés közötti minimális várakozási idö: $G_WAIT_BETWEEN_GETS_IN_SEC másodperc)\n");

    # $log->debug("getHtml() #2.2\n");
    sleep($wtime);
  } ### if ( $wtime > 0 )

  # $log->debug("getHtml() #2.5\n");
  $G_LAST_GET_TIME = time;
  if ( $G_DATA->{downloadMethod} eq 'httpTiny' ) {
    my $response = $httpEngine->get($url);
    if ( $response->{success} ) {
      $html    = $response->{content};
      $content = decode_utf8($html);
    } else {
      $log->logdie( "Error getting url '$url': "
          . "Status: "
          . ( $response->{status} ? $response->{status} : " ? " ) . ", "
          . "Reasons: "
          . ( $response->{reasons} ? $response->{reasons} : " ? " )
          . "(599: timeout, too big response etc.)" );
      die();
    } ### else [ if ( $response->{success...})]
  } elsif ( $G_DATA->{downloadMethod} eq $G_DATA->{CONSTANTS}->{DOWNLOADMETHODS}->{lwp} ) {
    my $response = $httpEngine->get($url);
    if ( $response->is_success ) {
      $html = $response->content;
    } else {
      $log->logdie( $response->status_line );
    }
  } elsif ( $G_DATA->{downloadMethod} eq $G_DATA->{CONSTANTS}->{DOWNLOADMETHODS}->{wwwMech} ) {
    my $response = $httpEngine->get($url);
    if ( $httpEngine->success() ) {
      $html    = $httpEngine->content();
      $content = $html;
    } else {

      # $log->info( "ajjjjaj: httpEngine error: " . $httpEngine->status() . "\n" );    #$httpEngine->status()
      $G_HTML_TREE = undef;
      stopWatch::pause($SW_DOWNLOAD);
      return;
    } ### else [ if ( $httpEngine->success...)]
  } else {
    $log->logdie("The value of $G_DATA->{iable g_downlo}adMethod is not ok, aborting");
  }

  stopWatch::pause($SW_DOWNLOAD);

  # $log->debug("getHtml() #3\n");

  if ( $OPTION_SAVEHTMLFILES or $VERBOSE ) {
    my $fileName = $url;
    $fileName = "$SCRIPTDIR/work/html/" . u_formatTimeNow_YMD_HMS() . ".${SITE}.${maker}.${page}.html";

    # $log->debug("fileName: $fileName\n");
    open( MYFILE, ">$fileName" ) or die "$fileName: $!";
    print MYFILE encode_utf8($html);
    close(MYFILE);
  } ### if ( $OPTION_SAVEHTMLFILES...)

  $log->logdie("The content of the received html is empty.") if ( length($html) == 0 );

  # $log->debug("getHtml() #4 cleanup\n");
  Encode::_utf8_off($content);
  $content = decode_utf8($content);

  # $log->debug("getHtml() #5\n");

  $content = u_utf8Decode($content);

  my $dom = XML::LibXML->load_html(
    string          => $content,
    recover         => 1,
    suppress_errors => 1,
  );
  $G_HTML_TREE = 'XML::LibXML::XPathContext'->new($dom);

  # $G_HTML_TREE = HTML::TreeBuilder::XPath->new_from_content($content) or logdie($!);
  # $log->debug(" \$G_HTML_TREE created.\n");
  $log->debug("getHtml returning\n");
  return $html;
} ### sub getHtml

sub parsePageCount {
  $log->debug("parsePageCount(): entering");

  my $count = undef;
  $log->logDie("Error: G_HTML_TREE is not defined.") unless $G_HTML_TREE;

  # <span class="cl-header-results-counter">2.773</span>

  my $value;

# $value = $G_HTML_TREE->findvalue('//span[@id="resultscounter"]') or return 1;    #  @title="Utolsó oldal"
# $value = $G_HTML_TREE->findvalue('//li[@class="next-page"]/preceding-sibling::li[1]/a/@href') or die "Check last html file."; #return 1;    #  @title="Utolsó oldal"
  $value = $G_HTML_TREE->findvalue('//span[@class=" cl-filters-summary-counter"]');

  $value =~ s/\D//g;
  $value =~ s/\.//g;
  $log->info("parsePageCount: [$value]\n");

  my $max = ceil( $value / $G_ITEMS_PER_PAGE ) or $log->logdie("$!: $value");
  if ( $G_ITEMS_TO_PROCESS_MAX > 0 ) {
    my $maxPagesToProcess = ceil( $G_ITEMS_TO_PROCESS_MAX / $G_ITEMS_PER_PAGE );

    if ( $maxPagesToProcess < $max ) {
      $log->info(" Figyelem: a beállítások miatt a $max oldal helyett csak $maxPagesToProcess kerül feldolgozásra.\n");
    }
    $max = $maxPagesToProcess;
  } ### if ( $G_ITEMS_TO_PROCESS_MAX...)

  $log->debug("Feldolgozandó oldalak száma: $max\n");

  # $log->info( " $max oldal elemeit dolgozom fel, oldalanként maximum $G_ITEMS_PER_PAGE elemmel.\n" );

  return $max;

} ### sub parsePageCount

sub parseItems {

  # my ($html) = @_;
  $log->debug("parseItems(): entering\n");
  stopWatch::continue($SW_PROCESSING);

  my $items;
  my $xpath;
  $xpath = $G_DATA->{sites}->{$SITE}->{XPATHS}->{XPATH_TALALATI_LISTA};
  $log->fatal("Üres: G_DATA->{sites}->{$SITE}->{XPATHS}->{XPATH_TALALATI_LISTA}\n") unless $xpath;

  $items = $G_HTML_TREE->findnodes($xpath) or do {

    # $log->error("ERROR: findnodes($xpath) error\n");
    return 0;
  };
  unless ($items) {
    $log->debug("findnodes($xpath): no items?\n");
    return 0;
  }
  $log->debug( scalar( $items->get_nodelist ) . " lista elemet találtam a következő xpath-al: [$xpath]\n" );

  print "[";
  my $index;
  foreach my $item ( $items->get_nodelist ) {
    $index++;
    $xpath = $G_DATA->{sites}->{$SITE}->{XPATHS}->{XPATH_TITLE};
    $log->fatal("Üres: G_DATA->{sites}->{$SITE}->{XPATHS}->{XPATH_TITLE}\n") unless $xpath;
    my $title = $item->findvalue($xpath);
    $title = u_cleanString($title);

    if ( $G_DATA->{sites}->{$SITE}->{XPATHS}->{XPATH_TITLE2} ) {
      $xpath = $G_DATA->{sites}->{$SITE}->{XPATHS}->{XPATH_TITLE2};
      my $title2 = $item->findvalue($xpath) if $xpath;
      $title .= " - " . $title2 if $title2;
    }

    unless ($title) {
      $log->error( "Title is empty for #${index} - is xpath [" . $G_DATA->{sites}->{$SITE}->{XPATHS}->{XPATH_TITLE} . "] wrong?\n" );

      # die;
      next;
    } ### unless ($title)
    $title = encode_utf8($title);
    $G_ITEMS_PROCESSED++;

    $xpath = $G_DATA->{sites}->{$SITE}->{XPATHS}->{XPATH_LINK};
    $log->fatal("Üres: G_DATA->{sites}->{$SITE}->{XPATHS}->{XPATH_LINK}\n") unless $xpath;
    my $link = $item->findvalue($xpath);
    unless ($link) {
      $log->fatal("Link is empty for #${index}\n");
    }

    my $id;
    if ( $SITE eq $SITE_AUTOSCOUT24 ) {
      $link = "https://www.autoscout24.at${link}";
      $id   = $link;
      $id =~ s/^.*-(.{36})$/$1/g;
    } elsif ( $SITE eq $SITE_WILLHABEN ) {
      $link = "https://www.willhaben.at${link}";
      $id   = $link;

      # https://www.willhaben.at/iad/gebrauchtwagen/d/auto/citroen-c4-1-6-16v-vti-275306032/
      $id =~ s/^.*\/(.*)\/$/$1/;
    } ### elsif ( $SITE eq $SITE_WILLHABEN)

    $xpath = $G_DATA->{sites}->{$SITE}->{XPATHS}->{XPATH_DESC};
    $log->fatal("Üres: G_DATA->{sites}->{$SITE}->{XPATHS}->{XPATH_DESC}\n") unless $xpath;
    my $desc = $item->findvalue($xpath);
    if ($desc) {
      $desc = u_cleanString($desc);
      $desc =~ s/bleifrei//g;
    } else {
      $log->debug("Üres: desc ($xpath)\n");
    }

    # $log->debug("desc:  [$xpath]: [$desc]\n");

    my $priceStr;
    if ( $SITE eq $SITE_WILLHABEN ) {
      $xpath = './section[contains(@class, "content-section")]/div[@class="info"]/script';
      my $script = u_cleanString( $item->findvalue($xpath) );

      # ('DQogICAgICAgICAgICAgICAgPHNwYW4gY2xhc3M9InB1bGwtcmlnaHQiPiA1NTAsLSA8L3NwYW4+DQogICAgICAgICAgICA=')
      $script =~ s/.*'(.*=)'\).*/$1/;
      $script = MIME::Base64::decode_base64($script);

      # <span class="pull-right"> 550,- </span>
      $script =~ s/.*>(.*)<.*/$1/;
      $priceStr = u_cleanString($script);
    } else {
      $xpath    = $G_DATA->{sites}->{$SITE}->{XPATHS}->{XPATH_PRICE};
      $priceStr = u_cleanString( $item->findvalue($xpath) );
    }

    $priceStr =~ s/,-/ €/;
    $priceStr =~ s/EUR //;
    $priceStr = "?" unless $priceStr;
    my $priceNr = $priceStr;
    $priceNr =~ s/\D//g;
    $priceNr = 0 unless $priceNr;

    my @fs;
    if ( $SITE eq $SITE_WILLHABEN ) {

      # '
      #         340.000 kW (462.060 PS)
      #  Diesel
      #  Limousine
      #     '

      # 2008 75.000 km
      my $yearKm = u_cleanString( $item->findvalue('./section[contains(@class, "content-section")]//span[@class="desc-left"]') );
      my $year   = $yearKm;
      $year =~ s/^(\d*) .*/$1/;
      my $age = $thisYear - $year;
      my $km  = $yearKm;
      $km =~ s/^\d* (.*)/$1/;

      push( @fs, "$year($age)" );
      push( @fs, "$km" );

      if ($desc) {
        $desc =~ s/[ ]+/ /g;
        $desc =~ s/^[ ]//g;
        $desc =~ s/^$//g;
        $desc =~ s/\n/#/g;
        $desc =~ s/# $//g;
        push( @fs, split( '# ', $desc ) );
      } ### if ($desc)

      my $text = "\n - $priceStr\n - $year($age)\n - $km\n - $desc\n";
      $text = u_clearSpaces($text);
    } ### if ( $SITE eq $SITE_WILLHABEN)

    # FEATURES

    if ( $SITE eq $SITE_AUTOSCOUT24 ) {
      @fs    = ();
      $xpath = $G_DATA->{sites}->{$SITE}->{XPATHS}->{XPATH_FEATURES};
      my @features = $item->findnodes($xpath);
      foreach my $feature (@features) {
        my $val = encode_utf8( $feature->textContent() );
        $val =~ s/\n//g;
        $val =~ s/Weitere Info.*//g;
        $val =~ s/^ //;
        $val =~ s/ $//;
        $val =~ s/ # /#/g;
        $val =~ s/  / /g;
        $val =~ s/  / /g;

        # 08/2011 -> 2011(99)
        if ( $val =~ m|\d\d/(\d\d\d\d)/| ) {
          $val = "$1(" . ( $thisYear - $1 ) . " év)";
        }
        push @fs, $val;
      } ### foreach my $feature (@features)
    } ### if ( $SITE eq $SITE_AUTOSCOUT24)

    ######################################################################################################
    # Storing data
    my $t = time;
    if ( $priceStr =~ m/verkauft/i ) {
      $log->debug("Not adding [$title] to the database (id: $id): already sold\n");
      $G_DATA->{ads}->{$SITE}->{$id}->{status} = $STATUS_VERKAUFT;
    } elsif ( not defined( $G_DATA->{ads}->{$SITE}->{$id} ) ) {

      # New
      $G_DATA->{ads}->{$SITE}->{$id}->{status} = $STATUS_NEW;

      $log->debug("Adding [$title] to the database (id: $id)\n");
      $G_DATA->{ads}->{$SITE}->{$id}->{history}->{$t} = " Adatbázisba került; ";

    } else {

      $G_DATA->{ads}->{$SITE}->{$id}->{status} = $STATUS_EMPTY;

      if ( not defined $G_DATA->{ads}->{$SITE}->{$id}->{history} ) {
        $G_DATA->{ads}->{$SITE}->{$id}->{history}->{$t} = "Adatbázisba került; ";
      }

      # Title changed?
      if ( $G_DATA->{ads}->{$SITE}->{$id}->{title} ne $title ) {
        $G_DATA->{ads}->{$SITE}->{$id}->{history}->{$t} .= "Cím: [" . $G_DATA->{ads}->{$SITE}->{$id}->{title} . "] -> [$title]; ";
        $G_DATA->{ads}->{$SITE}->{$id}->{status} = $STATUS_CHANGED;
      }

      # Price changed?
      if ( $G_DATA->{ads}->{$SITE}->{$id}->{priceNr} != $priceNr ) {
        $G_DATA->{ads}->{$SITE}->{$id}->{history}->{$t} .= " Ár: " . $G_DATA->{ads}->{$SITE}->{$id}->{priceStr} . " -> $priceStr; ";
        $G_DATA->{ads}->{$SITE}->{$id}->{status} = $STATUS_CHANGED;
      }

      # Desc changed?
      if ( $G_DATA->{ads}->{$SITE}->{$id}->{desc} ne $desc ) {
        $G_DATA->{ads}->{$SITE}->{$id}->{history}->{$t} .= " Leírás: " . $G_DATA->{ads}->{$SITE}->{$id}->{desc} . " -> $desc; ";
        $G_DATA->{ads}->{$SITE}->{$id}->{status} = $STATUS_CHANGED;
      }
    } ### else [ if ( $priceStr =~ m/verkauft/i)]

    # update
    $G_DATA->{ads}->{$SITE}->{$id}->{title}    = $title;
    $G_DATA->{ads}->{$SITE}->{$id}->{priceNr}  = $priceNr;
    $G_DATA->{ads}->{$SITE}->{$id}->{priceStr} = $priceStr;
    $G_DATA->{ads}->{$SITE}->{$id}->{link}     = $link;
    $G_DATA->{ads}->{$SITE}->{$id}->{info}     = \@fs;
    $G_DATA->{ads}->{$SITE}->{$id}->{desc}     = $desc;

    $G_DATA->{lastChange} = $t;
    if ( $G_DATA->{ads}->{$SITE}->{$id}->{status} eq $STATUS_CHANGED ) {
      $G_DATA->{ads}->{$SITE}->{$id}->{lastChange} = $t;
    }

    # $log->debug( Dumper( $G_DATA->{ads}->{$SITE}->{$id} ) );
    my $sign;
    if ( $G_DATA->{ads}->{$SITE}->{$id}->{status} eq $STATUS_NEW ) {
      $sign = "+";
    } elsif ( $G_DATA->{ads}->{$SITE}->{$id}->{status} eq $STATUS_VERKAUFT ) {
      $sign = "\$";
    } elsif ( $G_DATA->{ads}->{$SITE}->{$id}->{status} eq $STATUS_CHANGED ) {
      $sign = "*";
    } else {
      $sign = " ";
    }

    print "$sign";

  } ### foreach my $item ( $items->...)

  if ($G_ITEMS_IN_DB) {
    my $val = ( ( 0.0 + 100 * ( $G_ITEMS_PROCESSED ? $G_ITEMS_PROCESSED : 100 ) ) / $G_ITEMS_IN_DB );
    $log->info( sprintf( "] %2d%%\n", $val ) );
  } else {
    $log->info( sprintf( "] %4d\n", $G_ITEMS_PROCESSED ) );
  }
} ### sub parseItems

sub collectData {
  $log->info("collectData(): entering\n");
  $log->info( "collectData(): G_DATA: " . Dumper( $G_DATA->{sites}->{$SITE} ) );

  $collectionDate = strftime "%Y.%m.%d %H:%M:%S", localtime;

  $G_ITEMS_PROCESSED = 0;

  foreach my $maker ( sort keys %{ $G_DATA->{sites}->{$SITE}->{urls} } ) {

    # $G_DATA->{sites}->{$SITE}->{searchConfig}->{$makerString}
    my $url = $G_DATA->{sites}->{$SITE}->{urls}->{$maker};
    $log->info("\n\n ** $maker **\n");
    if (  $G_ITEMS_TO_PROCESS_MAX > 0
      and $G_ITEMS_PROCESSED >= $G_ITEMS_TO_PROCESS_MAX ) {
      $log->info("\nElértük a feldolgozási limitet.");
      return;
    }

    for ( my $i = 1 ; ; $i++ ) {
      if (  $G_ITEMS_TO_PROCESS_MAX > 0
        and $G_ITEMS_PROCESSED >= $G_ITEMS_TO_PROCESS_MAX ) {
        $log->info("\nElértük a feldolgozási limitet.");
        return;
      }
      getHtml( $url, $i, $maker );
      last unless $G_HTML_TREE;
      parseItems() or last;
    } ### for ( my $i = 1 ; ; $i++)
  } ### foreach my $maker ( sort keys...)
  $log->info("collectData(): returning\n");

} ### sub collectData

sub str_replace {
  my $replace_this = shift;
  my $with_this    = shift;
  my $string       = shift;

  if (1) {
    $string =~ s/$replace_this/$with_this/g;
  } else {

    my $length = length($string);
    my $target = length($replace_this);
    for ( my $i = 0 ; $i < $length - $target + 1 ; $i++ ) {
      if ( substr( $string, $i, $target ) eq $replace_this ) {
        $string = substr( $string, 0, $i ) . $with_this . substr( $string, $i + $target );
        return $string;    #Comment this if you what a global replace
      }
    } ### for ( my $i = 0 ; $i < ...)
  } ### else [ if (1) ]
  return $string;
} ### sub str_replace

sub dataSave {
  $G_DATA = () unless $G_DATA;
  if ( $G_DATA->{mail}->{sendMail} == 1 ) {
    store $G_DATA, "$SCRIPTDIR/data.dat";
  } else {
    $log->info("Az adatokat nem mentettük el, mert nem történt levélküldés sem, a \$G_DATA->{mail}->{sendMail} változó értéke miatt.\n");
  }
} ### sub dataSave

sub dataLoad {

  # $G_DATA = () unless $G_DATA;
  if ( not -e "$SCRIPTDIR/data.dat" ) {
    $log->info("dataLoad(): returning - there is no file to load.\n");
    return;
  }
  $G_DATA = retrieve("$SCRIPTDIR/data.dat") or die;
  foreach my $id ( keys %{ $G_DATA->{ads}->{$SITE} } ) {
    $G_DATA->{ads}->{$SITE}->{$id}->{status} = $STATUS_EMPTY;
  }
} ### sub dataLoad

# Mail sending
# Params
sub sndMails {
  my @ids = ();
  my $index;
  foreach my $id ( sort keys %{ $G_DATA->{ads}->{$SITE} } ) {
    my $item = $G_DATA->{ads}->{$SITE}->{$id};
    next unless ( $item->{status} eq $STATUS_NEW or $item->{status} eq $STATUS_CHANGED );

    $log->debug("sndMails(): push: [$id]\n");
    push( @ids, $id );
    if ( scalar(@ids) >= $G_DATA->{mail}->{itemsInAMailMax} ) {
      $index++;
      mailThisText( "${collectionDate}_${SITE}_${index}", getMailTextforItems(@ids) );
      @ids = ();
    }
  } ### foreach my $id ( sort keys ...)

  $index++;
  mailThisText( "${collectionDate}_${SITE}_${index}", getMailTextforItems(@ids) ) if ( scalar(@ids) );

} ### sub sndMails

sub getMailTextforItems {
  my (@ids) = @_;

  my $mailTextHtml  = "";
  my $text_changed  = "";
  my $text_new      = "";
  my $count_new     = 0;
  my $count_all     = 0;
  my $count_changed = 0;

  $log->debug( "getMailTextforItems(" . join( ',', @ids ) . ") \n" );

  $mailTextHtml = "Utolsó állapot: $dataFileDate\n\n" if $dataFileDate;

  foreach my $id (@ids) {
    if ( not defined $G_DATA->{ads}->{$SITE}->{$id} ) {
      $log->logdie("getMailTextforItems(): $id is not defined. ??? \n");
    }
    my $item = $G_DATA->{ads}->{$SITE}->{$id};
    $log->debug("Processing '$id'\n");

    # $log->debug( Dumper($item) );

    if ( $item->{status} eq $STATUS_NEW ) {
      $count_new++;
    } elsif ( $item->{status} eq $STATUS_CHANGED ) {
      $count_changed++;
    } else {
      $log->debug( "$id: ??? .[" . $item->{status} . "]\n" );
      next;
    }
    $count_all++;
    $mailTextHtml .= getMailTextforItem($id);
    $G_DATA->{ads}->{$SITE}->{$id}->{status} = $STATUS_EMPTY;
  } ### foreach my $id (@ids)

  $mailTextHtml .= "\n";
  $mailTextHtml .= "$G_ITEMS_PROCESSED feldolgozott hirdetés\n";
  $mailTextHtml .= get_SearchInfo() . "\n";

  if ( ( $count_new + $count_changed ) == 0 ) {
    $log->info("\nNincs újdonság.\n$mailTextHtml");
    $mailTextHtml = "";
  } else {
    $mailTextHtml .= "\n_____________________\n$count_new ÚJ hirdetés\n";
    $mailTextHtml .= "$count_changed MEGVÁLTOZOTT hirdetés\n" if $count_changed;

    # $log->info("$mailTextHtml\n");
  } ### else [ if ( ( $count_new + $count_changed...))]
  return $mailTextHtml;
} ### sub getMailTextforItems

sub getMailTextforItem {
  my ( $id, $format ) = @_;
  my $retval = "";
  $log->debug("getMailTextforItem($id)\n");

  if ( not defined( $G_DATA->{ads}->{$SITE}->{$id} ) ) {
    $log->logdie("getMailTextforItem(): $id is not defined. ??? \n");
  }
  my $item = $G_DATA->{ads}->{$SITE}->{$id};
  my $sign;
  if ( $item->{status} eq $STATUS_NEW ) {
    $sign = "ÚJ!";
  } elsif ( $item->{status} eq $STATUS_CHANGED ) {
    $sign = "*";
  } else {
    return "";
  }

  # $retval .= "$sign <a href=\"" . $item->{link} . "\">" . $item->{title} . "</a>\n";
  $retval .= "$sign [" . $item->{title} . "](" . $item->{link} . ")\n";
  $retval .= " - " . $item->{priceStr} . "\n";
  $retval .= " - " . str_replace( "^, ", "", join( ', ', @{ $item->{info} } ) ) . "\n";

  foreach my $dt ( sort keys %{ $item->{history} } ) {
    $retval .= " - " . strftime( "%Y.%m.%d %H:%M", localtime($dt) ) . ": " . $item->{history}->{$dt} . "\n";
  }

  $retval .= "\n";
  return $retval;
} ### sub getMailTextforItem

sub mailThisText {

  # http://www.revsys.com/writings/perl/sending-email-with-perl.html
  my ( $fileName, $bodyText ) = @_;
  $fileName =~ s/[.:]//g;
  $fileName =~ s/[ ]/_/g;

  $log->info("Levél küldése...\n");
  $G_DATA->{lastMailSendTime} = time if ( not defined $G_DATA->{lastMailSendTime} );
  if ( not $bodyText ) {
    if ( ( time - $G_DATA->{lastMailSendTime} ) > ( 60 * 60 ) ) {
      $log->info(" Nincs változás, viszont elég régen nem küldtünk levelet, menjen egy visszajelzés.\n");
      $bodyText = "Nyugalom, fut a hirdetések figyelése. Viszont nincs megváltozott vagy új hirdetés.";
    } else {
      $log->info(" Kihagyva: nincs változás, nem spamelünk. ;)\n");
      return;
    }
  } ### if ( not $bodyText )

  {
    my $fileNameTmp = $fileName;
    if ( $G_DATA->{mail}->{sendMail} == 1 ) {
      $fileNameTmp = "./mails/${fileName}.txt";
    } else {
      $fileNameTmp = "./mails/${fileName}_NOT_SENT.txt";
    }
    $log->debug("Txt mentése: $fileNameTmp\n");

    open( MYFILE, ">$fileNameTmp" ) or die "$fileNameTmp: $!";
    print MYFILE $bodyText;
    close(MYFILE);
  }
  {
    $bodyText = u_text2html($bodyText);
    my $fileNameTmp = $fileName;
    if ( $G_DATA->{mail}->{sendMail} == 1 ) {
      $fileNameTmp = "./mails/${fileName}.html";
    } else {
      $fileNameTmp = "./mails/${fileName}_NOT_SENT.html";
    }
    $log->debug("Htm mentése $fileNameTmp\n");
    open( MYFILE, ">$fileNameTmp" ) or die "${$fileNameTmp}: $!";
    print MYFILE $bodyText;
    close(MYFILE);
  }
  my @recipients;
  if ($DEBUG) {
    push( @recipients, @{ $G_DATA->{mailRecipientsDebug} } );
  } else {
    push( @recipients, @{ $G_DATA->{mailRecipients} } );
  }
  foreach (@recipients) {
    my $email = Email::Simple->create(
      header => [
        To             => $_,
        From           => '"Sanyi" <berczi.sandor@gmail.com>',
        Subject        => "$SITE frissítés (AdWatcher)",
        'Content-Type' => 'text/html',
      ],
      body => $bodyText,
    );

    # Email::Sender::Simple
    if ( $G_DATA->{mail}->{sendMail} == 1 ) {
      $log->info("Levél küldése: -> $_ ...\n");
      sendmail($email) or die $!;
      $log->info("Küldés sikeres.\n");
    }
  } ### foreach (@recipients)

  if ( $G_DATA->{mail}->{sendMail} == 1 ) {
    $G_DATA->{lastMailSendTime} = time;
  } else {
    $log->info("Levélküldés kihagyva (ok: 'sendMail' változó értéke: false.\n");
  }
} ### sub mailThisText

sub process {
  stopWatch::reset();
  stopWatch::continue($SW_FULL_PROCESSING);
  $dataFileDate = $G_DATA->{lastChange} ? ( strftime( "%Y.%m.%d %H:%M", localtime( $G_DATA->{lastChange} ) ) ) : "";
  $log->info( "process(): G_DATA: " . Dumper( $G_DATA->{sites}->{$SITE} ) );

  collectData();
  sndMails();
  dataSave();
  stopWatch::pause($SW_FULL_PROCESSING);

  stopWatch::info();
} ### sub process

# ██    ██ ████████ ██ ██      ██ ████████ ██ ███████ ███████
# ██    ██    ██    ██ ██      ██    ██    ██ ██      ██
# ██    ██    ██    ██ ██      ██    ██    ██ █████   ███████
# ██    ██    ██    ██ ██      ██    ██    ██ ██           ██
#  ██████     ██    ██ ███████ ██    ██    ██ ███████ ███████

sub u_formatEpoch_YMD_HMS {
  my ($e) = @_;
  u_formatTime_YMD_HMS( gmtime($e) );
}

sub u_formatTimeNow_YMD_HMS {
  u_formatTime_YMD_HMS( localtime() );
}

sub u_formatTime_YMD_HMS {
  return strftime( '%Y%m%d-%H%M%S', @_ );
}

sub u_utf8Decode {
  my ($content) = @_;

  # ü -> u, € -> EUR
  $content =~ s/([^[:ascii:]]+)/unidecode($1)/ge;
  return $content;
} ### sub u_utf8Decode

sub u_utf8Delete {
  my ($content) = @_;
  $content =~ s/[^[:ascii:]]+//g;    # get rid of non-ASCII characters
  return $content;
}

sub u_clearNewLines {
  my ($input) = @_;
  return undef unless $input;
  my $retval = $input;
  $retval =~ s/\n//g;
  $retval =~ s/\r//g;
  return $retval;
} ### sub u_clearNewLines

sub u_clearSpaces {
  my ($input) = @_;
  return undef unless $input;
  my $retval = $input;
  $retval =~ s/^[ \t]*//;
  $retval =~ s/[ \t]*$//;
  $retval =~ s/[ \t]{2,}/ /g;
  $retval =~ s/[ \t]{2,}/ /g;
  $retval =~ s/[ \t]{2,}/ /g;
  return $retval;
} ### sub u_clearSpaces

sub u_cleanString {
  my ($input) = @_;
  return undef unless $input;
  my $retval = u_clearSpaces( u_clearNewLines($input) );

  # $log->debug("u_cleanString($input)=$retval\n");
  return ($retval);
} ### sub u_cleanString

sub u_text2html {
  my $text    = shift;
  my $textBak = $text;
  $text =~ s|\n|<br>|g;

  $text =~ s| \[(.*?)\]\((.*?)\)| <a href="${2}">${1}</a>|g;
  $text =~ s|\n|<br/>|g;

  return $text;
} ### sub u_text2html

# ███████ ███    ██ ████████ ██████  ██    ██
# ██      ████   ██    ██    ██   ██  ██  ██
# █████   ██ ██  ██    ██    ██████    ████
# ██      ██  ██ ██    ██    ██   ██    ██
# ███████ ██   ████    ██    ██   ██    ██
sub main {
  ini();

  for ( ; ; ) {
    my $time = time;
    while ( ( ( 0 + strftime( "%H", localtime ) ) > $G_DATA->{silentHours}->{from} )
      and ( ( 0 + strftime( "%H", localtime ) ) < $G_DATA->{silentHours}->{till} ) ) {
      $log->info("Éjszaka nem dolgozunk, majd reggel mennek ki az ajánlatok egyben\n");
      sleep( 1 * 60 );    # wait 1 minute
    }

    process();
    return 0 if $OPTION_NO_LOOP;

    my $timeToWait = ( $time + $G_DATA->{G_WAIT_BETWEEN_FULL_PROCESS_IN_SEC} ) - time;
    if ( $timeToWait < 0 ) {
      $log->warn(
        "Warning: Túl alacsony a G_WAIT_BETWEEN_FULL_PROCESS_IN_SEC változó értéke: folyamatosan fut a feldolgozás. \nA mostani futás hossza "
          . ( time - $time ) );
    } else {
      $log->info( sprintf( "Várakozás a következő feldolgozásig: %d másodperc...\n", $timeToWait ) );
      sleep($timeToWait);
    }

  } ### for ( ; ; )
} ### sub main

main();
