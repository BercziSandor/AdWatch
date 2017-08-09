#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;
use HTTP::Tiny;
use HTTP::CookieJar;
use HTTP::Cookies;
use HTML::TreeBuilder::XPath;
use HTML::Entities;
use WWW::Mechanize;
use Encode;
use List::Util qw[min max];
use Storable;
use Log::Log4perl;
use Time::HiRes qw( time );
use POSIX qw(strftime);
use LWP::UserAgent;

use Email::Sender::Simple qw(sendmail);
use Email::Simple;
use Email::Simple::Creator;

my @g_mailRecipients =
  ( '"Sanyi" <berczi.sandor@gmail.com>', '"Tillatilla66" <tillatilla66@freemail.hu>', '"Tillatilla1966" <tillatilla.1966@gmail.com>' );
my $g_sendMail = 1;

# Do not change this settings above this line.

# debug options for the developer;
$Data::Dumper::Sortkeys = 1;
my $offline       = 0;
my $saveHtmlFiles = 0;
my $g_downloadMethod;

$g_downloadMethod = 'lwp';
$g_downloadMethod = 'wwwMech';
$g_downloadMethod = 'httpTiny';

my $G_ITEMS_TO_PROCESS_MAX             = 0;
my $G_WAIT_BETWEEN_FULL_PROCESS_IN_SEC = 10 * 60;
my $G_WAIT_BETWEEN_GETS_IN_SEC         = 5;

# GLOBAL variables
# my $url;
my $G_ITEMS_IN_DB;
my $G_HTML_TREE;
my $g_stopWatch;
my $G_DATA;
my $G_ITEMS_PROCESSED = 0;
my $G_ITEMS_PER_PAGE  = 100;    # default:10 max:100
my $G_LAST_GET_TIME   = 0;
my $log;
my $httpEngine;
my $collectionDate;

# CONSTANTS
my $STATUS_EMPTY   = 'undef';
my $STATUS_CHANGED = 'changed';
my $STATUS_NEW     = 'new';

my $urls;
my $logConf;

my $XPATH_TALALATI_LISTA = '//*[@id="main_nagyoldal_felcserelve"]//div[contains(concat(" ", @class, " "), " talalati_lista ")]';
my $XPATH_TITLE          = 'div[@class="talalati_lista_bal"]/div[@class="talalati_lista_headcont"]/div[@class="talalati_lista_head"]/h2/a';
my $XPATH_LINK           = 'div[@class="talalati_lista_bal"]/div[@class="talalati_lista_headcont"]/div[@class="talalati_lista_head"]/h2/a/@href';
my $XPATH_PRICE          = 'div[@class="talalati_lista_jobb"]/div[@class="talalati_lista_vetelar"]/div[@class="arsor"]';
my $XPATH_INFO           = 'div[@class="talalati_lista_bal"]/div[@class="talalati_lista_infosor"]';
my $XPATH_DESC =
  'div[@class="talalati_lista_bal"]/div[@class="talalati_lista_tartalom"]/div[@class="talalati_lista_szoveg"]/p[@class="leiras-nyomtatas"]';
my $XPATH_FEATURES =
  'div[@class="talalati_lista_bal"]/div[@class="talalati_lista_tartalom"]/div[@class="talalati_lista_szoveg"]/p[@class="felszereltseg-nyomtatas"]';
my $XPATH_KEP =
  'div[@class="talalati_lista_bal"]/div[@class="talalati_lista_tartalom"]/div[@class="talalati_lista_kep"]/a/img[@id="talalati_2"]/@src';

# //*[@id="talalati_2"]

sub msg
{
    my ( $level, $msg ) = @_;

}

