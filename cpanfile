#!perl
requires 'boolean';
requires 'Carp';
requires 'Exporter::Tidy';
requires 'perl', '5.010';
requires 'strict';
requires 'utf8';
requires 'warnings';

on configure => sub {
    requires 'ExtUtils::MakeMaker::CPANfile';
};

on develop => sub {
    requires 'App::githook::perltidy';
};

on test => sub {
    requires 'Test2::V0';
    suggests 'Text::Diff';
    suggests 'AnyEvent::Handle';
};

# vim: ft=perl
