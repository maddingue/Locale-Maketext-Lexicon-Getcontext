#!perl
use v5.14;
use strict;
use warnings;
use Test::More;


opendir my $dh, "t/po/off-common/"
    or die "can't read directory 't/po/off-common/': $!";
my @files = map "t/po/off-common/$_", grep {!/^\./} readdir $dh;
closedir $dh;

my %lang = (
    en  => "English",
    he  => "Hebrew",
    fr  => "French",
    ja  => "Japanese",
);

plan tests => 1 + 3 * @files;

my $module = "Locale::Maketext::Lexicon::Getcontext";

use_ok $module;

for my $file (@files) {
    # read & parse the .po
    open my $fh, "<", $file or die "can't read file '$file': $!";

    my $lexicon = eval { $module->parse(<$fh>) };
    is $@, "", "$module->parse(<$file>)";

    close $fh;

    # check some fields
    my ($lc) = $file =~ m:/([a-z]+)\.po$:;
    is $lexicon->{":langtag"}, $lc, ":langtag = $lc";
    is $lexicon->{":langname"}, $lang{$lc}, ":langname = $lang{$lc}";
}

