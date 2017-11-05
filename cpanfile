#!perl
requires 'perl', '5.010';
requires 'strict';
requires 'warnings';
requires 'utf8';
requires 'Carp';
requires 'Exporter::Tidy';

on configure => sub {
    requires 'ExtUtils::MakeMaker::CPANfile';
    requires 'Pod::Text';
};

on test => sub {
    requires 'Text::Diff';
    requires 'Test::More', '0.88';
    requires 'Test::Needs';
};

# vim: ft=perl
