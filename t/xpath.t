#!/usr/bin/perl -w

use strict;
use Test::Builder::Tester tests => 16;
use Test::More;

BEGIN { use_ok 'Test::XPath' or die; }

my $xml = '<foo><bar>first</bar><bar>post</bar></foo>';
my $html = '<html><head><title>Hello</title><body><p><em><b>first</b></em></p><p><em><b>post</b></em></p></body></html>';

ok my $xp = Test::XPath->new(
    xml => $xml,
), 'Should be able to create an object';
isa_ok $xp, 'Test::XPath';
isa_ok $xp->{xpc}, 'XML::LibXML::XPathContext';

ok +Test::XPath->new(
    xml         => $xml,
    options     => {
        no_network  => 1,
        keep_blanks => 1,
    },
), 'Should be able to configure the parser';

ok $xp = Test::XPath->new(
    xml     => $html,
    is_html => 1,
), 'Should be able to parse HTML';
isa_ok $xp, 'Test::XPath';
isa_ok $xp->{xpc}, 'XML::LibXML::XPathContext';

# Try successful xpath_ok.
test_out( 'ok 1 - whatever');
$xp->xpath_ok('/html/head/title', 'whatever');
test_test('xpath_ok works');

# Try failed xpath_ok.
test_out('not ok 1 - whatever');
test_err(qq{#   Failed test 'whatever'\n#   at t/xpath.t line 41.});
$xp->xpath_ok('/html/head/foo', 'whatever');
test_test('xpath_ok fail works');

# Try a recursive call.
test_out( 'ok 1 - p');
test_out( 'ok 2 - em');
test_out( 'ok 3 - b');
test_out( 'ok 4 - em');
test_out( 'ok 5 - b');
$xp->xpath_ok( '/html/body/p', sub {
    shift->xpath_ok('./em', sub {
        $_->xpath_ok('./b', 'b');
    }, 'em');
}, 'p');
test_test('recursive xpath_ok should work');

# Try is, like, and cmp_ok.
$xp->xpath_is( '/html/head/title', 'Hello', 'xpath_is should work');
$xp->xpath_isnt( '/html/head/title', 'Bye', 'xpath_isnt should work');
$xp->xpath_like( '/html/head/title', qr{^Hel{2}o$}, 'xpath_like should work');
$xp->xpath_unlike( '/html/head/title', qr{^Bye$}, 'xpath_unlike should work');
$xp->xpath_cmp_ok('/html/head/title', 'eq', 'Hello', 'xpath_cmp_ok should work');
