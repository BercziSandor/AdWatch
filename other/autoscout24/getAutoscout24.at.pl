#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Log::Log4perl;

# Http engines
use HTTP::Tiny;
use WWW::Mechanize;
use LWP::UserAgent;

# Cookie stuff
use HTTP::Cookies;
use HTTP::CookieJar;
use HTTP::CookieJar::LWP;

# http://search.cpan.org/~mirod/HTML-TreeBuilder-XPath-0.14/lib/HTML/TreeBuilder/XPath.pm
use HTML::TreeBuilder::XPath;
use HTML::Entities;
use Encode;
use List::Util qw[min max];
use Storable;
use Time::HiRes qw( time );
use POSIX qw(strftime);
use File::Basename;

use Email::Sender::Simple qw(sendmail);
use Email::Simple::Creator;

require lib::stopWatch;
our %MAKERS;
our $searchConfig;
my $thisYear;
my $urls;
my $PAGESTRING = "VVPAGEVV";

my @g_mailRecipients = ( '"Sanyi" <berczi.sandor@gmail.com>', '"Tillatilla1966" <tillatilla.1966@gmail.com>' );
@g_mailRecipients = ( '"Sanyi" <berczi.sandor@gmail.com>' );

my $SW_DOWNLOAD        = 'Letoltes';
my $SW_FULL_PROCESSING = 'Teljes futás';
my $SW_PROCESSING      = 'Feldolgozás';

# variables from config file
our $XPATH_TALALATI_LISTA;
our $XPATH_TITLE;
our $XPATH_TITLE2;
our $XPATH_SUBTITLE;
our $XPATH_LINK;
our $XPATH_PRICE;
our $XPATH_INFO;
our $XPATH_DESC;
our $XPATH_FEATURES;
our $XPATH_KEP;
our $textToDelete;
our $g_sendMail;

$Data::Dumper::Sortkeys = 1;

my $offline       = 0;
my $saveHtmlFiles = 0;
our $g_downloadMethod;

my $dataFileDate;
my $G_ITEMS_IN_DB;
my $G_HTML_TREE;
my $g_stopWatch;
my $G_DATA;
my $G_ITEMS_PROCESSED = 0;
my $G_ITEMS_PER_PAGE  = 20;    # default:10 max:100
my $G_LAST_GET_TIME   = 0;
my $log;
my $httpEngine;
my $collectionDate;

my $G_ITEMS_TO_PROCESS_MAX             = 0;        # 0: unlimited
my $G_WAIT_BETWEEN_FULL_PROCESS_IN_SEC = 8 * 60;
my $G_WAIT_BETWEEN_GETS_IN_SEC         = 5;

# CONSTANTS
my $STATUS_EMPTY   = 'undef';
my $STATUS_CHANGED = 'changed';
my $STATUS_NEW     = 'new';

