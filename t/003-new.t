# !perl
use strict;
use warnings;
use Test::More qw(no_plan);
use Git::Reduce::Tests;
use Git::Reduce::Tests::Opts qw(process_options);
use Data::Dumper;$Data::Dumper::Indent=1;
use Cwd;

my $params = {};
my @include_args = ("--include", "xt/git/001-load.t"); 

{
    local @ARGV = (@include_args);
    $params = process_options();
    my $self = Git::Reduce::Tests->new($params);
    ok(defined($self), "new() returned defined value");
    isa_ok($self, 'Git::Reduce::Tests');
}
