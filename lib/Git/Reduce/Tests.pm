package Git::Reduce::Tests;
use strict;
use feature 'say';
our $VERSION = '0.01';
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
    my $branches = $self->_get_branches();
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
        $self->_dump_branches();
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
    find(
        sub { $_ =~ m/\.t$/ and push(@tfiles, $File::Find::name) },
        $self->{params}->{dir}
    );
    
    my (@includes, @excludes);
    if ($self->{params}->{include}) {
        @includes = split(',' => $self->{params}->{include});
        croak("Did not specify test files to be included in reduced branch")
            unless @includes;
    }
    if ($self->{params}->{exclude}) {
        @excludes = split(',' => $self->{params}->{exclude});
        croak("Did not specify test files to be exclude from reduced branch")
            unless @excludes;
    }
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
    return ($reduced_branch);
}

sub push_to_remote {
    my ($self, $reduced_branch) = @_;
    unless ($self->{params}->{no_push}) {
        local $@;
        eval { $self->{git}->push($self->{params}->{remote}, "+$reduced_branch"); };
        croak($@) if $@;
        say "Pushing '$reduced_branch' to $self->{params}->{remote}"
            if $self->{params}->{verbose};
    }
    say "Finished!" if $self->{params}->{verbose};
}

##### INTERNAL METHODS #####

sub _get_branches {
    my $self = shift;
    my @branches = $self->{git}->branch;
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

sub _dump_branches {
    my $self = shift;
    my $branches = $self->_get_branches();
    say Dumper $branches;
}

##### INTERNAL SUBROUTINE #####

sub check_status {
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