sub ini
{
    # Logging
    my $logConf = q(
            log4perl.rootLogger = DEBUG, Logfile, Screen

            log4perl.appender.Logfile                          = Log::Log4perl::Appender::File
            log4perl.appender.Logfile.filename                 = test.log
            log4perl.appender.Logfile.layout                   = Log::Log4perl::Layout::PatternLayout
            log4perl.appender.Logfile.layout.ConversionPattern = %d %r [%-5p] %F %4L - %m%n

            log4perl.appender.Screen                           = Log::Log4perl::Appender::Screen
            log4perl.appender.Screen.stderr                    = 0
            log4perl.appender.Screen.layout                    = Log::Log4perl::Layout::PatternLayout
            log4perl.appender.Screen.layout.ConversionPattern  = %m
            log4perl.appender.Screen.Threshold                 = INFO
          );

    Log::Log4perl::init( \$logConf );
    $log         = Log::Log4perl->get_logger();
    $G_HTML_TREE = HTML::TreeBuilder::XPath->new;

    $thisYear = strftime "%Y", localtime;
    my ( $name, $path, $suffix ) = fileparse( $0, qr{\.[^.]*$} );

    my $cnfFile = "${path}${name}.cfg.pl";
    unless ( my $return = require $cnfFile ) {
        die "'$cnfFile' does not exist, aborting.\n" if ( not -e $cnfFile );
        die "couldn't parse $cnfFile: $@\n" if $@;
        die "couldn't include $cnfFile: $!\n" unless defined $return;
        die "couldn't run $cnfFile\n" unless $return;
    } ### unless ( my $return = require...)

    dataLoad();
    $dataFileDate = $G_DATA->{lastChange} ? ( strftime( "%Y.%m.%d %H:%M", localtime( $G_DATA->{lastChange} ) ) ) : "";

    my $cnt = `ps -aef | grep -v grep | grep -c "$name.pl"`;
    if ( $cnt > 1 ) { die "Már fut másik $name folyamat, ez leállítva.\n"; }

    $urls = getUrls();

    my $cookieJar_HttpCookieJar = HTTP::CookieJar->new;
    my $agent = 'Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36';

# $CookieJar_HttpCookieJar->add( "http://hasznaltauto.hu", "telepules_saved=1; telepules_id_user=3148; visitor_telepules=3148; talalatokszama=${G_ITEMS_PER_PAGE}; Path=/; Domain=.hasznaltauto.hu" ) or die "$!";
    $cookieJar_HttpCookieJar->add( "http://hasznaltauto.hu", "talalatokszama=${G_ITEMS_PER_PAGE}; Path=/; Domain=.hasznaltauto.hu" ) or die "$!";
    $cookieJar_HttpCookieJar->add( "http://hasznaltauto.hu", "telepules_saved=1; Path=/; Domain=.hasznaltauto.hu" )                  or die "$!";
    $cookieJar_HttpCookieJar->add( "http://hasznaltauto.hu", "telepules_id_user=3148; Path=/; Domain=.hasznaltauto.hu" )             or die "$!";
    $cookieJar_HttpCookieJar->add( "http://hasznaltauto.hu", "visitor_telepules=3148 Path=/; Domain=.hasznaltauto.hu" )              or die "$!";

    my $cookieJar_HttpCookieJarLWP = HTTP::CookieJar::LWP->new;
    $cookieJar_HttpCookieJarLWP->add( "http://hasznaltauto.hu", "talalatokszama=${G_ITEMS_PER_PAGE}; Path=/; Domain=.hasznaltauto.hu" ) or die "$!";
    $cookieJar_HttpCookieJarLWP->add( "http://hasznaltauto.hu", "talalatokszama=${G_ITEMS_PER_PAGE}; Path=/; Domain=.hasznaltauto.hu" ) or die "$!";
    $cookieJar_HttpCookieJarLWP->add( "http://hasznaltauto.hu", "telepules_saved=1; Path=/; Domain=.hasznaltauto.hu" )                  or die "$!";
    $cookieJar_HttpCookieJarLWP->add( "http://hasznaltauto.hu", "telepules_id_user=3148; Path=/; Domain=.hasznaltauto.hu" )             or die "$!";
    $cookieJar_HttpCookieJarLWP->add( "http://hasznaltauto.hu", "visitor_telepules=3148 Path=/; Domain=.hasznaltauto.hu" )              or die "$!";

    $G_ITEMS_IN_DB = ( $G_DATA->{ads} ? scalar( keys %{ $G_DATA->{ads} } ) : 0 );
    if ($G_DATA){
        $log->info(Dumper($G_DATA));
    }
    $log->info( "Ini: Eddig beolvasott hirdetések száma: " . $G_ITEMS_IN_DB . "\n" );

    $log->info( "Ini: Http motor: $g_downloadMethod\n" );
    if ( $g_downloadMethod eq 'httpTiny' ) {
        $httpEngine = HTTP::Tiny->new(
            timeout    => 30,
            cookie_jar => $cookieJar_HttpCookieJar,
            agent      => $agent
        ) or $log->logdie( $! );
    } elsif ( $g_downloadMethod eq 'lwp' ) {

        $httpEngine = LWP::UserAgent->new(
            timeout    => 30,
            cookie_jar => $cookieJar_HttpCookieJarLWP,
            agent      => $agent
        ) or $log->logdie( "zzz: $!" );

        # $httpEngine->cookie_jar( $cookieJar_HttpCookieJarLWP );

        # $httpEngine->cookie_jar( $cookieJar );
    } elsif ( $g_downloadMethod eq 'wwwMech' ) {
        $httpEngine = WWW::Mechanize->new(
            timeout    => 30,
            cookie_jar => $cookieJar_HttpCookieJarLWP,
            agent      => $agent
        );
    } else {
        $log->logdie( "TODO: Please implement this html engine" );
    }

} ### sub ini

