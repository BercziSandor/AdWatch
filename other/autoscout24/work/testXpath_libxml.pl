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

sub u_clearSpaces {
  my ($input) = @_;
  my $retval = $input;
  $retval =~ s/^\s*//;
  $retval =~ s/\n//g;
  $retval =~ s/\s*$//;
  $retval =~ s/\s{2,}/ /g;
  $retval =~ s/\s{2,}/ /g;
  $retval =~ s/\s{2,}/ /g;
  return $retval;

  # body...
} ### sub u_clearSpaces

my $xpath;
my $result;

my $articles = $xpc->findnodes('//div[@id="resultlist"]/article');
say "articles is a " . ref($articles) . ", size: " . $articles->size;

my $index_a;
my $index_cs;
my $index_c;
for my $article (@$articles) {
  $index_a++;
  say " article #${index_a} is a ", ref($article);

  my $contents = $article->findnodes('./section[@class="content-section"]');
  $index_cs++;
  say "  contents $index_cs is a " . ref($contents) . ", size: " . $contents->size;
  next unless $contents->size;

  for my $content (@$contents) {
    $index_c++;
    say "c: $index_c";

    my $name = u_clearSpaces( $xpc->findvalue( './/span[@itemprop="name"]', $content ) );
    say "   title: [$name]";

    my $desc = u_clearSpaces( $xpc->findvalue( './/div[@itemprop="description"]', $content ) );
    # say "   desc: [$desc]";

    my $info = u_clearSpaces( $xpc->findvalue( './/span[@class="desc-left"]', $content ) );
    # say "   info: [$info]";

    my $info2 = u_clearSpaces( $xpc->findvalue( './/span[@class="pull-right"]', $content ) );
    $info2 =~ s/,-/ €/;
    # say "   info2: [$info2]";

    my $text = u_clearSpaces("$desc $info $info2");
    say "   text: [$text]";

    my $link = $xpc->findvalue( './/div[contains(@class, "header")]/a/@href', $content );
    say "   link: [$link]";

  } ### for my $content (@$contents)

} ### for my $article (@$articles)
exit 0;