sub getHtml
{
    my ( $url, $page ) = @_;
    $page = 1 if not defined $page;
    $url =~ s/×page×/$page/g;

    my $html    = '';
    my $content = '';
    $log->debug( "getHtml(page $page)" );

    my $fileName = $url;

    # "https://www.hasznaltauto.hu/talalatilista/auto/QLCS1E1TTFYOULSU8S9....SGHQ1CYY9G9C5EUHUUI4LLU/page×page×";

    if ( $url =~ m|talalatilista/([^/]+)/(.{10})[^/]+/page(\d+)| ) {
        $fileName = "$1_$2_$3.html";
        $log->debug( "fileName: $fileName" );
    } else {
        $log->logdie( "Mi ez az url?? [$url]" );
    }

    if ( $offline and -e "$fileName" ) {
        $log->debug( " reading local file" );
        open( MYFILE, "$fileName" );
        my $record;
        while ( $record = <MYFILE> ) {
            $html .= $record;
        }
        close( MYFILE );
    } elsif ( $offline and !-e "$fileName" ) {
        $log->logdie( "File $fileName does not exist. (Option 'offline' is on)" );
    } else {
        $log->debug( " reading remote" );
        stopWatch_Continue( "Letoltés" );
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

            # print Dumper($response);
            if ( $response->is_success ) {
                $html    = $response->content;
                $content = decode_utf8( $html );
            } else {
                $log->logdie( $response->status_line );
            }

        } elsif ( $g_downloadMethod eq 'wwwMech' ) {
            my $response = $httpEngine->get( $url );
            if ( $httpEngine->success() ) {

                # $log->debug( Dumper( $httpEngine ) );
                $html    = $httpEngine->content();
                $content = $html;
            } else {
                $log->logdie( $httpEngine->status() );
            }

        } elsif ( $g_downloadMethod eq 'wget' ) {
        } elsif ( $g_downloadMethod eq 'curl' ) {

        } else {
            $log->logdie( "The value of variable g_downloadMethod is not ok, aborting" );

        }

        stopWatch_Pause( "Letoltés" );
        $log->debug( $html );
        if ( $saveHtmlFiles ) {
            open( MYFILE, ">$fileName" );
            print MYFILE $html;
            close( MYFILE );
        }

    } ### else [ if ( $offline and -e "$fileName")]
    $log->logdie( "The content of the received html is emply." ) if ( length( $html ) == 0 );

    # $G_HTML_TREE = HTML::TreeBuilder::XPath->new_from_content( $html);
    $G_HTML_TREE->delete();
    $G_HTML_TREE = undef;
    $G_HTML_TREE = HTML::TreeBuilder::XPath->new_from_content( $content ) or logdie( $! );
    return $html;
} ### sub getHtml

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

