# !perl
use strict;
use warnings;
use Test::More qw(no_plan);
use Git::Reduce::Tests;
use Git::Reduce::Tests::Opts qw(process_options);
use Data::Dumper;$Data::Dumper::Indent=1;

{
    my $params;
    my $self;
    my $start_branch = 'master';
    my $remote = 'origin';
    my $prefix = 'reduced_';
    
    $params = process_options(
        dir => '/home/jkeenan/gitwork/list-compare',
        include => join(',' => qw(
            t/90_oo_errors.t
            t/91_func_errors.t
         ) ),
        branch  => $start_branch,
        remote  => $remote,
        prefix  => $prefix,
        verbose => 1, 
    );
    $self = Git::Reduce::Tests->new($params);
    ok(defined($self), "new() returned defined value");
    isa_ok($self, 'Git::Reduce::Tests');
    
    my $reduced_branch;
    eval { $reduced_branch = $self->prepare_reduced_branch(); };
    ok(! $@, "prepare_reduced_branch() had no errors") or diag($@);
    is($reduced_branch, "$prefix$start_branch",
        "Got expected name for reduced branch");
    
    ok($self->push_to_remote($reduced_branch),
        "push_to_remote() returned true value");
}

{
    my $params;
    my $self;
    my $start_branch = 'master';
    my $remote = 'origin';
    my $suffix = '_reduced';
    
    $params = process_options(
        dir => '/home/jkeenan/gitwork/list-compare',
        include => join(',' => qw(
            t/90_oo_errors.t
            t/91_func_errors.t
         ) ),
        branch  => $start_branch,
        remote  => $remote,
        suffix  => $suffix,
        verbose => 1, 
    );
    $self = Git::Reduce::Tests->new($params);
    ok(defined($self), "new() returned defined value");
    isa_ok($self, 'Git::Reduce::Tests');
    
    my $reduced_branch;
    eval { $reduced_branch = $self->prepare_reduced_branch(); };
    ok(! $@, "prepare_reduced_branch() had no errors") or diag($@);
    is($reduced_branch, "$start_branch$suffix",
        "Got expected name for reduced branch");
    
    ok($self->push_to_remote($reduced_branch),
        "push_to_remote() returned true value");
}

