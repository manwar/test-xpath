#!/usr/bin/perl -w

use strict;
use Test::More tests => 55;
#use Test::More 'no_plan';
use File::Spec::Functions 'catfile';
use utf8;

BEGIN { use_ok 'Test::XPath' or die; }

my $xml = '<foo xmlns="http://w3.org/ex"><bar>first</bar><bar>post</bar></foo>';
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

# Do some tests with it.
$xp->xpath_ok('/html/head/title', 'Should find the title');

# Try a recursive call.
$xp->xpath_ok( '/html/body/p', sub {
    shift->xpath_ok('./em', sub {
        $_->xpath_ok('./b', 'Find b under em');
    }, 'Find em under para');
}, 'Find paragraphs');

# Try is, like, and cmp_ok.
$xp->xpath_is( '/html/head/title', 'Hello', 'xpath_is should work');
$xp->xpath_isnt( '/html/head/title', 'Bye', 'xpath_isnt should work');
$xp->xpath_like( '/html/head/title', qr{^Hel{2}o$}, 'xpath_like should work');
$xp->xpath_unlike( '/html/head/title', qr{^Bye$}, 'xpath_unlike should work');
$xp->xpath_cmp_ok('/html/head/title', 'eq', 'Hello', 'xpath_cmp_ok should work');

# Try multiples.
$xp->xpath_is('/html/body/p', 'firstpost', 'Two values should concatenate');

# Try loading a file.
my $file = catfile qw(t menu.xml);
ok $xp = Test::XPath->new( file => $file ), 'Should create with file';

# Do some tests on the XML.
$xp->xpath_is('/menu/restaurant', 'Trébol', 'Should find Unicode value in file');

# Use recursive xpath_ok() to ensure all items have the appropriate parts.
my $i = 0;
$xp->xpath_ok('/menu/item', sub {
    ++$i;
    $_->xpath_ok('./name', "Item $i should have a name");
    $_->xpath_ok('./price', "Item $i should have a price");
    $_->xpath_ok('./description', "Item $i should have a description");
}, 'Should have items' );

# Hey, so no try using the doc param.
ok $xp = Test::XPath->new(
    doc => XML::LibXML->new->parse_file($file),
), 'Should create with doc';
$xp->xpath_is('/menu/restaurant', 'Trébol', 'Should find Unicode value in doc');

# Use a namespace.
ok $xp = Test::XPath->new(
    xml   => $xml,
    xmlns => { 'ex' => 'http://w3.org/ex' },
), 'Should create with real namespace';
$xp->xpath_ok('/ex:foo/ex:bar', 'We should find an ex:bar');
$xp->xpath_is('/ex:foo/ex:bar[1]', 'first', 'Should be able to check the first ex:bar value');
