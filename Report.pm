#********************************************************************
# NAME: Sayed Jalal Sayed M Nasim
# ASGT: Activity 03
# ORGN: CSUB - CMPS 3500
# FILE: StackOverflow.perl
# DATE: 03/13/2025
#********************************************************************

package Report;

use strict;
use warnings;

# increment_lang_counts(\%counts, \@langs_in_row)
# Count each language at most once per row.
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

# top_k(\%counts, $k) -> array of [item, count] pairs
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

1; #end of package
