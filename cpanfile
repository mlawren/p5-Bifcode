#!perl
requires 'boolean';
requires 'Carp';
requires 'Exporter::Tidy';
requires 'perl', '5.010';
requires 'strict';
requires 'utf8';
requires 'warnings';

feature 'diff-bifcode' => sub {
    requires 'OptArgs2';
    requires 'Text::Diff';
};

feature 'anyevent-handle' => sub {
    requires 'AnyEvent::Handle';
};

on configure => sub {
    requires 'ExtUtils::MakeMaker::CPANfile';
};

on develop => sub {
    requires 'App::githook::perltidy';
    requires 'AnyEvent::Handle';
    requires 'OptArgs2';
    requires 'Text::Diff';
    requires 'Text::Table::Tiny';
};

on test => sub {
    requires 'Test2::V0';
    suggests 'AnyEvent::Handle';
    suggests 'OptArgs2';
    suggests 'Text::Diff';
};

# vim: ft=perl
