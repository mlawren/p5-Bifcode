#!perl
requires 'perl', '5.010';
requires 'strict';
requires 'warnings';
requires 'utf8';
requires 'Carp';
requires 'Exporter::Tidy';
recommends 'Text::Diff';

on build => sub {
    requires 'ExtUtils::MakeMaker::CPANfile';
};

on test => sub {
    requires 'Test::Differences';
    requires 'Test::More', '0.88';
    requires 'Test::Needs';
};

# vim: ft=perl
