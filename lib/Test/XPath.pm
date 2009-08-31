package Test::XPath;

use strict;
use 5.8.8;
use XML::LibXML '1.69';
use Test::Builder;

our $VERSION = '0.01';

sub new {
    my ($class, %p) = @_;
    my $doc = delete $p{doc} || _doc(\%p);
    my $xpc = XML::LibXML::XPathContext->new( $doc->documentElement );
    if (my $ns = $p{xmlns}) {
        while (my ($k, $v) = each %{ $ns }) {
            $xpc->registerNs( $k => $v );
        }
    }
    return bless {
        xpc  => $xpc,
        node => $doc->documentElement,
    };
}

sub ok {
    my ($self, $xpath, $code, $desc) = @_;
    my $xpc  = $self->{xpc};
    my $Test = Test::Builder->new;

    if (ref $code eq 'CODE') {
        # Gonna do some recursive testing.
        my @nodes = $xpc->findnodes($xpath, $self->{node})
            or return $Test->ok(0, $desc);

        # Record the current test result.
        my $ret  = $Test->ok(1, $desc);

        # Call the code ref on each found node.
        local $_ = $self;
        for my $node (@nodes) {
            local $self->{node} = $node;
            $code->($self);
        }
        return $ret;
    } else {
        # We're just testing for existence ($code is description).
        $Test->ok( $xpc->exists($xpath, $self->{node}), $code);
    }

}

sub node { shift->{node} }
sub xpc  { shift->{xpc}  }

sub is {
    Test::Builder::new->is_eq( _findv(shift, shift), @_);
}

sub isnt {
    Test::Builder::new->isnt_eq( _findv(shift, shift), @_);
}

sub like {
    Test::Builder::new->like( _findv(shift, shift), @_);
}

sub unlike {
    Test::Builder::new->unlike( _findv(shift, shift), @_);
}

sub cmp_ok {
    Test::Builder::new->cmp_ok( _findv(shift, shift), @_);
}

sub _findv {
    my $self = shift;
    $self->{xpc}->findvalue(shift, $self->{node});
}

sub _doc {
    my $p = shift;

    # Create and configure the parser.
    my $parser = XML::LibXML->new;

    # Apply any parser options.
    if (my $opts = $p->{options}) {
        while (my ($k, $v) = each %{ $opts }) {
            $parser->$k($v);
        }
    }

    # Parse and return the document.
    if ($p->{xml}) {
        return $p->{is_html}
            ? $parser->parse_html_string($p->{xml})
            : $parser->parse_string($p->{xml});
    }

    if ($p->{file}) {
        return $p->{is_html}
            ? $parser->parse_html_file($p->{file})
            : $parser->parse_file($p->{file});
    }

    require Carp;
    Carp::carp(
        'Test::XPath->new requires the "xml", "file", or "doc" parameter'
    );
}

1;
__END__

=begin comment

Fake-out Module::Build. Delete if it ever changes to support =head1 headers
other than all uppercase.

=head1 NAME

Test::XPath - Test XML and HTML content and structure with XPath expressions

=end comment

=head1 Name

Test::XPath - Test XML and HTML content and structure with XPath expressions

=head1 Synopsis

  use Test::More tests => 5;
  use Test::XPath;

  my $xml = <<'XML';
  <html>
    <head>
      <title>Hello</title>
      <style type="text/css" src="foo.css"></style>
      <style type="text/css" src="bar.css"></style>
    </head>
    <body>
      <h1>Welcome to my lair.</h1>
    </body>
  </html>
  XML

  my $tx = Test::XPath->new( xml => $xml );

  $tx->ok( '/html/head', 'There should be a head' );
  $tx->is( '/html/head/title', 'Hello', 'The title should be correct' );

  # Recursing into a document:
  my @css = qw(foo.css bar.css);
  $tx->ok( '/html/head/style[@type="text/css"]', sub {
      my $css = shift @css;
      shift->is( './@src', $css, "Style src should be $css");
  }, 'Should have style');

=head1 Description

Use the power of XPath expressions to validate the structure of your XML and
HTML documents.

=head2 About XPath

XPath is a powerful query language for XML documents. Test::XPath relies on
the libxml2 implementation provided by L<XML::LibXML|XML::LibXML>. This is a
complete implementation of the XPath spec, and is nice and efficient.

XPath works by selecting nodes in an XML document. Nodes, in general,
correspond to the elements (or tags, if you prefer) defined in the XML. The
W3Schools tutorial, L<http://www.w3schools.com/Xpath/default.asp> -- especially
the part on syntax, L<http://www.w3schools.com/Xpath/xpath_syntax.asp> --
provides a nice overview of XPath. See the XPath 1.0 W3C Recommendation,
L<http://www.w3.org/TR/xpath>, for thorough (and quite readable)
documentation.