sub getUrls
{
    my $urls;
    if ( not defined $thisYear ) { ini; }

# https://www.autoscout24.de/ergebnisse?mmvmk0=9&mmvco=1&fregfrom=2013&fregto=2015&pricefrom=0&priceto=8000&fuel=B&kmfrom=10000&powertype=kw&atype=C&ustate=N%2CU&sort=standard&desc=0
    foreach my $maker ( sort keys %{ $searchConfig->{mmvmk0} } ) {

        # print "$maker " . $MAKERS{$maker} . "\n";
        my $out = "https://www.autoscout24.at/ergebnisse?";
        $out .= "mmvmk0=" . $MAKERS{$maker};
        $out .= "&fregfrom=" . ( $thisYear - ( $searchConfig->{mmvmk0}->{$maker}->{maxAge} ) );
        foreach my $k ( sort keys %{ $searchConfig->{defaults} } ) {
            my $val;
            if ( defined $searchConfig->{mmvmk0}->{$maker}->{$k} ) {
                $val = $searchConfig->{mmvmk0}->{$maker}->{$k};
            } else {
                $val = $searchConfig->{defaults}->{$k};
            }
            if ( index( $val, ',' ) > 0 ) {
                my @vals = split( ',', $val );
                foreach my $v ( @vals ) {
                    $out .= "&$k=$v";
                }
            } else {
                $out .= "&$k=$val";
            }
        } ### foreach my $k ( sort keys %...)

        # print "$out\n";
        $urls->{$maker} = $out;
    } ### foreach my $maker ( sort keys...)
    return $urls;
} ### sub getUrls

# lista: //*div[@class='cl-list-elements']
# my $XPATH_TALALATI_LISTA = '//*[@id="main_nagyoldal_felcserelve"]//div[contains(concat(" ", @class, " "), " talalati_lista ")]';
# my $XPATH_TITLE          = 'div[@class="talalati_lista_bal"]/div[@class="talalati_lista_headcont"]/div[@class="talalati_lista_head"]/h2/a';
# my $XPATH_LINK           = 'div[@class="talalati_lista_bal"]/div[@class="talalati_lista_headcont"]/div[@class="talalati_lista_head"]/h2/a/@href';
# my $XPATH_PRICE          = 'div[@class="talalati_lista_jobb"]/div[@class="talalati_lista_vetelar"]/div[@class="arsor"]';
# my $XPATH_INFO           = 'div[@class="talalati_lista_bal"]/div[@class="talalati_lista_infosor"]';
# my $XPATH_DESC =
#   'div[@class="talalati_lista_bal"]/div[@class="talalati_lista_tartalom"]/div[@class="talalati_lista_szoveg"]/p[@class="leiras-nyomtatas"]';
# my $XPATH_FEATURES =
#   'div[@class="talalati_lista_bal"]/div[@class="talalati_lista_tartalom"]/div[@class="talalati_lista_szoveg"]/p[@class="felszereltseg-nyomtatas"]';
# my $XPATH_KEP =
#   'div[@class="talalati_lista_bal"]/div[@class="talalati_lista_tartalom"]/div[@class="talalati_lista_kep"]/a/img[@id="talalati_2"]/@src';

# https://www.autoscout24.at/ergebnisse?priceto=3000&pricetype=public&cy=A&mmvmk0=29&pricefrom=0&sort=standard&ustate=N&ustate=U&atype=C&page=3
# https://www.autoscout24.at/ergebnisse?priceto=3000&pricetype=public&cy=A&mmvmk0=29&pricefrom=0&sort=standard&ustate=N&ustate=U&atype=C&page=4
# size: max 20, default 20

