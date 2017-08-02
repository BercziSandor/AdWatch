#!/bin/perl
use warnings;
use strict;
use Data::Dumper;
use HTTP::Tiny;
use HTTP::CookieJar;
use HTML::TreeBuilder::XPath;
use HTML::Entities;
use Encode;
use List::Util qw[min max];
use Storable;
use Log::Log4perl;
use Time::HiRes qw( time );
use POSIX qw(strftime);

# Do not change this settings above this line.

# debug options for the developer;
$Data::Dumper::Sortkeys = 1;
my $offline           = 0;
my $maxPagesToProcess = 0;      # 0: off
my $talalatperOldal   = 100;    # default:10 max:100
my $saveHtmlFiles     = 0;

# GLOBAL variables
my $url;
my $G_TREE;
my $g_stopWatch;
my $G_DATA;
my $G_ITEMS_PROCESSED   = 0;
my $G_PROCESS_EVERY_SEC = 60;
my $log;
my $httpTiny;
my $cookieJar;

# CONSTANTS
my $STATUS_EMPTY   = 'undef';
my $STATUS_CHANGED = 'changed';
my $STATUS_NEW     = 'new';

my %urls;
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

sub msg
{
    my ( $level, $msg ) = @_;

}

sub getHtml
{
    my ( $url, $page ) = @_;
    $page = 1 if not defined $page;
    $url =~ s/×page×/$page/g;

    my $html;
    $log->debug( "getHtml(page $page)" );

    my $fileName = $url;

    # "https://www.hasznaltauto.hu/talalatilista/auto/QLCS1E1TTFYOULSU8S9....SGHQ1CYY9G9C5EUHUUI4LLU/page×page×";

    if ( $url =~ m|talalatilista/([^/]+)/(.{10})[^/]+/page(\d+)| ) {
        $fileName = "$1_$2_$3.html";

        $log->debug( "fileName: $fileName" );
    } else {
        $log->logdie( "xxlz" );
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
        my $response = $httpTiny->get( $url );
        stopWatch_Pause( "Letoltés" );
        if ( $response->{success} ) {
            $html = $response->{content};

            if ( $saveHtmlFiles ) {
                open( MYFILE, ">$fileName" );
                print MYFILE $html;
                close( MYFILE );
            }

            # open( MYFILE, "$fileName" );
            # my $record;
            # while ( $record = <MYFILE> ) {
            #     $html .= $record;
            # }
            # close( MYFILE );

        } else {
            $log->logdie( "Error getting url '$url': "
                  . "Status: "
                  . ( $response->{status} ? $response->{status} : " ? " ) . ", "
                  . "Reasons: "
                  . ( $response->{reasons} ? $response->{reasons} : " ? " )
                  . "(599: timeout, too big response etc.)" );
            die();
        } ### else [ if ( $response->{success...})]

        # $html = encode_utf8( $html );
    } ### else [ if ( $offline and -e "$fileName")]

    # $G_TREE = HTML::TreeBuilder::XPath->new_from_content( $html);
    $G_TREE->delete();
    $G_TREE = undef;
    $G_TREE = HTML::TreeBuilder::XPath->new_from_content( decode_utf8 $html) or logdie( $! );
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

    $log->debug( "parseItems()" );
    stopWatch_Continue( "Feldolgozás" );

    my @items;
    @items = $G_TREE->findnodes( $XPATH_TALALATI_LISTA );

    $log->debug( " There are " . scalar( @items ) . " 'talalati_lista' items" );
    $log->logdie( "No items" ) unless @items;
    my %items;
    for my $item ( @items ) {
        $G_ITEMS_PROCESSED++;
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

        if ( defined $G_DATA->{$id} ) {

            $G_DATA->{$id}->{status} = $STATUS_EMPTY;

            # already defined. Is it changed?
            if ( $G_DATA->{$id}->{title} ne $title ) {
                $G_DATA->{$id}->{comment} .= "Cím: [" . $G_DATA->{$id}->{title} . "] -> [$title]";
                $G_DATA->{$id}->{title}  = $title;
                $G_DATA->{$id}->{status} = $STATUS_CHANGED;

            } ### if ( $G_DATA->{$id}->{...})
            if ( ( $G_DATA->{$id}->{priceNr} ? $G_DATA->{$id}->{priceNr} : 0 ) != $priceNr ) {
                $G_DATA->{$id}->{comment} .= "Ár: " . $G_DATA->{$id}->{priceStr} . " -> $priceStr; ";
                $G_DATA->{$id}->{priceNr}  = $priceNr;
                $G_DATA->{$id}->{priceStr} = $priceStr;
                $G_DATA->{$id}->{status}   = $STATUS_CHANGED;
            } ### if ( ( $G_DATA->{$id}->...))

        } else {

            # add
            $G_DATA->{$id}->{title}    = $title;
            $G_DATA->{$id}->{link}     = $link;
            $G_DATA->{$id}->{features} = \@fs;
            $G_DATA->{$id}->{category} = $category;
            $G_DATA->{$id}->{info}     = \@infos;
            $G_DATA->{$id}->{desc}     = $desc;
            $G_DATA->{$id}->{priceStr} = $priceStr;
            $G_DATA->{$id}->{priceNr}  = $priceNr;
            $G_DATA->{$id}->{status}   = $STATUS_NEW;
        } ### else [ if ( defined $G_DATA->...)]

        my $sign;
        if ( $G_DATA->{$id}->{status} eq $STATUS_NEW ) {
            $sign = "+";
        } elsif ( $G_DATA->{$id}->{status} eq $STATUS_CHANGED ) {
            $sign = "*";
        } else {
            $sign = ".";
        }
        print "$sign";
        $log->debug( " $sign $id: [$title]" );
    } ### for my $item ( @items )
    $log->debug( "parseItems done - " . scalar( @items ) . " items parsed." );
    stopWatch_Pause( "Feldolgozás" );
} ### sub parseItems

