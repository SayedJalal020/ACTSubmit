package Report;

use strict;
use warnings;

sub increment_lang_counts {
    my ($counts_ref, $langs_ref) = @_;
    return if !defined $counts_ref || !defined $langs_ref;

    my %seen_in_row;

    for my $lang (@$langs_ref) {
        next if !defined $lang || $lang eq '';
        next if $seen_in_row{$lang}++;
        $counts_ref->{$lang}++;
    }
}

sub top_k {
    my ($counts_ref, $k) = @_;
    $k = 5 if !defined $k || $k !~ /^\d+$/;

    my @pairs = map { [ $_, $counts_ref->{$_} ] } keys %{$counts_ref};

    @pairs = sort {
        $b->[1] <=> $a->[1]
        ||
        $a->[0] cmp $b->[0]
    } @pairs;

    splice(@pairs, $k) if @pairs > $k;

    return @pairs;
}

1;
