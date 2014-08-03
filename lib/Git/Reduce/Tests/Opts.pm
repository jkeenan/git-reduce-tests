package Git::Reduce::Tests::Opts;
use strict;
use warnings;
use feature 'say';
use base qw( Exporter );
our @EXPORT_OK = qw(
    process_options
);
use Carp;
use Cwd;
use Data::Dumper;
use Getopt::Long;

sub process_options {
    my %opts;
    $opts{dir} = cwd();
    $opts{branch} = 'master';
    $opts{prefix} = 'reduced_';
    $opts{remote} = 'origin';
    $opts{no_delete} = 0;
    $opts{include} = '';
    $opts{exclude} = '';
    $opts{verbose} = 0;
    $opts{no_push} = 0;
    
    GetOptions(
        "dir=s" => \$opts{dir},
        "branch=s" => \$opts{branch},
        "prefix=s"  => \$opts{prefix},
        "remote=s"  => \$opts{remote},
        "no-delete"  => \$opts{no_delete}, # flag
        "no_delete"  => \$opts{no_delete}, # flag
        "include=s"  => \$opts{include},
        "exclude=s"  => \$opts{exclude},
        "verbose"  => \$opts{verbose}, # flag
        "no-push"  => \$opts{no_push}, # flag
        "no_push"  => \$opts{no_push}, # flag
    ) or croak("Error in command line arguments\n");
    say Dumper \%opts if $opts{verbose};
    
    croak("Could not locate directory $opts{dir}")
        unless (-d $opts{dir});
    if ($opts{include} and $opts{exclude}) {
        croak("'include' and 'exclude' options are mutually exclusive; choose one or the other");
    }
    return \%opts;
}

1;
