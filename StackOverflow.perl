#!/usr/bin/env perl
#********************************************************************
# NAME: Your Name
# ASGT: Activity 03
# ORGN: CSUB - CMPS 3500
# FILE: StackOverflow.perl
# DATE: MM/DD/YYYY
#********************************************************************

use strict;
use warnings;

use Getopt::Long qw(GetOptions);
use FindBin qw($Bin);
use lib $Bin;
use File::Spec;

use Tokenizer;
use Report;

my $help       = 0;
my $scope_demo = 0;
my $csv_path   = File::Spec->catfile($Bin, "StackOverflow.csv");

GetOptions(
    'scope-demo' => \$scope_demo,
    'help'       => \$help,
    'csv=s'      => \$csv_path,
) or usage();

usage() if $help;

if ($scope_demo) {
    run_scope_demo();
    exit 0;
}

if (!-e $csv_path) {
    die "ERROR: Could not find CSV file:\n  $csv_path\n";
}

eval {
    require Text::CSV;
    Text::CSV->import();
    1;
} or die "ERROR: Text::CSV is required for this program.\n";

open(my $fh, '<', $csv_path) or die "ERROR: Cannot open $csv_path: $!\n";

my $raw_header = <$fh>;
die "ERROR: Empty file or bad header\n" if !defined $raw_header;

$raw_header =~ s/^\xEF\xBB\xBF//;

my $sep_char = detect_separator($raw_header);

seek($fh, 0, 0) or die "ERROR: Could not rewind file: $!\n";

my $parser = Text::CSV->new({
    binary              => 1,
    sep_char            => $sep_char,
    allow_loose_quotes  => 1,
    allow_whitespace    => 1,
    auto_diag           => 0,
});

my $header_ref = $parser->getline($fh);
die "ERROR: Could not parse header row\n" if !defined $header_ref;

my @colnames = map {
    my $x = $_ // '';
    $x =~ s/^\xEF\xBB\xBF//;
    $x =~ s/^\s+|\s+$//g;
    $x;
} @$header_ref;

my $idx_tags  = find_col_index(\@colnames, qr/^tags$/i);
my $idx_label = find_col_index(\@colnames, qr/^(label|class|category|y)$/i);

my %domains_set;
my %emails_set;
my %lang_counts;
my $hq_count = 0;

while (my $row_ref = $parser->getline($fh)) {

    my @fields = @$row_ref;

    if ($idx_label >= 0 && $idx_label <= $#fields) {
        my $label = $fields[$idx_label] // '';
        $label =~ s/^\s+|\s+$//g;
        $hq_count++ if $label eq 'HQ';
    }

    my $full_row_text = join("\t", map { defined $_ ? $_ : '' } @fields);

    for my $domain (Tokenizer::extract_domains($full_row_text)) {
        $domains_set{$domain} = 1;
    }

    for my $email (Tokenizer::extract_emails($full_row_text)) {
        $emails_set{$email} = 1;
    }

    if ($idx_tags >= 0 && $idx_tags <= $#fields) {
        my $tag_field = $fields[$idx_tags] // '';
        my @tags = Tokenizer::extract_tags($tag_field);
        Report::increment_lang_counts(\%lang_counts, \@tags);
    }
}

close($fh);

write_lines_sorted("web_regex.txt", [ sort keys %domains_set ]);
write_lines_sorted("email_regex.txt", [ sort keys %emails_set ]);

print "\n";
print "1. There are " . (scalar keys %domains_set) . " unique website domains in StackOverflow.csv\n";
print "   web_regex.txt has been written...\n\n";

print "2. There are " . (scalar keys %emails_set) . " unique emails in StackOverflow.csv\n";
print "   email_regex.txt has been written...\n\n";

print "3. There are $hq_count high quality (HQ) entries in StackOverflow.csv\n\n";

print "4. The five most popular programming languages mentioned in the Tags column are:\n";

my @top5 = Report::top_k(\%lang_counts, 5);
my $rank = 1;

for my $pair (@top5) {
    my ($lang, $count) = @$pair;
    printf "   %d) %s : %d\n", $rank, $lang, $count;
    $rank++;
}

print "\n";

exit 0;

sub usage {
    print "Usage:\n";
    print "  ./StackOverflow.perl\n";
    print "  ./StackOverflow.perl --scope-demo\n";
    exit 1;
}

sub detect_separator {

    my ($line) = @_;

    my $tab_count   = () = $line =~ /\t/g;
    my $comma_count = () = $line =~ /,/g;

    return "\t" if $tab_count > $comma_count;
    return ",";
}

sub find_col_index {

    my ($cols_ref, $regex) = @_;

    for (my $i = 0; $i < @$cols_ref; $i++) {
        if (defined $cols_ref->[$i] && $cols_ref->[$i] =~ $regex) {
            return $i;
        }
    }

    return -1;
}

sub write_lines_sorted {

    my ($filename, $lines_ref) = @_;

    open(my $out, '>', $filename) or die "ERROR: Cannot write $filename: $!\n";

    for my $line (@$lines_ref) {
        next if !defined $line || $line eq '';
        print $out "$line\n";
    }

    close($out);
}

sub run_scope_demo {

    print "\n[Lexical demo]\n";

    my $x = 10;
    print "  outer x = $x\n";

    {
        my $x = 99;
        print "  inner x = $x\n";
    }

    print "  outer x (after block) = $x\n\n";

    print "[Package + dynamic rebinding demo]\n";
    print "  Tokenizer::STRIP_WWW (default) = $Tokenizer::STRIP_WWW\n";

    my $sample = "See https://www.example.com/path for details";

    my @d1 = Tokenizer::extract_domains($sample);
    print "  sample domain => " . ($d1[0] // '(none)') . "\n\n";

    {
        print "  (local override begins)\n";

        local $Tokenizer::STRIP_WWW = 0;

        print "  Tokenizer::STRIP_WWW (inside local) = $Tokenizer::STRIP_WWW\n";

        my @d2 = Tokenizer::extract_domains($sample);

        print "  sample domain => " . ($d2[0] // '(none)') . "\n";

        print "  (local override ends)\n\n";
    }

    print "  Tokenizer::STRIP_WWW (after local) = $Tokenizer::STRIP_WWW\n\n";
}