sub parseItems
{
    my ( $html ) = @_;

    $log->debug( "parseItems(" . \$html . ")" );
    stopWatch_Continue( "Feldolgozás" );

    my @items;
    @items = $G_HTML_TREE->findnodes( $XPATH_TALALATI_LISTA );

    $log->debug( " There are " . scalar( @items ) . " 'talalati_lista' items" );
    $log->logdie( "No items" ) unless @items;
    my %items;
    for my $item ( @items ) {
        $G_ITEMS_PROCESSED++;
        if ( ( $G_ITEMS_TO_PROCESS_MAX > 0 ) and ( $G_ITEMS_PROCESSED > $G_ITEMS_TO_PROCESS_MAX ) ) {
            print "x";
            next;
        }
        my $G_DATA_item = ();
        my $title       = encode_utf8( $item->findvalue( $XPATH_TITLE ) );
        my $link        = $item->findvalue( $XPATH_LINK );
        my $id          = $link;
        $id =~ s/^.*-(\d+)$/$1/g;    # s-11707757

        # https://www.hasznaltauto.hu/auto/dodge/grand_caravan/dodge_grand_caravan_3.6_benzin_gaz-11659098
        my $category = $link;
        $category =~ s#^.*hasznaltauto.hu/(.*)/(.*)/(.*)/.*$#$2/$3#g;    # s-11707757

        my $features = encode_utf8( $item->findvalue( $XPATH_FEATURES ) );
        $features = str_replace( "Felszereltség: ", "",  $features );
        $features = str_replace( " – ",           "#", $features );
        my @fs = split( '#', $features );

        my $keplink = $item->findvalue( $XPATH_KEP );

        my $info = $item->findvalue( $XPATH_INFO );
        $info = encode_entities( $info );
        $info = str_replace( "&nbsp;", "", $info );
        $info = str_replace( '[?] km-re', "", $info );
        $info = str_replace( "&middot;", "#", $info );
        $info = str_replace( "&sup3;", "3", $info );
        $info = decode_entities( $info );
        $info = encode_utf8( $info );
        my @infos = split( '#', $info );

        my $desc = encode_utf8( $item->findvalue( $XPATH_DESC ) );

        my $priceStr = encode_utf8( $item->findvalue( $XPATH_PRICE ) );
        my $priceNr  = $priceStr;

        # $priceNr =~ s/[Ft .]//g;    # 15.890.000 Ft
        $priceNr =~ s/\D//g;
        $priceNr = 0 unless $priceNr;

        if ( defined $G_DATA->{ads}->{$id} ) {

            $G_DATA->{ads}->{$id}->{status} = $STATUS_EMPTY;

            # already defined. Is it changed?
            if ( $G_DATA->{ads}->{$id}->{title} ne $title ) {
                $G_DATA->{ads}->{$id}->{comment} .=
                  strftime( "%Y.%m.%d %H:%M:%S:", localtime ) . "Cím: [" . $G_DATA->{ads}->{$id}->{title} . "] -> [$title]; ";
                $G_DATA->{ads}->{$id}->{title}  = $title;
                $G_DATA->{ads}->{$id}->{status} = $STATUS_CHANGED;

            } ### if ( $G_DATA->{ads}->{...})

            if ( ( $G_DATA->{ads}->{$id}->{priceNr} ? $G_DATA->{ads}->{$id}->{priceNr} : 0 ) != $priceNr ) {
                $G_DATA->{ads}->{$id}->{comment} .=
                  strftime( "%Y.%m.%d %H:%M:%S:", localtime ) . " Ár: " . $G_DATA->{ads}->{$id}->{priceStr} . " -> $priceStr; ";
                $G_DATA->{ads}->{$id}->{priceNr}  = $priceNr;
                $G_DATA->{ads}->{$id}->{priceStr} = $priceStr;
                $G_DATA->{ads}->{$id}->{status}   = $STATUS_CHANGED;
            } ### if ( ( $G_DATA->{ads}->...))

            if ( not defined $G_DATA->{ads}->{$id}->{firstSeen} ) {
                $G_DATA->{ads}->{$id}->{firstSeen} = strftime( "%Y.%m.%d %H:%M:%S", localtime );
                $G_DATA->{ads}->{$id}->{comment} .=
                  strftime( "%Y.%m.%d %H:%M:%S:", localtime ) . "Adatbázisba került; ";
            }
        } else {

            # add
            $G_DATA->{ads}->{$id}->{comment} =
              strftime( "%Y.%m.%d %H:%M:%S:", localtime ) . "Adatbázisba került; ";
            $G_DATA->{ads}->{$id}->{firstSeen} = strftime( "%Y.%m.%d %H:%M:%S", localtime );
            $G_DATA->{ads}->{$id}->{title}     = $title;
            $G_DATA->{ads}->{$id}->{link}      = $link;
            $G_DATA->{ads}->{$id}->{features}  = \@fs;
            $G_DATA->{ads}->{$id}->{category}  = $category;
            $G_DATA->{ads}->{$id}->{info}      = \@infos;
            $G_DATA->{ads}->{$id}->{desc}      = $desc;
            $G_DATA->{ads}->{$id}->{priceStr}  = $priceStr;
            $G_DATA->{ads}->{$id}->{priceNr}   = $priceNr;
            $G_DATA->{ads}->{$id}->{status}    = $STATUS_NEW;
        } ### else [ if ( defined $G_DATA->...)]
        $G_DATA->{lastChanged} = time;

        my $sign;
        if ( $G_DATA->{ads}->{$id}->{status} eq $STATUS_NEW ) {
            $sign = "+";
        } elsif ( $G_DATA->{ads}->{$id}->{status} eq $STATUS_CHANGED ) {
            $sign = "*";
        } else {
            $sign = " ";
        }
        print "$sign";
        $log->debug( " $sign $id: [$title]" );
    } ### for my $item ( @items )
    if ( $G_ITEMS_IN_DB ) {
        my $val = ( ( 0.0 + 100 * ( $G_ITEMS_PROCESSED ? $G_ITEMS_PROCESSED : 100 ) ) / $G_ITEMS_IN_DB );
        $log->info( sprintf( "] %2d%%", $val ) );
    } else {
        $log->info( sprintf( "] %4d", $G_ITEMS_PROCESSED ) );
    }
    $log->debug( "parseItems done - " . scalar( @items ) . " items parsed." );
    stopWatch_Pause( "Feldolgozás" );
} ### sub parseItems

