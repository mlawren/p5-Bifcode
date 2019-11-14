#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Require::Module 'AnyEvent';
use Test2::V0;

use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;

my $host = '127.0.0.1';
my $port = 44244;

my $c_msg = { client => 2 };
my $s_msg = { server => 3 };
my $cv    = AE::cv;

my %connections;

tcp_server(
    $host, $port,
    sub {
        my ($fh) = @_;
        $cv->begin;

        note 'Server accepted connection';

        my $handle;
        $handle = AnyEvent::Handle->new(
            fh     => $fh,
            on_eof => sub {
                my ($aeh) = @_;
                note 'server received EOF';
                $aeh->destroy();
                $cv->end;
            },
            on_error => sub {
                my ( $aeh, $fatal, $msg ) = @_;

                AE::log error => "$msg";
                if ( $! == Errno::EBADMSG() ) {
                    $aeh->push_write(
                        Bifcode => { status => 'EBADMSG', msg => "$msg" } );
                }
                else {
                    $aeh->push_write("Internal Error\n");
                }

                $aeh->destroy;
                $cv->end;
            },
        );

        $handle->push_read(
            Bifcode => sub {
                is $_[1], $c_msg, 'server received c_msg';
                $handle->push_write( Bifcode => $s_msg );
                note 'server disconnecting';
                $handle->destroy();
                $cv->end;
                1;
            }
        );

        $connections{$handle} = $handle;    # keep it alive.

        return;
    }
);

my $aeh;
tcp_connect $host, $port, sub {
    my ($fh) = @_ or return skip_all "$host connect failed: $!";

    note 'Client connected';
    $cv->begin;

    $aeh = AnyEvent::Handle->new(
        fh     => $fh,
        on_eof => sub {
            my ($aeh) = @_;
            note 'client received EOF';
            $aeh->destroy();
            $cv->end;
        },
        on_error => sub {
            my ( $aeh, $fatal, $msg ) = @_;
            AE::log error => "$msg";
            $aeh->destroy;
            $cv->end;
        },
    );

    $aeh->push_write( Bifcode => $c_msg );

    $aeh->push_read(
        'Bifcode' => sub {
            my ( $aeh, $ref ) = @_;
            is $ref, $s_msg, 'client received s_msg';

            note 'client disconnecting';
            $aeh->destroy;
            $cv->end;
        }
    );

    1;
};

$cv->recv;

done_testing();
