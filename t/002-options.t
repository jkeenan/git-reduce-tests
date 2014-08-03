# !perl
use strict;
use warnings;
use Test::More qw(no_plan);
use Git::Reduce::Tests::Opts qw(process_options);

my $opts = process_options();
for my $o ( qw|
    dir
    branch
    prefix
    remote
    no_delete
    no_push
    verbose
    | ) {
    ok(defined $opts->{$o}, "'$o' option defined");
}
if ($opts->{include}) {
    ok(! $opts->{exclude}, "'include' precludes 'exclude'");
}
if ($opts->{exclude}) {
    ok(! $opts->{include}, "'exclude' precludes 'include'");
}
