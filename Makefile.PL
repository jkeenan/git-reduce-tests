

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Git::Reduce::Tests',
    VERSION_FROM => 'lib/Git/Reduce/Tests.pm', # finds \$VERSION
    AUTHOR       => 'James E Keenan (jkeenan@cpan.org)',
    ABSTRACT     => 'Create a branch with fewer test files for faster development',
    MIN_PERL_VERSION => '5.10.0',
    PREREQ_PM    => {
                     'Carp' => 0,
                     'Cwd' => 0,
                     'Data::Dumper' => 0,
                     'File::Find' => 0,
                     'Getopt::Long' => 0,
                     'Git::Wrapper' => 0.034,
                     'Test::Simple' => 0.44,
                    },
);