sub getHtml
{
    my ( $url, $page ) = @_;
    $page = 1 if not defined $page;
    $log->debug( "getHtml($page, $g_downloadMethod)\n" );

    # $log->debug( "getHtml($url, page: $page)" );
    # $log->debug( "replace: '$PAGESTRING' -> $page in $url" );
    $url =~ s/$PAGESTRING/$page/g;

    # $log->debug( "result: $url" );

    my $html    = '';
    my $content = '';

    my $fileName = $url;

    # "https://www.hasznaltauto.hu/talalatilista/auto/QLCS1E1TTFYOULSU8S9....SGHQ1CYY9G9C5EUHUUI4LLU/pag"$PAGESTRING";

    if ( $url =~ m|autoscout24| ) {

        # $log->debug( "fileName: $fileName" );
    } else {
        $log->logdie( "Mi ez az url?? [$url]" );
    }

    $log->debug( " reading remote\n" );
    stopWatch::continue( $SW_DOWNLOAD );
    my $wtime = int( ( $G_LAST_GET_TIME + $G_WAIT_BETWEEN_GETS_IN_SEC ) - time );
    if ( $wtime > 0 ) {
        $log->debug(
            "$wtime másodperc várakozás (két lekérés közötti minimális várakozási idő: $G_WAIT_BETWEEN_GETS_IN_SEC másodperc)\n" );
        sleep( $wtime );
    }

    $G_LAST_GET_TIME = time;

    if ( $g_downloadMethod eq 'httpTiny' ) {
        my $response = $httpEngine->get( $url );
        if ( $response->{success} ) {
            $html    = $response->{content};
            $content = decode_utf8( $html );
        } else {
            $log->logdie( "Error getting url '$url': "
                  . "Status: "
                  . ( $response->{status} ? $response->{status} : " ? " ) . ", "
                  . "Reasons: "
                  . ( $response->{reasons} ? $response->{reasons} : " ? " )
                  . "(599: timeout, too big response etc.)" );
            die();
        } ### else [ if ( $response->{success...})]
    } elsif ( $g_downloadMethod eq 'lwp' ) {
        my $response = $httpEngine->get( $url );
        if ( $response->is_success ) {
            $html    = $response->content;
            $content = decode_utf8( $html );
        } else {
            $log->logdie( $response->status_line );
        }
    } elsif ( $g_downloadMethod eq 'wwwMech' ) {
        my $response = $httpEngine->get( $url );
        if ( $httpEngine->success() ) {
            $html    = $httpEngine->content();
            $content = $html;
            Encode::_utf8_off( $content );
            $content = decode_utf8( $content );
        } else {
            $log->logdie( "ajjjjaj: httpEngine error: " . $httpEngine->status() . "\n" );    #$httpEngine->status()
        }

    } elsif ( $g_downloadMethod eq 'wget' ) {
    } elsif ( $g_downloadMethod eq 'curl' ) {
    } else {
        $log->logdie( "The value of variable g_downloadMethod is not ok, aborting" );
    }

    stopWatch::pause( $SW_DOWNLOAD );

    # $log->debug( $content );
    if ( $saveHtmlFiles ) {
        open( MYFILE, ">$fileName" );
        print MYFILE $html;
        close( MYFILE );
    }
    $log->logdie( "The content of the received html is emply." ) if ( length( $html ) == 0 );

    # $G_HTML_TREE = HTML::TreeBuilder::XPath->new_from_content( $html);
    $G_HTML_TREE->delete();
    $G_HTML_TREE = undef;
    $G_HTML_TREE = HTML::TreeBuilder::XPath->new_from_content( $content ) or logdie( $! );

    # $log->debug( Dumper( $G_HTML_TREE ) );
    $log->debug( " \$G_HTML_TREE created.\n" );
    $log->debug( "getHtml returning\n" );
    return $html;

} ### sub getHtml

