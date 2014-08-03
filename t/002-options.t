# !perl
use strict;
use warnings;
use Test::More qw(no_plan);
use Git::Reduce::Tests::Opts qw(process_options);
use Data::Dumper;$Data::Dumper::Indent=1;
use feature 'say';
use Cwd;

my ($params);

$params = process_options();
for my $o ( qw|
    dir
    branch
    prefix
    remote
    no_delete
    no_push
    verbose
    | ) {
    ok(defined $params->{$o}, "'$o' option defined");
}
for my $o ( qw|
    include
    exclude
    | ) {
    ok(! $params->{$o}, "'$o' option empty");
}

{
    my $phony_dir = "/tmp/abcdefghijklmnop_foobar";
    local @ARGV = ("--dir", $phony_dir, "verbose");
    local $@;
    eval { $params = process_options(); };
    like($@, qr/Could not locate directory $phony_dir/,
        "Die on non-existent directory $phony_dir provided on command-line");
}

{
    my $phony_dir = "/tmp/abcdefghijklmnop_foobar";
    local $@;
    eval { $params = process_options("dir" => $phony_dir); };
    like($@, qr/Could not locate directory $phony_dir/,
        "Die on non-existent directory $phony_dir provided to process_options()");
}

{
    my $cwd = cwd();
    my $phony_dir = "/tmp/abcdefghijklmnop_foobar";
    local @ARGV = ("--dir", $phony_dir);
    $params = process_options("dir" => $cwd);
    is($params->{dir}, $cwd,
        "Argument provided directly to process_options supersedes command-line argument");
}

{
    my $include = "t/001-load.t";
    my $exclude = "t/999-load.t";
    local $@;
    eval { $params = process_options(
        'include'   => $include,
        'exclude'   => $exclude,
    ); };
    like($@,
        qr/'include' and 'exclude' options are mutually exclusive; choose one or the other/,
        "Die on provision of both 'include' and 'exclude' options"
    );
}

SKIP: {
    my ($stdout);
    eval { require IO::CaptureOutput; };
    skip "IO::CaptureOutput not installed", 1 if $@;
    IO::CaptureOutput::capture(
        sub { $params = process_options( "verbose" => 1 ); },
        \$stdout,
    );
    like($stdout, qr/'verbose'\s*=>\s*1/s,
        "Got expected verbose output: arguments to process_options()");
}

SKIP: {
    my ($stdout);
    eval { require IO::CaptureOutput; };
    skip "IO::CaptureOutput not installed", 1 if $@;
    local @ARGV = ("--verbose");
    IO::CaptureOutput::capture(
        sub { $params = process_options(); },
        \$stdout,
    );
    like($stdout, qr/'verbose'\s*=>\s*1,/s,
        "Got expected verbose output: command-line argument");
}

{
    my $include = "t/001-load.t";
    my $exclude = "t/999-load.t";
    local $@;
    eval { $params = process_options(
        'include'   => $include,
        'exclude',
    ); };
    like($@,
        qr/Must provide even list of key-value pairs to process_options/,
        "Die on odd number of arguments to process_options()"
    );
    $@ = undef;

    $params = process_options( 'include'   => $include );
    is($params->{include}, $include, "Got expected include");
}