sub parsePageCount
{
    my $count = undef;
    $log->logDie( "Error." ) unless $G_HTML_TREE;
    my @values = $G_HTML_TREE->findvalues( '//a[@class="oldalszam"]' ) or return 1;    #  @title="Utolsó oldal"

    use List::Util qw( max );
    my $max = max( @values ) or $log->logdie( "$!" );

    if ( $G_ITEMS_TO_PROCESS_MAX > 0 ) {
        use POSIX;
        my $maxPagesToProcess = ceil( $G_ITEMS_TO_PROCESS_MAX / $G_ITEMS_PER_PAGE );

        if ( $maxPagesToProcess < $max ) {
            $log->info( " Figyelem: a beállítások miatt a $max oldal helyett csak $maxPagesToProcess kerül feldolgozásra.\n" );
        }
        $max = $maxPagesToProcess;
    } ### if ( $G_ITEMS_TO_PROCESS_MAX...)
        # $log->info( " Feldolgozandó oldalak száma: $max" );

    # $log->info( " $max oldal elemeit dolgozom fel, oldalanként maximum $G_ITEMS_PER_PAGE elemmel.\n" );

    return $max;
} ### sub parsePageCount

sub ini
{
    use File::Basename;
    my ( $name, $path, $suffix ) = fileparse( $0, qr{\.[^.]*$} );

    my $cnfFile = "${path}${name}.cfg.pl";
    unless ( my $return = do $cnfFile ) {
        die "$cnfFile does not exist, aborting.\n" if ( not -e $cnfFile );
        die "couldn't parse $cnfFile: $@\n" if $@;
        die "couldn't do $cnfFile: $!\n" unless defined $return;
        die "couldn't run $cnfFile\n" unless $return;
    } ### unless ( my $return = do $cnfFile)
    dataLoad();

    # ************************************************
    # INI start

    # Típusok:
    #   - Audi 2002 től
    #   - Citroen 2006 tól
    #   - Fiat 2006 tól
    #   - Ford 2006 tól.
    #   - Honda 2005 től

    #   - Opel 2006 tól
    #   - Peugeot 2006 tól.
    #   - Renault 2006 tól
    #   - Seat  2006 tól
    #   - Skoda 2006 tól

    #   - Suzuki tipusok, 2006 tól.
    #   - Toyota 2006
    #   - Volkswagen  2002 től

    # - 2 m Ft-ig
    # - Dunántúli megyékben

    $urls = {

        dunantuli_2m_2006_audi_honda =>
"https://www.hasznaltauto.hu/talalatilista/auto/2G4ZLMFQ4LHPDGMZKJH00HADOQOOO6I164FMT47PL79M11C6MT71K400GI1Q2ZAHZFIKISZH2WL3JRYZ8ZJ87GT03S8C1AZRLUKKM3FT8GHHPFYQMRM175HW1YGIHMEUGMZ28MKYJ99JGRMG1AOFW5410IOQDAPO1KKQRMMLJST3K0KYSK6U42Q04ORSZ57FWWWYHL9QJWTAZR5SWAMSM5HR3WRT7427GUM3A9FU01A1J4KWI6CHI245M4Q6KFI8C7MYYZPSIU98C2FC2K2MRDEKTJ1694T18W9MYGEY6A8UACERT2U6H6WFID7ZM6AA6699ELQ9AS782CFRPQQEUOKS6JYKLEMYYY8O4923OMPOIG67IT1QROW9TC8T6UDTQDF9O9OG59FI7HRCH6LDP608G38MS3ADHC2FMSJH2JS68SWSCLCQ2LD1PJ6DD/page×page×",

        dunantuli_2m_2006_opel_skoda =>
"https://www.hasznaltauto.hu/talalatilista/auto/DOSR5EWSS5PGQEEI31POCFKQD2IG1EW5APLPGJJE86ATQFIZEKD6F682EEA208WK606DAF0OR179H56HGTA1I5MEE0EHL3839HF85E47EGJAWCEZGA6TPUYYOHWYUFPSKPHYFZJZY2EYJQY4SGYP8P250KIWLF5Z1QAHOJDII1Z13RA5DSMJH22006DC4R2EUFO06M1QO4D64154T6ERW59TU8CR9ZO5EW4TR8R5G13UPJ7TZJ2SO882WU32AZFKCDKLZ4AYPKH4MG1R73ZCM4UJPK4J6OKKRS6AUQ1JL1PKM8M0PEDDJZTKF5PUKI3RW66LTIDIMM7Y74CGJL0R9GG1J32MDS3R20GIOLI5SDEGIAYGJ7HQDCMT7I5ZQYPQELCELQ07P6ZQY4H36HT674T3CYTM9QHYK8FYM8KO1G6DCDZJ3KA8JFK8ETQ/page×page×",

        dunantuli_2m_2006_toyota_wv =>
"https://www.hasznaltauto.hu/talalatilista/auto/QLCS1AYWZFTOUAAS97TJJORP42IMYY7AY4JH11U4IGIU3AYMS6HPJ9C3D7AMGZIU63SR652051Z37727OOYH1QT3GKKSCIF9QG5RW1QAF43TUDOIPROT2IEJTOLI4OJSM42CPE7F0HL0A00QL2WOHH8T02OAAYCAT17R2PLZ71K9I77SG2QWE8M86E60M40AOEE2T1DW75W929MQW0YYEEAR1W96GLG2TZYJCOYA7EGL056Q3DRS79KPDOOJ0AM1DIHK6CH0C6DIE9PO76P3KLJZJ2W9J55USTPE6ZGMQ0OW4GGC67TMJMIFIKD4492W9FSTQQJAUUZJALPKU8RY6L51D5QI9LGHJORWG2GZGFKAH9931YAU1F9RPPYRDF8D2FGYTQOS63I2DFO5OU74S812WLOCDLLDPHC7CP7CGMA8EYD6158WSO72ELLUU/page×page×",

    };

    $logConf = q(
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

    # INI end
    # ************************************************

    Log::Log4perl::init( \$logConf );
    $log = Log::Log4perl->get_logger();
    my $agent = 'Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36';

    $log->info( strftime( "%Y.%m.%d %H:%M:%S", localtime ) . "\n" );

    # set_cookie( $version, $key, $val, $path, $domain, $port, $path_spec, $secure, $maxage, $discard, \%rest )
    my $cookieJar_HttpCookies;
    $cookieJar_HttpCookies = HTTP::Cookies->new();
    $cookieJar_HttpCookies->set_cookie( 0, 'talalatokszama', $G_ITEMS_PER_PAGE, '/', 'http://hasznaltauto.hu', 80, 0, 0, 86400, 0 );

    # Working, but only with httpTiny
    # 3128:Tapolca
    my $cookieJar_HttpCookieJar = HTTP::CookieJar->new;
    $cookieJar_HttpCookieJar->add( "http://hasznaltauto.hu",
        "telepules_saved=1; telepules_id_user=3148; visitor_telepules=3148; talalatokszama=${G_ITEMS_PER_PAGE}; Path=/; Domain=.hasznaltauto.hu" );
    $cookieJar_HttpCookieJar->add( "http://hasznaltauto.hu", "talalatokszama=${G_ITEMS_PER_PAGE}; Path=/; Domain=.hasznaltauto.hu" );

    $G_ITEMS_IN_DB = ( $G_DATA->{ads} ? scalar( keys %{ $G_DATA->{ads} } ) : 0 );
    $log->info( "Ini: Eddig beolvasott hirdetések száma: " . $G_ITEMS_IN_DB . "\n" );
    $log->info( "Ini: Http motor: $g_downloadMethod\n" );
    if ( $g_downloadMethod eq 'httpTiny' ) {
        $httpEngine = HTTP::Tiny->new(
            timeout    => 15,
            cookie_jar => $cookieJar_HttpCookieJar,
            agent      => $agent
        ) or $log->logdie( $! );
    } elsif ( $g_downloadMethod eq 'lwp' ) {

        $httpEngine = LWP::UserAgent->new(
            timeout => 15,

            # cookie_jar => $cookieJar,
            agent => $agent
        ) or $log->logdie( "zzz: $!" );

        $httpEngine->cookie_jar( $cookieJar_HttpCookies );

        # $httpEngine->cookie_jar( $cookieJar );
    } elsif ( $g_downloadMethod eq 'wwwMech' ) {
        $httpEngine = WWW::Mechanize->new(
            cookie_jar => $cookieJar_HttpCookies,
            agent      => $agent
        );

    } else {
        $log->logdie( "TODO: Please define this html engine" );
    }

    $G_HTML_TREE = HTML::TreeBuilder::XPath->new;

} ### sub ini

sub getMailText
{
    my $mailText      = "\n";
    my $mailTextHtml  = "";
    my $text_changed  = "";
    my $text_new      = "";
    my $count_new     = 0;
    my $count_changed = 0;

    foreach my $id ( keys %{ $G_DATA->{ads} } ) {
        if ( $G_DATA->{ads}->{$id}->{status} eq $STATUS_NEW ) {
            $count_new++;

            $mailTextHtml .= "+ ";
            $mailTextHtml .= "<a href=\"" . $G_DATA->{ads}->{$id}->{link} . "\">" . $G_DATA->{ads}->{$id}->{title} . "</a><br/>";
            $mailTextHtml .= " - " . $G_DATA->{ads}->{$id}->{priceStr} . "<br/>";
            $mailTextHtml .= " - " . str_replace( "^, ", "", join( ', ', @{ $G_DATA->{ads}->{$id}->{info} } ) ) . "<br/>";
            $mailTextHtml .= "<br/>";

            $text_new .= "\n+ ["
              . $G_DATA->{ads}->{$id}->{title} . "]"
              . "\n - Link:     "
              . $G_DATA->{ads}->{$id}->{link}
              . "\n - Ár:       "
              . $G_DATA->{ads}->{$id}->{priceStr}
              . "\n - Megjegyzés: "
              . $G_DATA->{ads}->{$id}->{comment}
              . "\n - Egyéb:    "
              . str_replace( "^, ", "", join( ', ', @{ $G_DATA->{ads}->{$id}->{info} } ) ) . "\n";

        } elsif ( $G_DATA->{ads}->{$id}->{status} eq $STATUS_CHANGED ) {
            $count_changed++;

            $mailTextHtml .= "* ";
            $mailTextHtml .= "<a href=\"" . $G_DATA->{ads}->{$id}->{link} . "\">" . $G_DATA->{ads}->{$id}->{title} . "</a><br/>";
            $mailTextHtml .= " - " . $G_DATA->{ads}->{$id}->{priceStr} . "<br/>";
            $mailTextHtml .= " - " . str_replace( "^, ", "", join( ', ', @{ $G_DATA->{ads}->{$id}->{info} } ) ) . "<br/>";
            $mailTextHtml .= " - " . $G_DATA->{ads}->{$id}->{comment} . "<br/>";
            $mailTextHtml .= "<br/>";

            $text_changed .=
                "\n* ["
              . $G_DATA->{ads}->{$id}->{title} . "]"
              . "\n - Link:     "
              . $G_DATA->{ads}->{$id}->{link}
              . "\n - Megjegyzés: "
              . $G_DATA->{ads}->{$id}->{comment}
              . "\n - Ár:       "
              . $G_DATA->{ads}->{$id}->{priceStr}
              . "\n - Egyéb:    "
              . str_replace( "^, ", "", join( ', ', @{ $G_DATA->{ads}->{$id}->{info} } ) ) . "\n";
        } ### elsif ( $G_DATA->{ads}->{...})

    } ### foreach my $id ( keys %{ $G_DATA...})
    $mailTextHtml .= "</table>";

    $mailText = "\n" . $text_changed . $text_new;
    $mailText = $mailText . "\nMegjegyzés:\n +: új elem \n *: változott elem\n .: változatlan elem\n";
    $mailText = "${mailText}\n$G_ITEMS_PROCESSED feldolgozott hirdetés\n";

    if ( ( $count_new + $count_changed ) == 0 ) {
        $mailText = "\nNincs újdonság.\n$mailText";
    } else {
        $mailText = "${mailText}\n_____________________\n$count_new ÚJ hirdetés\n";
        $mailText = "${mailText}$count_changed MEGVÁLTOZOTT hirdetés\n" if $count_changed;
        my $fileName = ${collectionDate};
        $fileName =~ s/[.:]//g;
        $fileName =~ s/[ ]/_/g;
        $fileName = "./mails/${fileName}.txt";
        $log->debug( "Szöveg mentése $fileName file-ba..." );
        open( MYFILE, ">$fileName" );
        print MYFILE $mailText;
        close( MYFILE );
    } ### else [ if ( ( $count_new + $count_changed...))]

    print "$mailText\n";
    return $mailTextHtml;
} ### sub getMailText

sub dataSave
{
    store $G_DATA, 'data.dat';
}

sub dataLoad
{
    return if ( not -e 'data.dat' );
    $G_DATA = retrieve( 'data.dat' );
    foreach my $id ( keys %{ $G_DATA->{ads} } ) {

        # $log->debug( "Loaded: $G_DATA->{ads}->{$id}->{title}" );
        $G_DATA->{ads}->{$id}->{status} = $STATUS_EMPTY;
    }
} ### sub dataLoad

sub collectData
{
    $collectionDate = strftime "%Y.%m.%d %H:%M:%S", localtime;

    $G_ITEMS_PROCESSED = 0;
    foreach my $urlId ( sort keys %$urls ) {
        my $url = $urls->{$urlId};
        $log->info( "\n** $urlId **\n" );
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
            $log->info( sprintf( "\n%" . length( "" . $pageCount ) . "d/%d [", $i, $pageCount ) );
            $log->debug( sprintf( "%2.0f%% (%d of %d pages)", ( 0.0 + 100 * ( $i - 1 ) / $pageCount ), ( $i - 1 ), $pageCount ) );
            $html = getHtml( $url, $i );
            parseItems( \$html );
        } ### for ( my $i = 1 ; $i <=...)
    } ### foreach my $urlId ( sort keys...)
} ### sub collectData