sub parsePageCount
{

    my $count = undef;
    $log->logDie( "Error: G_HTML_TREE is not defined." ) unless $G_HTML_TREE;

    # <span class="cl-header-results-counter">2.773</span>
    my $value = $G_HTML_TREE->findvalue( '//span[@id="resultscounter"]' ) or return 1;    #  @title="Utolsó oldal"
    $value =~ s/\.//g;
    $log->debug( "parsePageCount: $value\n" );

    use POSIX;
    my $max = ceil( $value / $G_ITEMS_PER_PAGE ) or $log->logdie( "$!: $value" );
    if ( $G_ITEMS_TO_PROCESS_MAX > 0 ) {
        my $maxPagesToProcess = ceil( $G_ITEMS_TO_PROCESS_MAX / $G_ITEMS_PER_PAGE );

        if ( $maxPagesToProcess < $max ) {
            $log->info( " Figyelem: a beállítások miatt a $max oldal helyett csak $maxPagesToProcess kerül feldolgozásra.\n" );
        }
        $max = $maxPagesToProcess;
    } ### if ( $G_ITEMS_TO_PROCESS_MAX...)

    $log->debug( "Feldolgozandó oldalak száma: $max\n" );

    # $log->info( " $max oldal elemeit dolgozom fel, oldalanként maximum $G_ITEMS_PER_PAGE elemmel.\n" );

    return $max;

} ### sub parsePageCount

sub parseItems
{
    my ( $html ) = @_;

    # $log->debug( "parseItems()\n" );
    stopWatch::continue( $SW_PROCESSING );

    # print \$html;
    my $items;

    # my $tmp = $G_HTML_TREE->findvalue( "//title" ) or die "$!";
    # $log->debug( "TEST: title: [$tmp]\n" );

    $items = $G_HTML_TREE->findnodes( $XPATH_TALALATI_LISTA );
    foreach my $item ( $items->get_nodelist ) {
        $G_ITEMS_PROCESSED++;
        my $tmp;
        my $title = $item->findvalue( $XPATH_TITLE );
        $tmp = $item->findvalue( $XPATH_TITLE2 );
        $title .= " - " . $tmp if $tmp;
        $title = encode_utf8( $title );
        my $desc = $item->findvalue( $XPATH_DESC );

        my $link = $item->findvalue( $XPATH_LINK );
        my $id   = $link;
        $link = "https://www.autoscout24.at/$link";

        # /angebote/audi-a3-2-0-tdi-ambition-klimaauto-dpf-alu-6-gang-diesel-schwarz-99d1f527-0d81-ed66-e053-e250040a9fc2
        $id =~ s/^.*-(.{36})$/$1/g;

        my $priceStr = encode_utf8( $item->findvalue( $XPATH_PRICE ) );
        $priceStr = "?" unless $priceStr;
        my $priceNr = $priceStr;
        $priceNr =~ s/\D//g;
        $priceNr = 0 unless $priceStr;

        my $features = encode_utf8( join( '#', $item->findvalues( $XPATH_FEATURES ) ) );
        $features =~ s/$textToDelete//g;
        $features =~ s/^ //;
        $features =~ s/ $//;
        $features =~ s/ # /#/g;
        $features =~ s/  / /g;

        my @fs = split( '#', $features );

        if ( 0 ) {
            $log->debug( "\n** title: [$title]\n" );
            $log->debug( " id: [$id]\n" );
            $log->debug( " desc: [$desc]\n" ) if $desc;
            $log->debug( " link: $link\n" );
            $log->debug( " price: [$priceStr: $priceNr]\n" );
            $log->debug( "feature: [$features]\n" );
        } ### if ( 0 )

        ######################################################################################################
        # Storing data
        my $t = time;
        if ( defined $G_DATA->{ads}->{$id} ) {

            $log->debug( "Updating [$title] in the database...\n" );
            $G_DATA->{ads}->{$id}->{status} = $STATUS_EMPTY;

            if ( not defined $G_DATA->{ads}->{$id}->{history} ) {
                $G_DATA->{ads}->{$id}->{history}->{$t} .= "Adatbázisba került; ";
                $log->debug( " Updating history\n" );
            }

            # already defined. Is it changed?
            if ( $G_DATA->{ads}->{$id}->{title} ne $title ) {
                $G_DATA->{ads}->{$id}->{history}->{$t} .= "Cím: [" . $G_DATA->{ads}->{$id}->{title} . "] -> [$title]; ";
                $G_DATA->{ads}->{$id}->{title}  = $title;
                $G_DATA->{ads}->{$id}->{status} = $STATUS_CHANGED;
                $log->debug( " Updating title\n" );
            } ### if ( $G_DATA->{ads}->{...})

            if ( ( $G_DATA->{ads}->{$id}->{priceNr} ? $G_DATA->{ads}->{$id}->{priceNr} : 0 ) != $priceNr ) {
                $G_DATA->{ads}->{$id}->{history}->{$t} .= " Ár: " . $G_DATA->{ads}->{$id}->{priceStr} . " -> $priceStr; ";
                $G_DATA->{ads}->{$id}->{priceNr}  = $priceNr;
                $G_DATA->{ads}->{$id}->{priceStr} = $priceStr;
                $G_DATA->{ads}->{$id}->{status}   = $STATUS_CHANGED;
                $log->debug( " Updating price\n" );
            } ### if ( ( $G_DATA->{ads}->...))

        } else {

            # add
            $log->debug( "Adding [$title] to the database\n" );
            $G_DATA->{ads}->{$id}->{history}->{$t} = " Adatbázisba került; ";
            $G_DATA->{ads}->{$id}->{title}         = $title;
            $G_DATA->{ads}->{$id}->{link}          = $link;
            $G_DATA->{ads}->{$id}->{info}          = \@fs;

            # $G_DATA->{ads}->{$id}->{category}      = $category;
            # $G_DATA->{ads}->{$id}->{info}          = \@infos;
            $G_DATA->{ads}->{$id}->{desc}     = $desc;
            $G_DATA->{ads}->{$id}->{priceStr} = $priceStr;
            $G_DATA->{ads}->{$id}->{priceNr}  = $priceNr;
            $G_DATA->{ads}->{$id}->{status}   = $STATUS_NEW;
        } ### else [ if ( defined $G_DATA->...)]
        $G_DATA->{lastChange} = time;

        my $sign;
        if ( $G_DATA->{ads}->{$id}->{status} eq $STATUS_NEW ) {
            $sign = "+";
        } elsif ( $G_DATA->{ads}->{$id}->{status} eq $STATUS_CHANGED ) {
            $sign = "*";
        } else {
            $sign = " ";
        }

        # $log->debug( Dumper( $G_DATA->{ads}->{$id} ) );

        print "$sign";

    } ### foreach my $item ( $items->...)

    if ( $G_ITEMS_IN_DB ) {
        my $val = ( ( 0.0 + 100 * ( $G_ITEMS_PROCESSED ? $G_ITEMS_PROCESSED : 100 ) ) / $G_ITEMS_IN_DB );
        $log->info( sprintf( "] %2d%%", $val ) );
    } else {
        $log->info( sprintf( "] %4d", $G_ITEMS_PROCESSED ) );
    }

    # or die "findnodes error: $!\n";
    $log->debug( " There are " . scalar( @$items ) . " 'talalati_lista' items\n" );
    $log->logwarn( "parseItems(): No items, aborting\n" ) unless $items;
} ### sub parseItems

