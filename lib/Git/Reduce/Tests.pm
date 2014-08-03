package Git::Reduce::Tests;
use strict;
use feature 'say';
our $VERSION = '0.01';
our @ISA = qw( Exporter );
our @EXPORT_OK = qw( run );
use Git::Wrapper;
use Carp;
use Data::Dumper;$Data::Dumper::Indent=1;
use File::Find qw( find );

sub run {
    my $opts = shift;
    my @includes = split(',' => $opts->{include}) if $opts->{include};
    my @excludes = split(',' => $opts->{exclude}) if $opts->{exclude};

    my $git = Git::Wrapper->new($opts->{dir});
    
    check_status($git, $opts);
    {
        local $@;
        eval {$git->checkout($opts->{branch}) };
        croak($@) if $@;
    }
    
    my $branches = get_branches($git);
    my $reduced_branch = $opts->{prefix} . $opts->{branch};
    unless($opts->{no_delete}) {
        if (exists($branches->{$reduced_branch})) {
            say "Deleting branch '$reduced_branch'" if $opts->{verbose};
            $git->branch('-D', $reduced_branch);
        }
    }
    if ($opts->{verbose}) {
        say "Current branches:";
        dump_branches($git);
    }
    
    {
        local $@;
        eval { $git->checkout('-b', $reduced_branch); };
        croak($@) if $@;
        say "Creating branch '$reduced_branch'" if $opts->{verbose};
    }
    
    my @tfiles = ();
    sub wanted {
        $_ =~ m/\.t$/ and push(@tfiles, $File::Find::name);
    }
    find(\&wanted, $opts->{dir});
    
    if ($opts->{verbose}) {
        say "Test files:";
        say Dumper [ sort @tfiles ];
        if ($opts->{include}) {
            say "Included test files:";
            say Dumper(\@includes);
        }
        if ($opts->{exclude}) {
            say "Excluded test files:";
            say Dumper(\@excludes);
        }
    }
    my %included = map { +qq{$opts->{dir}/$_} => 1 } @includes;
    my %excluded = map { +qq{$opts->{dir}/$_} => 1 } @excludes;
    my @removed = ();
    if ($opts->{include}) {
        @removed = grep { ! exists($included{$_}) } sort @tfiles;
    }
    if ($opts->{exclude}) {
        @removed = grep { exists($excluded{$_}) } sort @tfiles;
    }
    if ($opts->{verbose}) {
        say "Test files to be removed:";
        say Dumper(\@removed);
    }
    
    $git->rm(@removed);
    $git->commit( '-m', "Remove unwanted test files" );
    unless ($opts->{no_push}) {
        local $@;
        eval { $git->push($opts->{remote}, "+$reduced_branch"); };
        croak($@) if $@;
        say "Pushing '$reduced_branch' to $opts->{remote}"
            if $opts->{verbose};
    }
    say "Finished!" if $opts->{verbose};
}

##### INTERNAL SUBROUTINES #####

sub get_branches {
    my $git = shift;
    my @branches = $git->branch;
    my %branches;
    
    for (@branches) {
        if (m/^\*\s+(.*)/) {
            my $br = $1;
            $branches{$br} = 'current';
        }
        else {
            if (m/^\s+(.*)/) {
                my $br = $1;
                $branches{$br} = 1;
            }
            else {
                croak "Could not get branch";
            }
        }
    }
    return \%branches;
}

sub dump_branches {
    my $git = shift;
    my $branches = get_branches($git);
    say Dumper $branches;
}

sub check_status {
    my ($git, $opts) = @_;
    my $statuses = $git->status;
    if (! $statuses->is_dirty) {
        say "git status okay" if $opts->{verbose};
        return 1;
    }
    my $msg = '';
    for my $type (qw<indexed changed unknown conflict>) {
        my @states = $statuses->get($type)
            or next;
        $msg .= "Files in state $type\n";
        for (@states) {
            $msg .= '  ' . $_->mode . ' ' . $_->from;
            if ($_->mode eq 'renamed') {
                $msg .= ' renamed to ' . $_->to;
            }
            $msg .= "\n";
        }
    }
    croak($msg);
}

1;

