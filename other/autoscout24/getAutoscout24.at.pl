#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use Data::Dumper;
use Log::Log4perl;

# use Log::Dispatch::File::Rolling;

use FindBin;
use lib "$FindBin::Bin/lib";

# Http engines
use HTTP::Tiny;
use WWW::Mechanize;
use LWP::UserAgent;
use LWP::Protocol::https;

# Cookie stuff
use HTTP::Cookies;
use HTTP::CookieJar;
use HTTP::CookieJar::LWP;

# http://search.cpan.org/~mirod/HTML-TreeBuilder-XPath-0.14/lib/HTML/TreeBuilder/XPath.pm
use XML::LibXML;

#use HTML::TreeBuilder::XPath;
#use HTML::Entities;
use Encode;
use List::Util qw[min max];
use Storable;
use Time::HiRes qw( time );
use POSIX;
use File::Basename;
use Cwd 'abs_path';

use Email::Sender::Simple qw(sendmail);
use Email::Simple::Creator;

require stopWatch;

my $thisYear;

# my $urls;

my $SW_DOWNLOAD        = 'Letoltes';
my $SW_FULL_PROCESSING = 'Teljes futás';
my $SW_PROCESSING      = 'Feldolgozás';

# variables from config file
our $G_DATA;

$Data::Dumper::Sortkeys = 1;
my $site;
my $offline       = 0;
my $saveHtmlFiles = 1;

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

my $G_ITEMS_TO_PROCESS_MAX     = 0;    # 0: unlimited
my $G_WAIT_BETWEEN_GETS_IN_SEC = 5;

# CONSTANTS
my $STATUS_EMPTY   = 'undef';
my $STATUS_CHANGED = 'changed';
my $STATUS_NEW     = 'new';