sub parsePageCount
{
    my $count = undef;
    logDie( "Error." ) unless $G_TREE;
    my @values = $G_TREE->findvalues( '//a[@class="oldalszam"]' ) or return 1;    #  @title="Utolsó oldal"

    use List::Util qw( max );
    my $max = max( @values ) or $log->logdie( "$!" );
    if ( $maxPagesToProcess > 0 ) {
        if ( $maxPagesToProcess < $max ) {
            $log->info( "Figyelem: a beállítások miatt a $max oldal helyett csak $maxPagesToProcess kerül feldolgozásra.\n" );
        }
        $max = $maxPagesToProcess;
    } ### if ( $maxPagesToProcess...)
    $log->info( "$max oldal elemeit dolgozom fel, oldalanként maximum $talalatperOldal elemmel.\n" );

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

    # ************************************************
    # INI start
    $Data::Dumper::Sortkeys = 1;
    $offline                = 0;
    $maxPagesToProcess      = 0;      # 0: off
    $talalatperOldal        = 100;    # default:10 max:100
    $saveHtmlFiles          = 0;

    $G_PROCESS_EVERY_SEC = 60;

    %urls = (
        default =>
"https://www.hasznaltauto.hu/talalatilista/auto/QLCS1E1TTFYOULSU8S95PUE9O1TC04GYPAFYH9LDU3D5H99S5WUSR596L97PMP3PT4JUAT1FTHK2U6G9TACKTZKSSH9T048A18ZQA3OUES75KZ8SDW01JGY208A27TTCK5IZR8YS780KTIY4KJ84WFDE2RKPQGA4CDI6225A38E69WA21HSGHQ1CYY9G9C5EUHUUI4LLU/page×page×",
        alpha =>
"https://www.hasznaltauto.hu/talalatilista/auto/0P5EDP3MFTF1GPWWMCUFESO5IMJPSPQW7GT5KK27JSUQY07DEM38C7WJ1C63ZWSF9RY268R527C4WM5ETSRKWSW5IM6KGI8484OWJ5PUPEF5SSDRSJGYSUAU0REYP2TMQU3HHYT2EZOPHL9SJ7DSQPUIAIZUC4REIYCZR96L24CRSUEIF4DTPMA2G1ULG4EWG/page×page×"
    );

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

    my $enableCookies = 1;
    if ( $enableCookies ) {
        $cookieJar = HTTP::CookieJar->new;

        # 3128:Tapolca
        $cookieJar->add( "http://hasznaltauto.hu",
            "telepules_saved=1; telepules_id_user=3148; visitor_telepules=3148; talalatokszama=${talalatperOldal}; Path=/; Domain=.hasznaltauto.hu" );
        $cookieJar->add( "http://hasznaltauto.hu", "talalatokszama=${talalatperOldal}; Path=/; Domain=.hasznaltauto.hu" );
    } else {
        $cookieJar = undef;
    }

    # $httpTiny = HTTP::Tiny->new( cookie_jar => $cookieJar ) or $log->logdie( $! );
    $httpTiny = HTTP::Tiny->new( timeout => 15, cookie_jar => $cookieJar ) or $log->logdie( $! );

    # add cookie received from a request

    $url    = $urls{'alpha'};
    $G_TREE = HTML::TreeBuilder::XPath->new;
    dataLoad();

} ### sub ini