=head2 Testing HTML

If you want to use XPath to test the content and structure of an HTML document,
be sure to pass the C<is_html> option to C<new()>, like so:

  my $xp = Test::XPath->new( xml => $html, is_html => 1 );

Test::XPath will then use XML::LibXML's HTML parser to parser the document,
rather than its XML parser. The upshot is that you won't have to worry about
namespace prefixes, and XML::LibXML won't try to fetch any DTD specified in
the DOCTYPE section of your HTML.

=head1 Class Interface

=head2 Constructor

=head3 C<new>

  my $xp = Test::XPath->new( xml => $xml );

Creates and returns an XML::XPath object. This object can be used to run XPath
tests on the XML passed to it. The supported parameters are:

=over

=item C<xml>

  xml => '<foo><bar>hey</bar></foo>',

The XML to be parsed and tested. Required unless the C<file> or C<doc> option
is passed.

=item C<file>

  file => 'rss.xml',

Name of a file containing the XML to be parsed and tested. Required unless the
C<xml> or C<doc> option is passed.

=item C<doc>

  doc => XML::LibXML->new->parse_file($xml_file),

An XML::LibXML document object. Required unless the C<xml> or C<file> option
is passed.

=item C<is_html>

  is_html => 1,

If the XML you're testing is actually HTML, pass this option a true value and
XML::LibXML's HTML parser will be used instead of the XML parser. This is
especially useful if your HTML has a DOCTYPE declaration or an XML namespace
(xmlns attribute) and you don't want the parser grabbing the DTD over the
Internet and you don't want to mess with a namespace prefix in your XPath
expressions.

=item C<xmlns>

  xmlns => {
      x => 'http://www.w3.org/1999/xhtml',
      a => 'http://www.w3.org/2007/app',
  },

Set up prefixes for XML namespaces. Required if your XML uses namespaces and
you want to write reasonable XPath expressions.

=item C<options>

  options => { recover_silently => 1, no_network => 1 },

Optional hash reference of
L<XML::LibXML::Parser options|XML::LibXML::Parser/"PARSER OPTIONS">, such as
"validation", "recover", and "no_network".

=back

=head1 Instance Interface

=head2 Assertions

=head3 C<ok>

  $xp->ok( '//foo/bar', 'Should have bar element under foo element' );
  $xp->ok('/contains(//title, "Welcome")', 'Title should contain "Welcome"');

Test that an XPath expression evaluated against the XML document returns a
true value. If the XPath expression finds no nodes, the result will be false.
If it finds a value, the value must be a true value (in the Perl sense).

  $xp->ok('//assets/story', sub {
      my $i;
      for my $story (@_) {
          $story->is('[@id]/text()', ++$i, "ID should be $i in story" );
      }
  }, 'Should have story elements' );

=head3 C<is>

  $xp->is('/html/head/title', 'Welcome');

=head3 C<isnt>

  $xp->isnt('/html/head/link/@type', 'hello');

=head3 C<like>

  $xp->like('/html/head/title', qr/^Foobar Inc.: .+/);

=head3 C<unlike>

  $xp->unlike()

=head3 C<cmp_ok>

  $xp->cmp_ok()

=head2 Accessors

=head3 C<node>

Returns the current context node.

=head3 C<xpc>

Returns the L<XML::LibXML::XPathContext|XML::LibXML::XPathContext> used to
execute the XPath expressions.

=head1 See Also

=over

=item *

L<http://www.w3schools.com/Xpath/default.asp> - The W3Schools XPath Tutorial

=item *

L<XML::LibXML::XPathContext|XML::LibXML::XPathContext> - The XML::LibXML
XPath evaluation library.

=item *

L<http://www.w3.org/TR/xpath> - XML Path Language (XPath) Version 1.0 W3C
Recommendation

=item *

L<Test::XML::XPath|Test::XML::XPath> - Another library for testing XPath
assertions using a functional interface. Ships with L<Test::XML|Test::XML>.

=back

=head1 Support

This module is stored in an open GitHub repository,
L<http://github.com/theory/test-xpath/tree/>. Feel free to fork and
contribute!

Please file bug reports at L<http://github.com/theory/test-xpath/issues/>.

=head1 Author

=begin comment

Fake-out Module::Build. Delete if it ever changes to support =head1 headers
other than all uppercase.

=head1 AUTHOR

=end comment

=over

=item David E. Wheeler <david@kineticode.com>

=back

=head1 Copyright and License

Copyright (c) 2009 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

