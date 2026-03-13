package Tokenizer;

use strict;
use warnings;

# Required Chapter 5 artifact: package variable (shared within package scope)
our $STRIP_WWW = 1;

# -------------------------
# Chapter 3 regex extractors
# -------------------------

# extract_domains($text) -> list of unique-ish domains found in $text
# Notes:
# - Capturing groups are used here.
# - /g global matching is used.
# - s/// substitution is used for normalization.
sub extract_domains {
  my ($text) = @_;
  return () if !defined $text;

  my %seen;

  # Find hostnames after http(s)://
  # Capture group 1 = host
  while ($text =~ m{https?://([A-Za-z0-9.-]+\.[A-Za-z]{2,})(?::\d+)?(?:/|$)}gi) {
    my $host = $1;

    # Normalize: lowercase
    $host = lc $host;

    # Normalize: remove leading www. if enabled (package var)
    if ($STRIP_WWW) {
      $host =~ s/^www\.//i;   # substitution s///
    }

    # Optional: anchored validation (meaningful ^...$)
    next if $host !~ /^[a-z0-9][a-z0-9.-]*\.[a-z]{2,}$/;

    $seen{$host} = 1;
  }

  return sort keys %seen;
}

# extract_emails($text) -> list of emails found in $text
sub extract_emails {
  my ($text) = @_;
  return () if !defined $text;

  my %seen;

  # Capture local-part and domain separately (2 capturing groups)
  while ($text =~ /([A-Za-z0-9._%+\-]+)\@([A-Za-z0-9.\-]+\.[A-Za-z]{2,})/g) {
    my $local = $1;
    my $dom   = $2;

    my $email = lc("$local\@$dom");

    # Anchored validation (meaningful ^...$)
    next if $email !~ /^[a-z0-9._%+\-]+\@[a-z0-9.\-]+\.[a-z]{2,}$/;

    $seen{$email} = 1;
  }

  return sort keys %seen;
}

# extract_tags($tag_field) -> list of tags from a field like "<java><python>"
# Return lowercased tags (no angle brackets)
sub extract_tags {
    my ($tag_field) = @_;
    return () if !defined $tag_field;

    my %seen;
    # common Languages
    my %valid_lang = map { $_ => 1 } (
    "c","c++","c#","java","javascript","python","php",
    "ruby","go","rust","kotlin","swift","typescript",
    "scala","perl","matlab","r","dart","objective-c",
    "fortran","lisp","scheme","clojure","haskell","ocaml",
    "erlang","elixir","julia","nim","zig",
    "assembly","asm","vhdl","verilog",
    "pascal","ada","cobol",
    "f#","groovy","powershell","bash","shell",
    "sql","plsql","tcl","smalltalk","crystal","basic","visualbasic"
    );

    while ($tag_field =~ /<([^>]+)>/g) {
        my $tag = lc $1;
        $tag =~ s/^\s+|\s+$//g;

        next if $tag eq '';
        next if !$valid_lang{$tag};   # filter non-languages

        $seen{$tag} = 1;
    }

    return sort keys %seen;
}

1;  # end of package