sub ini {
  $SCRIPTDIR = dirname( abs_path($0) );

  # Logging
  my $logConf = q(
            log4perl.rootLogger                                 = DEBUG, Logfile, Screen

            log4perl.appender.Logfile                           = Log::Log4perl::Appender::File
            log4perl.appender.Logfile.filename                  = test.log
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
  $log->info("ini(): entering\n");

  # $G_HTML_TREE = HTML::TreeBuilder::XPath->new;

  $thisYear = strftime "%Y", localtime;
  my ( $name, $path, $suffix ) = fileparse( $0, qr{\.[^.]*$} );

  my $cnfFile = "${path}${name}.cfg.pl";
  unless ( my $return = require $cnfFile ) {
    die "'$cnfFile' does not exist, aborting.\n" if ( not -e $cnfFile );
    die "couldn't parse $cnfFile: $@\n" if $@;
    die "couldn't include $cnfFile: $!\n" unless defined $return;
    die "couldn't run $cnfFile\n" unless $return;
  } ### unless ( my $return = require...)
  $log->info("ini(): cfg read\n");

  if ( not defined $G_DATA->{sites}->{$site}->{searchConfig}->{defaults}->{page} ) {
    $log->logdie("A G_DATA->{$site}->{searchConfig}->{defaults}->{page} nincs definiálva.\n");
  }

  # Checking config
  if ( not defined $G_DATA->{sites}->{AUTOSCOUT}->{searchConfig}->{mmvmk0}
    or not defined $G_DATA->{CONSTANTS}->{DOWNLOADMETHODS}
    or not defined $G_DATA->{sites}->{AUTOSCOUT}->{searchConfig}->{defaults}
    or not defined $G_DATA->{sites}->{AUTOSCOUT}->{XPATHS}
    or not defined $G_DATA->{sendMail}
    or not defined $G_DATA->{mailRecipients}
    or not defined $G_DATA->{downloadMethod} ) {
    die "G_DATA is not ok, aborting\n";
  } ### if ( not defined $G_DATA...)

  dataLoad();
  $log->info("ini(): dataLoad ok\n");

  $dataFileDate
    = $G_DATA->{lastChange}
    ? ( strftime( "%Y.%m.%d %H:%M", localtime( $G_DATA->{lastChange} ) ) )
    : "";

  my $cnt = `ps -aef | grep -v grep | grep -c "$name.pl"`;
  if ( $cnt > 1 ) {
    warn "Már fut másik $name folyamat, ez leállítva.\n";

    # FIXME
  }

  my $cookieJar_HttpCookieJar    = HTTP::CookieJar->new;
  my $cookieJar_HttpCookieJarLWP = HTTP::CookieJar::LWP->new;
  my $agent = 'Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36';

  # Specific code
  getUrls();

  if ( "$site" eq "hasznaltauto.hu" ) {
    $cookieJar_HttpCookieJar->add( "http://hasznaltauto.hu", "visitor_telepules=3148 Path=/; Domain=.hasznaltauto.hu" )
      or die "$!";
    $cookieJar_HttpCookieJarLWP->add( "http://hasznaltauto.hu", "visitor_telepules=3148 Path=/; Domain=.hasznaltauto.hu" )
      or die "$!";
  } ### if ( "$site" eq "hasznaltauto.hu")

  # Generic
  $G_ITEMS_IN_DB = ( $G_DATA->{ads}->{$site} ? scalar( keys %{ $G_DATA->{ads}->{$site} } ) : 0 );
  if ($G_DATA) {
    $log->info( Dumper($G_DATA) );
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

} ### sub ini

sub getUrls {

  $log->info("getUrls(): entering\n");
  die "Run ini() before getUrls, aborting.\n" if ( not defined $thisYear );

  my $site = 'AUTOSCOUT';
  $log->info("getUrls -> ${site}\n");
  if (0) {

    # AUTOSCOUT
    foreach my $maker ( sort keys %{ $G_DATA->{sites}->{$site}->{searchConfig}->{mmvmk0} } ) {
      $log->info("maker: [$maker]\n");
      my $out = "https://www.autoscout24.at/ergebnisse?";

      # $log->info( Dumper( $G_DATA ) );
      $out .= "mmvmk0=" . $G_DATA->{sites}->{$site}->{makers}->{$maker};

      # $log->info( "out=$out\n" );

      if ( not defined $G_DATA->{sites}->{$site}->{searchConfig}->{mmvmk0}->{$maker}->{maxAge} ) {
        $log->logdie( $G_DATA->{sites}->{$site}->{searchConfig}->{mmvmk0}->{$maker}->{maxAge} . " is not defined. Aborting." );
      }
      $out .= "&fregfrom=" . ( $thisYear - ( $G_DATA->{sites}->{$site}->{searchConfig}->{mmvmk0}->{$maker}->{maxAge} ) );

      # $log->info( "out=$out\n" );

      foreach my $k ( sort keys %{ $G_DATA->{sites}->{$site}->{searchConfig}->{defaults} } ) {
        my $val;
        $log->debug("Default: $k\n");
        if ( defined $G_DATA->{sites}->{$site}->{searchConfig}->{mmvmk0}->{$maker}->{$k} ) {
          $val = $G_DATA->{sites}->{$site}->{searchConfig}->{mmvmk0}->{$maker}->{$k};
        } else {
          $val = $G_DATA->{sites}->{$site}->{searchConfig}->{defaults}->{$k};
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

      $log->debug( "\$G_DATA->{sites}->{$site}->{urls}->{" . $maker . "}=" . $out . "\n" );
      $G_DATA->{sites}->{$site}->{urls}->{$maker} = $out;
    } ### foreach my $maker ( sort keys...)
  } ### if (0)

  # WillHaben
  $site = 'WillHaben';
  $log->info("getUrls -> ${site}\n");
  my $makerString = 'CAR_MODEL/MAKE';
  foreach my $maker ( sort keys %{ $G_DATA->{sites}->{$site}->{searchConfig}->{$makerString} } ) {
    $log->info("maker: [$maker]\n");
    next if ( not defined $G_DATA->{sites}->{$site}->{searchConfig}->{$makerString}->{$maker}->{maxAge} );
    my $out = $G_DATA->{sites}->{$site}->{searchUrlRoot};

    # $log->info( Dumper( $G_DATA ) );
    die "Define G_DATA->{$site}->{makers}->{$maker}, it isn't, aborting." if not defined $G_DATA->{sites}->{$site}->{makers}->{$maker};
    $out .= "$makerString=" . $G_DATA->{sites}->{$site}->{makers}->{$maker};

    # $log->info( "out=$out\n" );
    $out .= "&YEAR_MODEL_FROM=" . ( $thisYear - ( $G_DATA->{sites}->{$site}->{searchConfig}->{$makerString}->{$maker}->{maxAge} ) );

    # $log->info( "out=$out\n" );

    foreach my $k ( sort keys %{ $G_DATA->{sites}->{$site}->{searchConfig}->{defaults} } ) {
      my $val;
      $log->debug("Default: $k\n");
      if ( defined $G_DATA->{sites}->{$site}->{searchConfig}->{$makerString}->{$maker}->{$k} ) {
        $val = $G_DATA->{sites}->{$site}->{searchConfig}->{$makerString}->{$maker}->{$k};
      } else {
        $val = $G_DATA->{sites}->{$site}->{searchConfig}->{defaults}->{$k};
      }
      if ( index( $val, ',' ) > 0 ) {
        my @vals = split( ',', $val );
        foreach my $v (@vals) {
          $out .= "&$k=$v";
        }
      } else {
        $out .= "&$k=$val";
      }

      # $log->debug("out=[$out]\n");
    } ### foreach my $k ( sort keys %...)

    # $log->debug( "\$G_DATA->{sites}->{$site}->{urls}->{" . $maker . "}=" . $out . "\n" );
    $G_DATA->{sites}->{$site}->{urls}->{$maker} = $out;
  } ### foreach my $maker ( sort keys...)

  print Dumper( $G_DATA->{sites}->{$site}->{urls} );

} ### sub getUrls

sub getHtml {
  my ( $url, $page, $maker ) = @_;
  $page = 1 if not defined $page;

  # $G_HTML_TREE->delete() if defined $G_HTML_TREE;
  $G_HTML_TREE = undef;

  $url =~ s/$G_DATA->{sites}->{$site}->{searchConfig}->{defaults}->{page}/$page/g;
  $log->debug("getHtml($url, $page, $maker)\n");

  my $html    = '';
  my $content = '';

  # Specific code
  if ( $url !~ m|$site|i ) {
    $log->logdie("Mi ez az url?? [$url]");
  }

  # Generic code
  $log->debug(" reading remote\n");
  stopWatch::continue($SW_DOWNLOAD);
  my $wtime = int( ( $G_LAST_GET_TIME + $G_WAIT_BETWEEN_GETS_IN_SEC ) - time );
  if ( $wtime > 0 ) {
    $log->debug("$wtime másodperc várakozás (két lekérés közötti minimális várakozási idő: $G_WAIT_BETWEEN_GETS_IN_SEC másodperc)\n");
    sleep($wtime);
  }

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
      $html    = $response->content;
      $content = decode_utf8($html);
    } else {
      $log->logdie( $response->status_line );
    }
  } elsif ( $G_DATA->{downloadMethod} eq $G_DATA->{CONSTANTS}->{DOWNLOADMETHODS}->{wwwMech} ) {
    my $response = $httpEngine->get($url);
    if ( $httpEngine->success() ) {
      $html    = $httpEngine->content();
      $content = $html;
      Encode::_utf8_off($content);
      $content = decode_utf8($content);
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

  # $log->debug( $content );
  if ($saveHtmlFiles) {
    my $fileName = $url;
    $fileName = int(time) . ".${maker}.${page}.html";
    $log->debug("fileName: $fileName\n");
    open( MYFILE, ">$fileName" ) or die "$fileName: $!";
    print MYFILE encode_utf8($html);
    close(MYFILE);
  } ### if ($saveHtmlFiles)
  $log->logdie("The content of the received html is emply.") if ( length($html) == 0 );

  my $dom = XML::LibXML->load_html(
    string          => $content,
    recover         => 1,
    suppress_errors => 1,
  );
  $G_HTML_TREE = 'XML::LibXML::XPathContext'->new($dom);

  # $G_HTML_TREE = HTML::TreeBuilder::XPath->new_from_content($content) or logdie($!);
  $log->debug(" \$G_HTML_TREE created.\n");
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

sub u_clearNewLines {
  my ($input) = @_;
  my $retval = $input;
  $retval =~ s/\n//g;
  $retval =~ s/\r//g;
  return $retval;
} ### sub u_clearNewLines

sub u_clearSpaces {
  my ($input) = @_;
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
  return ( u_clearSpaces( u_clearNewLines($input) ) );
}

sub parseItems {

  # my ($html) = @_;
  $log->debug("parseItems(): entering\n");
  stopWatch::continue($SW_PROCESSING);

  my $items;
  my $xpath;
  $xpath = $G_DATA->{sites}->{$site}->{XPATHS}->{XPATH_TALALATI_LISTA};
  $log->debug("Evaluating0 [$xpath]\n");
  $items = $G_HTML_TREE->findnodes($xpath) or return 1;
  $log->debug( " There are " . scalar( $items->get_nodelist ) . " 'talalati_lista' items\n" );
  return 1 unless $items;
  foreach my $item ( $items->get_nodelist ) {

    $xpath = $G_DATA->{sites}->{$site}->{XPATHS}->{XPATH_TITLE};
    my $title = u_cleanString( $item->findvalue($xpath) );
    $log->debug("Evaluating1 [$xpath]: [$title]\n");

    if ( $G_DATA->{sites}->{$site}->{XPATHS}->{XPATH_TITLE2} ) {
      $xpath = $G_DATA->{sites}->{$site}->{XPATHS}->{XPATH_TITLE2};
      $log->debug("Evaluating2 [$xpath]\n");
      my $title2 = $item->findvalue($xpath) if $xpath;
      $title .= " - " . $title2 if $title2;
    } ### if ( $G_DATA->{sites}->...)

    $title = encode_utf8($title);
    $log->info("parseItems(): title: [$title]\n");
    next unless $title;
    $G_ITEMS_PROCESSED++;

    my $link = $item->findvalue( $G_DATA->{sites}->{$site}->{XPATHS}->{XPATH_LINK} );
    my $id   = $link;

    my $desc = $item->findvalue( $G_DATA->{sites}->{$site}->{XPATHS}->{XPATH_DESC} );
    $desc =~ s/bleifrei//g;

    # if ( $site eq 'WillHaben' ) {
    if ( $site eq 'autoscout24' ) {
      $link = "https://www.autoscout24.at${link}";

      # /angebote/audi-a3-2-0-tdi-ambition-klimaauto-dpf-alu-6-gang-diesel-schwarz-99d1f527-0d81-ed66-e053-e250040a9fc2
      $id =~ s/^.*-(.{36})$/$1/g;
    } ### if ( $site eq 'autoscout24')

    my $priceStr = u_cleanString( encode_utf8( $item->findvalue( $G_DATA->{sites}->{$site}->{XPATHS}->{XPATH_PRICE} ) ) );
    $priceStr = "?" unless $priceStr;
    $priceStr =~ s/,-/ €/;
    my $priceNr = $priceStr;
    $priceNr =~ s/\D//g;
    $priceNr = 0 unless $priceStr;

    my @fs;
    if ( $site eq 'WillHaben' ) {

      # '
      #         340.000 kW (462.060 PS)
      #  Diesel
      #  Limousine
      #     '


      # 2008 75.000 km
      my $yearKm = u_cleanString( $item->findvalue('./section[@class="content-section"]//span[@class="desc-left"]') );
      my $year   = $yearKm;
      $year =~ s/^(\d*) .*/$1/;
      my $age = $thisYear - $year;
      my $km  = $yearKm;
      $km =~ s/^\d* (.*)/$1/;

      push( @fs, "$year($age)" );
      push( @fs, "$km" );

      $desc=~ s/[ ]+/ /g;
      $desc=~ s/^[ ]//g;
      $desc=~ s/^$//g;
      $desc=~ s/\n/#/g;
      $desc=~ s/# $//g;
      push( @fs, split('# ', $desc) );

      my $text = "\n - $priceStr\n - $year($age)\n - $km\n - $desc\n";
      $text = u_clearSpaces($text);
    } ### if ( $site eq 'WillHaben')

    # FEATURES

    if ( $site eq 'autoscout24' ) {
      my $features = encode_utf8( join( '#', $item->findvalues( $G_DATA->{sites}->{$site}->{XPATHS}->{XPATH_FEATURES} ) ) );
      $features =~ s/$G_DATA->{sites}->{$site}->{textToDelete}//g;
      $features =~ s/^ //;
      $features =~ s/ $//;
      $features =~ s/ # /#/g;
      $features =~ s/  / /g;
      @fs = split( '#', $features );
    } ### if ( $site eq 'autoscout24')

    say Dumper(@fs);
    exit 1;    # FIXME

    ######################################################################################################
    # Storing data
    my $t = time;
    if ( defined $G_DATA->{ads}->{$site}->{$id} ) {

      # $log->debug("Updating [$title] in the database...\n");
      $G_DATA->{ads}->{$site}->{$id}->{status} = $STATUS_EMPTY;

      if ( not defined $G_DATA->{ads}->{$site}->{$id}->{history} ) {
        $G_DATA->{ads}->{$site}->{$id}->{history}->{$t} .= "Adatbázisba került; ";
        $log->debug(" Updating history\n");
      }

      # $title;
      # $desc;
      # $priceNr;
      #  $priceStr;
      #  @fs;    # features
      #  $link;
      # $info

      # already defined. Is it changed?
      if ( $G_DATA->{ads}->{$site}->{$id}->{title} ne $title ) {
        $G_DATA->{ads}->{$site}->{$id}->{history}->{$t} .= "Cím: [" . $G_DATA->{ads}->{$site}->{$id}->{title} . "] -> [$title]; ";
        $G_DATA->{ads}->{$site}->{$id}->{title}  = $title;
        $G_DATA->{ads}->{$site}->{$id}->{status} = $STATUS_CHANGED;
        $log->debug(" Updating title\n");
      } ### if ( $G_DATA->{ads}->{...})

      if (
        (
            $G_DATA->{ads}->{$site}->{$id}->{priceNr}
          ? $G_DATA->{ads}->{$site}->{$id}->{priceNr}
          : 0
        ) != $priceNr
        ) {
        $G_DATA->{ads}->{$site}->{$id}->{history}->{$t} .= " Ár: " . $G_DATA->{ads}->{$site}->{$id}->{priceStr} . " -> $priceStr; ";
        $G_DATA->{ads}->{$site}->{$id}->{priceNr}  = $priceNr;
        $G_DATA->{ads}->{$site}->{$id}->{priceStr} = $priceStr;
        $G_DATA->{ads}->{$site}->{$id}->{status}   = $STATUS_CHANGED;
        $log->debug(" Updating price\n");
      } ### if ( ( $G_DATA->{ads}->...))

    } else {

      $log->debug("Adding [$title] to the database\n");

      $G_DATA->{ads}->{$site}->{$id}->{history}->{$t} = " Adatbázisba került; ";
      $G_DATA->{ads}->{$site}->{$id}->{title}         = $title;
      $G_DATA->{ads}->{$site}->{$id}->{link}          = $link;
      $G_DATA->{ads}->{$site}->{$id}->{info}          = \@fs;
      $G_DATA->{ads}->{$site}->{$id}->{desc}          = $desc;
      $G_DATA->{ads}->{$site}->{$id}->{priceStr}      = $priceStr;
      $G_DATA->{ads}->{$site}->{$id}->{priceNr}       = $priceNr;
      $G_DATA->{ads}->{$site}->{$id}->{status}        = $STATUS_NEW;
    } ### else [ if ( defined $G_DATA->...)]

    $G_DATA->{lastChange} = time;

    my $sign;
    if ( $G_DATA->{ads}->{$site}->{$id}->{status} eq $STATUS_NEW ) {
      $sign = "+";
    } elsif ( $G_DATA->{ads}->{$site}->{$id}->{status} eq $STATUS_CHANGED ) {
      $sign = "*";
    } else {
      $sign = " ";
    }

    # $log->debug( "\n$id:" . Dumper( $G_DATA->{ads}->{$site}->{$id} ) );

    print "$sign";

  } ### foreach my $item ( $items->...)
## perltidy -cscw 2018-11-2: ### if ( $site eq 'WillHaben')

  if ($G_ITEMS_IN_DB) {
    my $val = ( ( 0.0 + 100 * ( $G_ITEMS_PROCESSED ? $G_ITEMS_PROCESSED : 100 ) ) / $G_ITEMS_IN_DB );
    $log->info( sprintf( "] %2d%%", $val ) );
  } else {
    $log->info( sprintf( "] %4d", $G_ITEMS_PROCESSED ) );
  }

  # $log->logwarn( "parseItems(): No items, aborting\n" ) unless $items;
} ### sub parseItems
## perltidy -cscw 2018-11-2: ### foreach my $item ( $items->...)
## perltidy -cscw 2018-11-2: ### sub parseItems

sub collectData {
  $log->info("collectData(): entering");
  $collectionDate = strftime "%Y.%m.%d %H:%M:%S", localtime;

  $G_ITEMS_PROCESSED = 0;

  # AUTOSCOUT
  foreach my $maker ( sort keys %{ $G_DATA->{sites}->{$site}->{urls} } ) {
    my $url = $G_DATA->{sites}->{$site}->{urls}->{$maker};
    $log->info("\n\n** $maker **\n");
    if (  $G_ITEMS_TO_PROCESS_MAX > 0
      and $G_ITEMS_PROCESSED >= $G_ITEMS_TO_PROCESS_MAX ) {
      $log->info("\nElértük a feldolgozási limitet.");
      return;
    }

    # getHtml( $url, 1, $maker )
    # next unless $G_HTML_TREE;

    # pagecount is hard to parse, skipping it.
    # my $pageCount = parsePageCount( \$html );
    # $log->logdie("PageCount is 0") if ( $pageCount == 0 );
    # for ( my $i = 1 ; $i <= $pageCount ; $i++ ) {

    for ( my $i = 1 ; ; $i++ ) {
      if (  $G_ITEMS_TO_PROCESS_MAX > 0
        and $G_ITEMS_PROCESSED >= $G_ITEMS_TO_PROCESS_MAX ) {
        $log->info("\nElértük a feldolgozási limitet.");
        return;
      }

      # $log->info( sprintf( "\n%2d/%d [", $i, $pageCount ) );
      # $log->debug( sprintf( "%2.0f%% (%d of %d pages)", ( 0.0 + 100 * ( $i - 1 ) / $pageCount ), $i, $pageCount ) );
      getHtml( $url, $i, $maker );
      last unless $G_HTML_TREE;
      parseItems() or last;
    } ### for ( my $i = 1 ; ; $i++)
  } ### foreach my $maker ( sort keys...)

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
  if ( $G_DATA->{sendMail} == 1 ) {
    store $G_DATA, "$SCRIPTDIR/data.dat";
  } else {
    $log->info("Az adatokat nem mentettük el, mert nem történt levélküldés sem, a \$G_DATA->{sendMail} változó értéke miatt.\n");
  }
} ### sub dataSave

sub dataLoad {

  # $G_DATA = () unless $G_DATA;
  if ( not -e "$SCRIPTDIR/data.dat" ) {
    $log->info("dataLoad(): returning - there is no file to load.\n");
    return;
  }
  $G_DATA = retrieve("$SCRIPTDIR/data.dat") or die;
  foreach my $id ( keys %{ $G_DATA->{ads}->{$site} } ) {
    $G_DATA->{ads}->{$site}->{$id}->{status} = $STATUS_EMPTY;
  }
} ### sub dataLoad

sub sndMail {

  # http://www.revsys.com/writings/perl/sending-email-with-perl.html
  my ($bodyText) = @_;

  $log->info("Levél küldése...\n");

  $G_DATA->{lastMailSendTime} = time if ( not defined $G_DATA->{lastMailSendTime} );
  if ( not $bodyText ) {
    if ( ( time - $G_DATA->{lastMailSendTime} ) > ( 60 * 60 ) ) {
      $log->info(" Nincs változás, viszont elég régen nem küldtünk levelet, menjen egy visszajelzés.\n");
      $bodyText = "Nyugalom, fut a hirdetések figyelése. Viszont nincs változás, ez van.";
    } else {
      $log->info(" Kihagyva: nincs változás, nem spamelünk. ;)\n");
      return;
    }
  } ### if ( not $bodyText )

  {
    my $fileName = ${collectionDate};
    $fileName =~ s/[.:]//g;
    $fileName =~ s/[ ]/_/g;
    if ( $G_DATA->{sendMail} == 1 ) {
      $fileName = "./mails/${fileName}.txt";
    } else {
      $fileName = "./mails/${fileName}_NOT_SENT.txt";
    }
    $log->debug("Szöveg mentése $fileName file-ba...");

    open( MYFILE, ">$fileName" ) or die "$fileName: $!";
    print MYFILE $bodyText;
    close(MYFILE);
  }

  $bodyText = u_text2html($bodyText);

  {
    my $fileName = ${collectionDate};
    $fileName =~ s/[.:]//g;
    $fileName =~ s/[ ]/_/g;
    if ( $G_DATA->{sendMail} == 1 ) {
      $fileName = "./mails/${fileName}.html";
    } else {
      $fileName = "./mails/${fileName}_NOT_SENT.html";
    }
    $log->debug("Szöveg mentése $fileName file-ba...");
    open( MYFILE, ">$fileName" ) or die $!;
    print MYFILE $bodyText;
    close(MYFILE);
  }

  foreach ( @{ $G_DATA->{mailRecipients} } ) {
    my $email = Email::Simple->create(
      header => [
        To             => $_,
        From           => '"Sanyi" <berczi.sandor@gmail.com>',
        Subject        => 'Autoscout24.at frissítés',
        'Content-Type' => 'text/html',
      ],
      body => $bodyText,
    );
    $log->info(" $_ ...\n");

    # Email::Sender::Simple
    if ( $G_DATA->{sendMail} == 1 ) {
      sendmail($email) or die $!;
      $log->info("Levél küldése sikeres. To: [$_]\n");
    }

  } ### foreach ( @{ $G_DATA->{mailRecipients...}})

  if ( $G_DATA->{sendMail} == 1 ) {
    $G_DATA->{lastMailSendTime} = time;
  } else {
    $log->info("Levélküldés kihagyva (ok: 'sendMail' változó értéke: false.\n");
  }
} ### sub sndMail

sub u_text2html {
  my $text    = shift;
  my $textBak = $text;
  $text =~ s|\n|<br>|g;

  $text =~ s| \[(.*?)\]\((.*?)\)| <a href="${2}">${1}</a>|g;
  $text =~ s|\n|<br/>|g;

  return $text;
} ### sub u_text2html

sub getMailText {
  my $mailTextHtml  = "";
  my $text_changed  = "";
  my $text_new      = "";
  my $count_new     = 0;
  my $count_changed = 0;

  $mailTextHtml = "Utolsó állapot: $dataFileDate\n\n";
  foreach my $id ( sort keys %{ $G_DATA->{ads}->{$site} } ) {
    my $item = $G_DATA->{ads}->{$site}->{$id};
    if ( $item->{status} eq $STATUS_NEW ) {
      $count_new++;
      $log->debug("$id: new\n");
    } elsif ( $item->{status} eq $STATUS_CHANGED ) {
      $count_changed++;
      $log->debug("$id: changed\n");
    } else {
      $log->debug( "$id: ??? .[" . $item->{status} . "]\n" );
      next;
    }
    $mailTextHtml .= getMailTextforItem($id);

  } ### foreach my $id ( sort keys ...)

  $mailTextHtml .= "\n";
  $mailTextHtml .= "$G_ITEMS_PROCESSED feldolgozott hirdetés\n";

  if ( ( $count_new + $count_changed ) == 0 ) {
    $log->info("\nNincs újdonság.\n$mailTextHtml");
    $mailTextHtml = "";
  } else {
    $mailTextHtml .= "\n_____________________\n$count_new ÚJ hirdetés\n";
    $mailTextHtml .= "$count_changed MEGVÁLTOZOTT hirdetés\n" if $count_changed;
    $log->info("$mailTextHtml\n");
  }
  return $mailTextHtml;
} ### sub getMailText

sub getMailTextforItem {
  my ( $id, $format ) = @_;
  my $retval = "";
  return undef if ( not defined( $G_DATA->{ads}->{$site}->{$id} ) );
  my $item = $G_DATA->{ads}->{$site}->{$id};
  my $sign = (
    $item->{status} eq $STATUS_NEW
    ? "ÚJ!"
    : ( $item->{status} eq $STATUS_CHANGED ? "*" : "" )
  );
  return undef if ( not $sign );

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

sub process {
  stopWatch::reset();
  stopWatch::continue($SW_FULL_PROCESSING);
  collectData();

  sndMail( getMailText() );
  dataSave();
  stopWatch::pause($SW_FULL_PROCESSING);

  stopWatch::info();
} ### sub process

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

$site = 'WillHaben';
main();