sub process
{
    stopWatch_Reset();
    stopWatch_Continue( "Teljes futás" );
    collectData();
    sendMail( getMailText() );
    dataSave();

    # stopWatch_Pause( "Teljes futás" );
    # stopWatch_Info();
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

sub sendMail
{

    # http://www.revsys.com/writings/perl/sending-email-with-perl.html
    my ( $bodyText ) = @_;

    return if ( not $g_sendMail );

    $log->info( "Levél küldése...\n" );

    foreach ( @g_mailRecipients ) {
        my $email = Email::Simple->create(
            header => [
                To             => $_,
                From           => '"Sanyi" <berczi.sandor@gmail.com>',
                Subject        => "Hasznaltauto.hu frissítés",
                'Content-Type' => 'text/html',
            ],
            body => $bodyText,
        );
        $log->info( " $_ ...\n" );
        sendmail( $email );
    } ### foreach ( @g_mailRecipients)

    # my $email = Email::Simple->create(
    #     header => [
    #         To             => '"Sanyi" <berczi.sandor@gmail.com>',
    #         From           => '"Sanyi" <berczi.sandor@gmail.com>',
    #         Subject        => "Hasznaltauto.hu frissítés",
    #         'Content-Type' => 'text/html',
    #     ],

    #     # body => "<p>This message is short, <br/>but <b>at least</b+++> it's cheap.</p>",
    #     body => $bodyText,
    # );
    # sendmail( $email );

} ### sub sendMail

sub stopWatch_Pause
{
    my ( $name ) = shift;
    if ( $g_stopWatch->{$name}->{start} ) {
        $g_stopWatch->{$name}->{elapsed} += ( Time::HiRes::time() - $g_stopWatch->{$name}->{start} );
    }
    $g_stopWatch->{$name}->{start} = undef;
    return;
} ### sub stopWatch_Pause

sub stopWatch_Info
{
    $log->info( "Futásidő összesítés:\n" );
    foreach my $name ( keys %$g_stopWatch ) {
        my $elapsed;
        $elapsed = $g_stopWatch->{$name}->{elapsed};
        if ( $g_stopWatch->{$name}->{start} ) {
            ${elapsed} += ( Time::HiRes::time() - $g_stopWatch->{$name}->{start} );
        }

        $log->info( sprintf( " - %-15s %6.2fs (%.2felem/s)\n", $name, ${elapsed}, ( 0.0 + $G_ITEMS_PROCESSED / ${elapsed} ) ) );
    } ### foreach my $name ( keys %$g_stopWatch)
} ### sub stopWatch_Info

sub stopWatch_ReadValue
{
    my ( $name ) = shift;
    my $elapsed;
    $elapsed = $g_stopWatch->{$name}->{elapsed} if $g_stopWatch->{$name}->{elapsed};
    $elapsed += ( Time::HiRes::time() - $g_stopWatch->{$name}->{start} ) if $g_stopWatch->{$name}->{start};
    $elapsed = 0 unless $elapsed;
    return sprintf( "%.2f", $elapsed );
} ### sub stopWatch_ReadValue

sub stopWatch_Reset
{
    my ( $name ) = shift;
    if ( $name ) {
        $g_stopWatch->{$name}->{start}   = undef;
        $g_stopWatch->{$name}->{elapsed} = 0;
    } else {
        $g_stopWatch = ();
    }
} ### sub stopWatch_Reset

sub stopWatch_Continue
{
    my ( $name ) = shift;
    $g_stopWatch->{$name}->{start} = Time::HiRes::time();

    # $g_stopWatch->{$name}->{elapsed} = 0;
} ### sub stopWatch_Continue
