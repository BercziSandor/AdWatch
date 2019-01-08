#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use Data::Dumper;

use XML::LibXML;

my $filename;
$filename = '1540465883__.html';
$filename = '1540465883.html';
$filename = '1.html';

my $dom = XML::LibXML->load_html(
  location        => $filename,
  recover         => 1,
  suppress_errors => 1,
);
my $G_HTML_TREE = 'XML::LibXML::XPathContext'->new($dom);

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

my $xpath;

$xpath = '//div[contains(concat(" ", @class, " "), " cl-list-element cl-list-element-gap ")]';
my $items = $G_HTML_TREE->findnodes($xpath) or die "findnodes($xpath) error";
my $index;
foreach my $item ( $items->get_nodelist ) {
  $index++;
  $xpath = './/h2[contains(concat(" ", @class, " "), " cldt-summary-makemodel ")]';
  my $title = u_cleanString( $item->findvalue($xpath) );
  next unless $title;
  say "########\n$index";
  say " title: [$title]";


  my $link = $item->findvalue('.//div[contains(concat(" ", @class, " "), " cldt-summary-titles ")]/a/@href');
  say " link: [$link]";

  my $xpath='.//div[contains(concat(" ", @class, " "), " cldt-summary-vehicle-data ")]/ul//li';
  my @features= $item->findnodes($xpath);


  my @fs;
  foreach my $feature (@features) {
    my $val = $feature->textContent();
    $val =~ s/\n//g;
    $val =~ s/^ //;
    $val =~ s/ $//;
    $val =~ s/ # /#/g;
    $val =~ s/  / /g;
    push @fs, $val;
  } ### foreach my $feature (@features)


  print Dumper(@fs);
  # print "fs: $featuresString\n";  




} ### foreach my $item ( $items->...)