sub collectData
{
    $collectionDate = strftime "%Y.%m.%d %H:%M:%S", localtime;

    $G_ITEMS_PROCESSED = 0;

    # $log->info(Dumper($urls));

    foreach my $maker ( sort keys %$urls ) {

        my $url = $urls->{$maker};
        $log->info( "\n\n** $maker **\n" );
        if ( $G_ITEMS_TO_PROCESS_MAX > 0 and $G_ITEMS_PROCESSED >= $G_ITEMS_TO_PROCESS_MAX ) {
            $log->info( "\nElértük a feldolgozási limitet." );
            return;
        }
        my $html = getHtml( $url, 1 );
        my $pageCount = parsePageCount( \$html );
        $log->logdie( "PageCount is 0" ) if ( $pageCount == 0 );

        for ( my $i = 1 ; $i <= $pageCount ; $i++ ) {
            if ( $G_ITEMS_TO_PROCESS_MAX > 0 and $G_ITEMS_PROCESSED >= $G_ITEMS_TO_PROCESS_MAX ) {
                $log->info( "\nElértük a feldolgozási limitet." );
                return;
            }
            $log->info( sprintf( "\n%2d/%d [", $i, $pageCount ) );
            $log->debug( sprintf( "%2.0f%% (%d of %d pages)", ( 0.0 + 100 * ( $i - 1 ) / $pageCount ), $i, $pageCount ) );
            if ( $i > 1 ) {
                $html = getHtml( $url, $i );
            }
            parseItems( \$html );
        } ### for ( my $i = 1 ; $i <=...)
    } ### foreach my $maker ( sort keys...)
} ### sub collectData

