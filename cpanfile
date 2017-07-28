requires 'perl', '5.006';
requires 'strict';
requires 'warnings';
requires 'Carp';
requires 'Exporter::Tidy';

on build => sub {
    requires 'ExtUtils::MakeMaker::CPANfile';
};

on test => sub {
	requires 'Test::Differences';
	requires 'Test::More', '0.88';
};

# vim: ft=perl
