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

# say $dom->toStringHTML();

my $xpath;
my $result;

my $articles = $dom->findnodes('//div[@id="resultlist"]/article');
say "articles is a " . ref($articles) . ", size: " . $articles->size;

for my $article ( $articles->get_nodelist ) {
  say 'article is a ', ref($article);
  my $contents = $article->findnodes('./section[@class="content-section"]');
  say "contents is a " . ref($contents) . ", size: " . $contents->size;
  foreach my $content ( $contents->get_nodelist ) {
    say '$content is a ', ref($content);
    say "title: " . $content->findvalue('./span[@itemprop="name"]');
  }
} ### for my $article ( $articles...)
exit 0;

say 'xxxxxxxxxxxxxxxxxxxxxxxx';

$result = $dom->findnodes($xpath);
say '$result is a ', ref($result);
my $i = 1;
foreach my $i ( 1 .. $result->size ) {
  my $node = $result->get_node($i);
  say '$node is a ', ref($node);
  say "X: " . $node->nodeName if $node->nodeType == XML_ELEMENT_NODE;
}

$xpath = '//div[@id="resultlist"]/article[@itemtype="http://schema.org/Product"]/section[@class="content-section"]';

$result = $dom->findnodes($xpath);

foreach my $content ($result) {
  say $content->findvalue('./span[@itemprop="name"]');
}
