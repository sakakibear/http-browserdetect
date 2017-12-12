#!/usr/bin/perl

use strict;
use warnings;

use Test::Most;
use Test::FailWarnings;

use FindBin;
use JSON::PP;
use Path::Tiny qw( path );

# test that the module loads without errors
my $w;
{
    local $SIG{__WARN__} = sub { $w = shift };
    require HTTP::BrowserDetect;
}
ok( !$w, 'no warnings on require' );

my $json  = path("$FindBin::Bin/useragents.json")->slurp;
my $tests = JSON::PP->new->ascii->decode($json);

$json = path("$FindBin::Bin/more-useragents.json")->slurp;
my $more_tests = JSON::PP->new->ascii->decode($json);
$tests = { %$tests, %$more_tests };

foreach my $ua ( sort ( keys %{$tests} ) ) {

    my $test = $tests->{$ua};

    my $detected = HTTP::BrowserDetect->new($ua);
    subtest $ua => sub {

        foreach my $method (
            'browser', 'browser_string', 'browser_beta',
            'device', 'device_name',   'device_string', 'device_beta',
            'engine', 'engine_string', 'engine_beta',
            'language',
            'os', 'os_string', 'os_beta',
            'robot', 'robot_name', 'robot_string', 'robot_beta',
            ) {
            if ( $test->{$method} ) {
                cmp_ok(
                    $detected->$method, 'eq', $test->{$method},
                    "$method: $test->{$method}"
                );
            }
        }

        foreach my $method (
            qw(
            os_version
            os_major
            os_minor
            public_version
            public_major
            public_minor
            robot_version
            robot_major
            robot_minor
            version
            major
            minor
            engine_version
            engine_major
            engine_minor
            ios
            tablet
            )
            ) {

            if (    exists $test->{$method}
                and defined $test->{$method}
                and length $test->{$method} ) {
                cmp_ok(
                    $detected->$method, '==', $test->{$method},
                    "$method: $test->{$method}"
                );
            }
        }

        foreach my $type ( @{ $test->{match} } ) {
            ok( $detected->can($type) && $detected->$type, "$type should match" );
        }

        is_deeply(
            [ sort $detected->browser_properties() ],
            [ sort @{ $test->{match} } ],
            "browser properties match"
        );

        # Test that $ua doesn't match a specific method
        foreach my $type ( @{ $test->{no_match} } ) {
            ok( !$detected->$type, "$type shouldn't match (and doesn't)" );
        }

    };
}

my $detected = HTTP::BrowserDetect->new('Nonesuch');
diag( $detected->user_agent );

foreach my $method (
    qw(
    engine_string
    engine_version
    engine_major
    engine_minor
    device
    device_name
    gecko_version
    )
    ) {
    is_deeply(
        [ $detected->$method ],
        [undef], "$method should return undef in list context"
    );
}

done_testing();
