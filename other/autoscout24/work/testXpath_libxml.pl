#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use XML::LibXML;

my $filename = '1540465883__.html';

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
  $retval =~ s/\s*$//;
  $retval =~ s/\s{2,}/ /;
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
    say "   desc: [$desc]";

    my $info  = u_clearSpaces( $xpc->findvalue( './/div[@class="desc-left"]',  $content ) );
    say "   info: [$info]";

    my $info2 = u_clearSpaces( $xpc->findvalue( './/div[@class="pull-right"]', $content ) );
    say "   info2: [$info2]";

  } ### for my $content (@$contents)
## perltidy -cscw 2018-10-30: ### for my $content ( $contents...)

} ### for my $article (@$articles)
## perltidy -cscw 2018-10-30: ### for my $article ( $articles...)
exit 0;

say 'xxxxxxxxxxxxxxxxxxxxxxxx';

$result = $xpc->findnodes($xpath);
say '$result is a ', ref($result);
my $i = 1;
foreach my $i ( 1 .. $result->size ) {
  my $node = $result->get_node($i);
  say '$node is a ', ref($node);
  say "X: " . $node->nodeName if $node->nodeType == XML_ELEMENT_NODE;
}

$xpath = '//div[@id="resultlist"]/article[@itemtype="http://schema.org/Product"]/section[@class="content-section"]';

$result = $xpc->findnodes($xpath);

foreach my $content ($result) {
  say $content->findvalue('./span[@itemprop="name"]');
}