sub str_replace
{
    my $replace_this = shift;
    my $with_this    = shift;
    my $string       = shift;

    if ( 1 ) {
        $string =~ s/$replace_this/$with_this/g;
    } else {

        my $length = length( $string );
        my $target = length( $replace_this );
        for ( my $i = 0 ; $i < $length - $target + 1 ; $i++ ) {
            if ( substr( $string, $i, $target ) eq $replace_this ) {
                $string = substr( $string, 0, $i ) . $with_this . substr( $string, $i + $target );
                return $string;    #Comment this if you what a global replace
            }
        } ### for ( my $i = 0 ; $i < ...)
    } ### else [ if ( 1 ) ]
    return $string;
} ### sub str_replace

sub dataSave
{
    # Do not save if g_sendMail != 1
    $G_DATA = () unless $G_DATA;
    if ( $g_sendMail ) {
        store $G_DATA, 'data.dat';
    } else {
        $log->info( "Az adatokat nem mentettük el, mert nem történt levélküldés sem, a \$g_sendMail változó értéke miatt.\n" );
    }
} ### sub dataSave

sub dataLoad
{
    # $G_DATA = () unless $G_DATA;
    if ( not -e 'data.dat' ){
        $log->info("dataLoad(): returning - there is no file to load.\n");
        return;
    };
    $G_DATA = retrieve( 'data.dat' ) or die ;
    foreach my $id ( keys %{ $G_DATA->{ads} } ) {
        $G_DATA->{ads}->{$id}->{status} = $STATUS_EMPTY;
    }
} ### sub dataLoad

sub sndMail
{

    # http://www.revsys.com/writings/perl/sending-email-with-perl.html
    my ( $bodyText ) = @_;

    $log->info( "Levél küldése...\n" );

    $G_DATA->{lastMailSendTime} = time if ( not defined $G_DATA->{lastMailSendTime} );
    if ( not $bodyText ) {
        if ( ( time - $G_DATA->{lastMailSendTime} ) > ( 60 * 60 ) ) {
            $log->info( " Nincs változás, viszont elég régen nem küldtünk levelet, menjen egy visszajelzés.\n" );
            $bodyText = "Nyugalom, fut a hirdetések figyelése. Viszont nincs változás, ez van.";
        } else {
            $log->info( " Kihagyva: nincs változás, nem spamelünk. ;)\n" );
            return;
        }
    } ### if ( not $bodyText )

    {
        my $fileName = ${collectionDate};
        $fileName =~ s/[.:]//g;
        $fileName =~ s/[ ]/_/g;
        if ( $g_sendMail ) {
            $fileName = "./mails/${fileName}.txt";
        } else {
            $fileName = "./mails/${fileName}_NOT_SENT.txt";
        }
        $log->debug( "Szöveg mentése $fileName file-ba..." );

        open( MYFILE, ">$fileName" ) or die "$fileName: $!";
        print MYFILE $bodyText;
        close( MYFILE );
    }

    $bodyText = text2html( $bodyText );

    {
        my $fileName = ${collectionDate};
        $fileName =~ s/[.:]//g;
        $fileName =~ s/[ ]/_/g;
        if ( $g_sendMail ) {
            $fileName = "./mails/${fileName}.html";
        } else {
            $fileName = "./mails/${fileName}_NOT_SENT.html";
        }
        $log->debug( "Szöveg mentése $fileName file-ba..." );
        open( MYFILE, ">$fileName" ) or die $!;
        print MYFILE $bodyText;
        close( MYFILE );
    }

    foreach ( @g_mailRecipients ) {
        my $email = Email::Simple->create(
            header => [
                To             => $_,
                From           => '"Sanyi" <berczi.sandor@gmail.com>',
                Subject        => 'Hasznaltauto.hu frissítés',
                'Content-Type' => 'text/html',
            ],
            body => $bodyText,
        );    # TODO: sending in plain text?
        $log->info( " $_ ...\n" );

        # Email::Sender::Simple
        if ( $g_sendMail ) {
            sendmail( $email ) or die $!;
        }

    } ### foreach ( @g_mailRecipients)

    if ( $g_sendMail ) {
        $G_DATA->{lastMailSendTime} = time;
    } else {
        $log->info( "Levélküldés kihagyva a g_sendMail változó értéke miatt.\n" ) if not $g_sendMail;
    }
} ### sub sndMail

