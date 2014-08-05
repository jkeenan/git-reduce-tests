# !perl
use strict;
use warnings;
use Test::More tests => 29;
use Git::Reduce::Tests::Opts qw(process_options);
use Data::Dumper;$Data::Dumper::Indent=1;
use Cwd;

my $params = {};
my @include_args = ("--include", "t/001-load.t"); 

{
    local @ARGV = (@include_args);
    $params = process_options();
    for my $o ( qw|
        dir
        branch
        prefix
        remote
        no_delete
        no_push
        verbose
        test_suffix
        | ) {
        ok(defined $params->{$o}, "'$o' option defined");
    }
    ok(  length($params->{include}), "'include' option populated");
    ok(! length($params->{exclude}), "'exclude' option not populated");
}

{
    my $branch = 'develop';
    my $prefix = 'smoke-me/';
    my $remote = 'upstream';
    my $no_delete = 1;
    my $no_push = 1;
    my $test_suffix = 'test';
    local @ARGV = (
        @include_args,
        '--branch' => $branch,
        '--prefix' => $prefix,
        '--remote' => $remote,
        '--no_delete' => $no_delete,
        '--no_push' => $no_push,
        '--test_suffix' => $test_suffix,
    );
    $params = process_options();
    is($params->{branch}, $branch, "Got explicitly set branch");
    is($params->{prefix}, $prefix, "Got explicitly set prefix");
    is($params->{remote}, $remote, "Got explicitly set remote");
    is($params->{no_delete}, $no_delete, "Got explicitly set no_delete");
    is($params->{no_push}, $no_push, "Got explicitly set no_push");
    is($params->{test_suffix}, $test_suffix, "Got explicitly set test_suffix");
}

{
    my $no_delete = 1;
    my $no_push = 1;
    my $test_suffix = 'test';
    local @ARGV = (
        @include_args,
        '--no-delete' => $no_delete,
        '--no-push' => $no_push,
        '--test-suffix' => $test_suffix,
    );
    $params = process_options();
    is($params->{no_delete}, $no_delete, "Got explicitly set no-delete");
    is($params->{no_push}, $no_push, "Got explicitly set no-push");
    is($params->{test_suffix}, $test_suffix, "Got explicitly set test-suffix");
}

{
    my $phony_dir = "/tmp/abcdefghijklmnop_foobar";
    local @ARGV = ("--dir", $phony_dir, "verbose", @include_args);
    local $@;
    eval { $params = process_options(); };
    like($@, qr/Could not locate directory $phony_dir/,
        "Die on non-existent directory $phony_dir provided on command-line");
}

{
    my $phony_dir = "/tmp/abcdefghijklmnop_foobar";
    local $@;
    eval { $params = process_options("dir" => $phony_dir, @include_args); };
    like($@, qr/Could not locate directory $phony_dir/,
        "Die on non-existent directory $phony_dir provided to process_options()");
}

{
    my $cwd = cwd();
    my $phony_dir = "/tmp/abcdefghijklmnop_foobar";
    local @ARGV = ("--dir", $phony_dir, @include_args);
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
    local @ARGV = (@include_args);
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
    local @ARGV = ("--verbose", @include_args);
    IO::CaptureOutput::capture(
        sub { $params = process_options(); },
        \$stdout,
    );
    like($stdout, qr/'verbose'\s*=>\s*1/s,
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
    $params = undef;
    $params = process_options( 'exclude'   => $exclude );
    is($params->{exclude}, $exclude, "Got expected exclude");

    $include = '';
    $exclude = '';
    local $@;
    eval { $params = process_options(
        'include'   => $include,
        'exclude'   => $exclude,
    ); };
    like($@,
        qr/Must populate one of 'include' or 'exclude' with test files/,
        "Die on failure to populate one of 'include' or 'exclude'",
    );
}

