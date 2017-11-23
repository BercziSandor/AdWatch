#!/bin/perl

package stopWatch;
our $g_stopWatch;

sub pause
{
    my ( $name ) = shift;
    if ( $g_stopWatch->{$name}->{start} ) {
        $g_stopWatch->{$name}->{elapsed} += ( Time::HiRes::time() - $g_stopWatch->{$name}->{start} );
    }
    $g_stopWatch->{$name}->{start} = undef;
    return;
} ### sub pause

sub info
{
    $log->info( "\nFutásidő összesítés:\n" );
    foreach my $name ( keys %$g_stopWatch ) {
        my $elapsed;
        $elapsed = $g_stopWatch->{$name}->{elapsed};
        if ( $g_stopWatch->{$name}->{start} ) {
            ${elapsed} += ( Time::HiRes::time() - $g_stopWatch->{$name}->{start} );
        }

        # $log->info( sprintf( " - %-15s %6.2fs (%.2felem/s)\n", $name, ${elapsed}, ( 0.0 + $G_ITEMS_PROCESSED / ${elapsed} ) ) );
    } ### foreach my $name ( keys %$g_stopWatch)
} ### sub info

sub readValue
{
    my ( $name ) = shift;
    my $elapsed;
    $elapsed = $g_stopWatch->{$name}->{elapsed} if $g_stopWatch->{$name}->{elapsed};
    $elapsed += ( Time::HiRes::time() - $g_stopWatch->{$name}->{start} ) if $g_stopWatch->{$name}->{start};
    $elapsed = 0 unless $elapsed;
    return sprintf( "%.2f", $elapsed );
} ### sub readValue

sub reset
{
    my ( $name ) = shift;
    if ( $name ) {
        $g_stopWatch->{$name}->{start}   = undef;
        $g_stopWatch->{$name}->{elapsed} = 0;
    } else {
        $g_stopWatch = ();
    }
} ### sub reset

sub continue
{
    my ( $name ) = shift;
    $g_stopWatch->{$name}->{start} = Time::HiRes::time();

    # $g_stopWatch->{$name}->{elapsed} = 0;
} ### sub continue


return 1;