sub text2html
{
    my $text    = shift;
    my $textBak = $text;
    $text =~ s|\n|<br>|g;

    $text =~ s| \[(.*?)\]\((.*?)\)| <a href="${2}">${1}</a>|g;
    $text =~ s|\n|<br/>|g;

    return $text;
} ### sub text2html

sub getMailText
{
    my $mailTextHtml  = "";
    my $text_changed  = "";
    my $text_new      = "";
    my $count_new     = 0;
    my $count_changed = 0;

    $mailTextHtml = "Utolsó állapot: $dataFileDate\n\n";
    foreach my $id ( keys %{ $G_DATA->{ads} } ) {
        my $item = $G_DATA->{ads}->{$id};
        if ( $item->{status} eq $STATUS_NEW ) {
            $count_new++;
        } elsif ( $item->{status} eq $STATUS_CHANGED ) {
            $count_changed++;
        } else {
            next;
        }
        $mailTextHtml .= getMailTextforItem( $id );

    } ### foreach my $id ( keys %{ $G_DATA...})

    $mailTextHtml .= "\n";
    $mailTextHtml .= "$G_ITEMS_PROCESSED feldolgozott hirdetés\n";

    if ( ( $count_new + $count_changed ) == 0 ) {
        $log->info( "\nNincs újdonság.\n$mailTextHtml" );
        $mailTextHtml = "";
    } else {
        $mailTextHtml .= "\n_____________________\n$count_new ÚJ hirdetés\n";
        $mailTextHtml .= "$count_changed MEGVÁLTOZOTT hirdetés\n" if $count_changed;
        $log->info( "$mailTextHtml\n" );
    }

    return $mailTextHtml;
} ### sub getMailText

sub getMailTextforItem
{
    my ( $id, $format ) = @_;
    my $retval = "";
    return undef if ( not defined( $G_DATA->{ads}->{$id} ) );
    my $item = $G_DATA->{ads}->{$id};
    my $sign = ( $item->{status} eq $STATUS_NEW ? "ÚJ!" : ( $item->{status} eq $STATUS_CHANGED ? "*" : "" ) );
    return undef if ( not $sign );

    # $retval .= "$sign <a href=\"" . $item->{link} . "\">" . $item->{title} . "</a>\n";
    $retval .= "$sign [" . $item->{title} . "](" . $item->{link} . ")\n";
    $retval .= " - " . $item->{priceStr} . "\n";
    $retval .= " - " . str_replace( "^, ", "", join( ', ', @{ $item->{info} } ) ) . "\n";

    foreach my $dt ( sort keys %{ $item->{history} } ) {
        $retval .= " - " . strftime( "%Y.%m.%d %H:%M", localtime( $dt ) ) . ": " . $item->{history}->{$dt} . "\n";
    }

    $retval .= "\n";

    return $retval;
} ### sub getMailTextforItem

sub process
{
    stopWatch::reset();
    stopWatch::continue( $SW_FULL_PROCESSING );
    collectData();

    sndMail( getMailText() );
    dataSave();
    stopWatch::pause( $SW_FULL_PROCESSING );

    stopWatch::info();
} ### sub process

sub main
{
    ini();

    for ( ; ; ) {
        my $time = time;
        process();

        my $timeToWait = ( $time + $G_WAIT_BETWEEN_FULL_PROCESS_IN_SEC ) - time;
        if ( $timeToWait < 0 ) {
            $log->warn(
"Warning: Túl alacsony a G_WAIT_BETWEEN_FULL_PROCESS_IN_SEC változó értéke: folyamatosan fut a feldolgozás. \nA mostani futás hossza "
                  . ( time - $time )
                  . " másodperc volt, a változó értéke pedig $G_WAIT_BETWEEN_FULL_PROCESS_IN_SEC.\n" );
        } else {
            $log->info( sprintf( "Várakozás a következő feldolgozásig: %d másodperc...\n", $timeToWait ) );
            sleep( $timeToWait );
        }

    } ### for ( ; ; )
} ### sub main

main();