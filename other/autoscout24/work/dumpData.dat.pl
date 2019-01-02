#!/usr/bin/perl

use strict;
use warnings;
use Storable;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

my $G_DATA;

# $G_DATA = () unless $G_DATA;
die "../data.dat does not exist, aborting.\n" unless ( -e "../data.dat" );
$G_DATA = retrieve("../data.dat") or die;

print Dumper($G_DATA);