sub dataInfo
{
    my $mailText      = "\n";
    my $text_changed  = "";
    my $text_new      = "";
    my $count_new     = 0;
    my $count_changed = 0;

    foreach my $id ( keys %$G_DATA ) {
        if ( $G_DATA->{$id}->{status} eq $STATUS_NEW ) {
            $count_new++;
            $text_new .= "\n+ ["
              . $G_DATA->{$id}->{title} . "]"
              . "\n - Link:     "
              . $G_DATA->{$id}->{link}
              . "\n - Ár:       "
              . $G_DATA->{$id}->{priceStr}
              . "\n - Egyéb:    "
              . str_replace( "^, ", "", join( ', ', @{ $G_DATA->{$id}->{info} } ) ) . "\n";
        } elsif ( $G_DATA->{$id}->{status} eq $STATUS_CHANGED ) {
            $count_changed++;
            $text_changed .=
                "\n* ["
              . $G_DATA->{$id}->{title} . "]"
              . "\n - Link:     "
              . $G_DATA->{$id}->{link}
              . "\n - Változás: "
              . $G_DATA->{$id}->{comment}
              . "\n - Ár:       "
              . $G_DATA->{$id}->{priceStr}
              . "\n - Egyéb:    "
              . str_replace( "^, ", "", join( ', ', @{ $G_DATA->{$id}->{info} } ) ) . "\n";
        } ### elsif ( $G_DATA->{$id}->{...})
    } ### foreach my $id ( keys %$G_DATA)

    $mailText = "\n" . $text_changed . $text_new;
    $mailText = $mailText . "\nMegjegyzés:\n +: új elem \n *: változott elem\n .: változatlan elem\n";
    $mailText = "${mailText}\n$G_ITEMS_PROCESSED feldolgozott hírdetés\n";

    if ( ( $count_new + $count_changed ) == 0 ) {
        $mailText = "\nNincs újdonság.\n$mailText";
    } else {
        $mailText = "${mailText}\n_____________________\n$count_new ÚJ hírdetés\n";
        $mailText = "${mailText}$count_changed MEGVÁLTOZOTT hírdetés\n" if $count_changed;
    }

    print "$mailText\n";
    return $mailText;
} ### sub dataInfo

sub dataSave
{
    store $G_DATA, 'data.dat';
}

sub dataLoad
{
    return if ( not -e 'data.dat' );
    $G_DATA = retrieve( 'data.dat' );
    foreach my $id ( keys %$G_DATA ) {
        $log->debug( "Loaded: $G_DATA->{$id}->{title}" );
        $G_DATA->{$id}->{status} = $STATUS_EMPTY;
    }
} ### sub dataLoad

sub collectData
{
    my $date = strftime "%Y.%m.%d %H:%M:%S", localtime;
    $log->info( "$date\n" );
    my $html = getHtml( $url, 1 );
    my $pageCount = parsePageCount( \$html );
    $log->logdie( "PageCount is 0" ) if ( $pageCount == 0 );

    $G_ITEMS_PROCESSED = 0;
    for ( my $i = 1 ; $i <= $pageCount ; $i++ ) {
        $log->info( sprintf( "\n%" . length( "" . $pageCount ) . "d ", $i ) );
        $log->debug( sprintf( "%2.0f%% (%d of %d pages)", ( 0.0 + 100 * ( $i - 1 ) / $pageCount ), ( $i - 1 ), $pageCount ) );
        $html = getHtml( $url, $i );
        parseItems( \$html );
    } ### for ( my $i = 1 ; $i <=...)

} ### sub collectData

sub process
{
    stopWatch_Reset();
    stopWatch_Continue( "Teljes futás" );
    collectData();
    dataInfo();
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
        my $timeToWait = ( $time + $G_PROCESS_EVERY_SEC ) - time;
        if ( $timeToWait < 0 ) {
            $log->warn( "Warning: There is no wait time between the processings: continous processing.\n" );
        } else {
            $log->info( sprintf( "Waiting %d secs for next processing...\n", $timeToWait ) );
            sleep( $timeToWait );
        }

    } ### for ( ; ; )
} ### sub main

main();

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
