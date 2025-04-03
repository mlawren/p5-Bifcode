#!perl
requires 'boolean';
requires 'Carp';
requires 'Exporter::Tidy';
requires 'Math::BigInt'   => '1.999723';
requires 'Math::BigFloat' => '1.999723';
requires 'perl', '5.010';
requires 'strict';
requires 'utf8';
requires 'warnings';

feature 'diff-bifcode2' => sub {
    requires 'OptArgs2' => '2.0.0';
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
    requires 'OptArgs2' => '2.0.0';
    requires 'Text::Diff';
    requires 'Term::Table';
};

on test => sub {
    requires 'Test2::V0';
    requires 'Test2::Require::Module';
    suggests 'AnyEvent::Handle';
    suggests 'OptArgs2' => '2.0.0';
    suggests 'Text::Diff';
};

# vim: ft=perl
