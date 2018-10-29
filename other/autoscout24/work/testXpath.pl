#!/usr/bin/perl

# https://grantm.github.io/perl-libxml-by-example/html.html

use strict;
use warnings;
use Data::Dumper;

use HTML::TreeBuilder::XPath;
use HTML::Entities;
use HTTP::CookieJar::LWP;
use WWW::Mechanize;
use Encode;

use XML::LibXML;

my $saveHtmlFiles = 0;

my $cookieJar_HttpCookieJarLWP = HTTP::CookieJar::LWP->new;
my $agent                      = 'Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36';
my $xp                         = HTML::TreeBuilder::XPath->new;

my $httpEngine = WWW::Mechanize->new(
  timeout    => 30,
  cookie_jar => $cookieJar_HttpCookieJarLWP,
  agent      => $agent
);

sub getHtml {
  my ($url) = @_;

  print("getHtml($url)");
  $xp->delete() if defined $xp;
  $xp = undef;

  my $html    = '';
  my $content = '';

  my $response = $httpEngine->get($url);
  if ( $httpEngine->success() ) {
    $html    = $httpEngine->content();
    $content = $html;
    Encode::_utf8_off($content);
    $content = decode_utf8($content);
  } else {

    # $log->info( "ajjjjaj: httpEngine error: " . $httpEngine->status() . "\n" );    #$httpEngine->status()
    $xp = undef;
    return;
  } ### else [ if ( $httpEngine->success...)]

  # $log->debug( $content );
  if ($saveHtmlFiles) {
    my $fileName = $url;
    $fileName = int(time) . ".html";
    open( MYFILE, ">$fileName" ) or die "$fileName: $!";
    print MYFILE encode_utf8($html);
    close(MYFILE);
  } ### if ($saveHtmlFiles)
  die("The content of the received html is emply.") if ( length($html) == 0 );

  $xp = HTML::TreeBuilder::XPath->new_from_content($content) or die($!);
  print(" OK\n");
  return $html;
} ### sub getHtml

sub evall {
  my ($xpath) = @_;
  my $nodes;
  print("\nevall($xpath)\n");
  $nodes = $xp->findnodes($xpath);
  if ( not $nodes->isa('XML::XPath::NodeSet') ) {
    print "Found [$nodes]\n";
    # print Dumper($nodes);
    # return;
  }

  my $index;
  foreach my $item ( $nodes->get_nodelist ) {
    ++$index;
    my $title = $item->findvalue('.//span[@itemprop="name"]');
    print "$index) title: [$title]\n";
  }

} ### sub evall

getHtml("file:///cygdrive/c/Users/sberczi/Documents/hasznaltAutoWatcher/other/autoscout24/work/1540465883__.html");

# evall('.//article[contains(@class, "search-result-entry")]');
# evall('article[contains(@class, "search-result-entry")]');
# evall('//article[contains(@class, "search-result-entry")]');
# evall('.//article[@class="search-result-entry  "]');
# evall('.//div[@id="resultlist"]/article[contains(concat(" ", @class, " "), " search-result-entry ")]/section[@class="content-section"]');
evall('//div[@id="resultlist"]');
evall('//div[@id="resultlist"]/article[@itemtype="http://schema.org/Product"]/section[@class="content-section"]//span[@itemprop="name"]');

# evall('.//div[@id="resultlist"]//article[@itemtype="http://schema.org/Product"]');
# evall('.//div[@id="resultlist"]/article[contains(concat(" ", @class, " "), " search-result-entry ")]');
