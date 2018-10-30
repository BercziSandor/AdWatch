#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use XML::LibXML;

my $filename;
$filename = '1540465883__.html';
$filename = '1540465883.html';

my $dom = XML::LibXML->load_html(
  location        => $filename,
  recover         => 1,
  suppress_errors => 1,
);
my $xpc = 'XML::LibXML::XPathContext'->new($dom);

# say $xpc->toStringHTML();

sub u_clearNewLines {
  my ($input) = @_;
  my $retval = $input;
  $retval =~ s/\n//g;
  $retval =~ s/\r//g;
  return $retval;
} ### sub u_clearNewLines
## perltidy -cscw 2018-10-30: ### sub u_clearSpaces

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

my $xpath;
my $result;
my $articles = $xpc->findnodes('//div[@id="resultlist"]/article');

for my $article (@$articles) {
  my $contents = $article->findnodes('./section[@class="content-section"]');
  next unless $contents->size;

  for my $content (@$contents) {
    my $name = u_clearSpaces( $xpc->findvalue( './/span[@itemprop="name"]', $content ) );
    say "\n**************";
    say " title: [$name]";

    my $desc = u_cleanString( $xpc->findvalue( './/div[@itemprop="description"]', $content ) );

    # say " desc: [$desc]";

    my $info = u_cleanString( $xpc->findvalue( './/span[@class="desc-left"]', $content ) );

    # say " info: [$info]";

    my $info2 = u_cleanString( $xpc->findvalue( './/span[@class="pull-right"]', $content ) );
    $info2 =~ s/,-/ €/;

    # say " info2: [$info2]";

    my $text = " - $desc\n - $info\n - $info2";
    $text =~ s/bleifrei//g;
    $text = u_clearSpaces($text);
    say " text: [$text]";

    my $link = $xpc->findvalue( './/div[contains(@class, "header")]/a/@href', $content );
    say " link: [$link]";

  } ### for my $content (@$contents)

} ### for my $article (@$articles)
exit 0;
