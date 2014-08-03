package Git::Reduce::Tests;
use strict;
use feature 'say';
our $VERSION = '0.01';
#our @ISA = qw( Exporter );
#our @EXPORT_OK = qw( run push_to_remote );
use Git::Wrapper;
use Carp;
use Data::Dumper;$Data::Dumper::Indent=1;
use File::Find qw( find );

sub new {
    my ($class, $params) = @_;
    my %data;

    while (my ($k,$v) = each %{$params}) {
        $data{params}{$k} = $v;
    }
    $data{git} = Git::Wrapper->new($params->{dir});
    
    # Make sure we can check out the branch needing testing.
    check_status(\%data);
    {
        local $@;
        eval {$data{git}->checkout($data{params}->{branch}) };
        croak($@) if $@;
    }
    return bless \%data, $class;
}

sub prepare_reduced_branch {
    my $self = shift;

    # reduced_branch:  temporary branch whose test suite has been reduced in
    # size
    # Compose name for reduced_branch
    my $branches = get_branches($self->{git});
    my $reduced_branch = $self->{params}->{prefix} . $self->{params}->{branch};

    # Customarily, delete any existing branch with temporary branch's name.
    unless($self->{params}->{no_delete}) {
        if (exists($branches->{$reduced_branch})) {
            say "Deleting branch '$reduced_branch'" if $self->{params}->{verbose};
            $self->{git}->branch('-D', $reduced_branch);
        }
    }
    if ($self->{params}->{verbose}) {
        say "Current branches:";
        dump_branches($self->{git});
    }
    
    # Create the reduced branch.
    {
        local $@;
        eval { $self->{git}->checkout('-b', $reduced_branch); };
        croak($@) if $@;
        say "Creating branch '$reduced_branch'" if $self->{params}->{verbose};
    }
    
    # Locate all test files.
    my @tfiles = ();
    find( sub { $_ =~ m/\.t$/ and push(@tfiles, $File::Find::name) }, $self->{params}->{dir});
    
    my @includes = split(',' => $self->{params}->{include}) if $self->{params}->{include};
    my @excludes = split(',' => $self->{params}->{exclude}) if $self->{params}->{exclude};
    if ($self->{params}->{verbose}) {
        say "Test files:";
        say Dumper [ sort @tfiles ];
        if ($self->{params}->{include}) {
            say "Included test files:";
            say Dumper(\@includes);
        }
        if ($self->{params}->{exclude}) {
            say "Excluded test files:";
            say Dumper(\@excludes);
        }
    }
    # Create lookup tables for test files to be included in, 
    # or excluded from, the reduced branch.
    my %included = map { +qq{$self->{params}->{dir}/$_} => 1 } @includes;
say STDERR "XXX:";
say STDERR Dumper \%included;
    my %excluded = map { +qq{$self->{params}->{dir}/$_} => 1 } @excludes;
    my @removed = ();
    if ($self->{params}->{include}) {
        @removed = grep { ! exists($included{$_}) } sort @tfiles;
    }
    if ($self->{params}->{exclude}) {
        @removed = grep { exists($excluded{$_}) } sort @tfiles;
    }
    if ($self->{params}->{verbose}) {
        say "Test files to be removed:";
        say Dumper(\@removed);
    }
    
    # Remove undesired teste files and commit the reduced branch.
    $self->{git}->rm(@removed);
    $self->{git}->commit( '-m', "Remove unwanted test files" );
#    return ($self->{git}, $reduced_branch);
    return ($reduced_branch);
}

#sub push_to_remote {
##    my ($params, $git, $reduced_branch) = @_;
#    my ($self, $reduced_branch) = @_;
#    unless ($params->{no_push}) {
#        local $@;
#        eval { $git->push($params->{remote}, "+$reduced_branch"); };
#        croak($@) if $@;
#        say "Pushing '$reduced_branch' to $params->{remote}"
#            if $params->{verbose};
#    }
#    say "Finished!" if $params->{verbose};
#}
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
#    my ($git, $params) = @_;
    my $dataref = shift;
    my $statuses = $dataref->{git}->status;
    if (! $statuses->is_dirty) {
        say "git status okay" if $dataref->{params}->{verbose};
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
