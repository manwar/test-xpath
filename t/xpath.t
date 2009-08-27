#!/usr/bin/perl -w

use strict;
use Test::More tests => 8;
#use Test::More 'no_plan';

BEGIN { use_ok 'Test::XPath' or die; }

my $xml = '<foo><bar>first</bar><bar>post</bar></foo>';
my $html = '<html><head><title>Hello</title><body><p>first</p><p>post</p></body></html>';

ok my $xpath = Test::XPath->new(
    xml => $xml,
), 'Should be able to create an object';
isa_ok $xpath, 'Test::XPath';
isa_ok ${ $xpath }, 'XML::LibXML::Document';

ok +Test::XPath->new(
    xml         => $xml,
    no_network  => 1,
    keep_blanks => 1,
), 'Should be able to configure the parser';

ok $xpath = Test::XPath->new(
    html => $html,
), 'Should be able to parse HTML';
isa_ok $xpath, 'Test::XPath';
isa_ok ${ $xpath }, 'XML::LibXML::Document';

