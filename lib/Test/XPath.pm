package Test::XPath;

use strict;
use 5.6.2;
use XML::LibXML '1.69';
use Test::Builder;

our $VERSION = '0.10';

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
correspond to the elements (or tags, if you prefer) defined in the XML, text
within those elements, attribute values, and comments. The expressions for
making such selections use a file-system-type syntax, the basics of which are:

=over

=item C<$nodename>

Selects all child nodes with the name.

=item C</>

Selects the root node.

=item C<//>

Selects nodes from the current node that match the selection, regardless of
where they are in the node hierarchy.

=item C<.>

Selects the current node.

=item C<..>

Selects the parent of the current node.

=item C<@>

Selects attributes.

=back

And some examples:

=over

=item C<head>

Selects all of the child nodes of the "head" element.

=item C</html>

Selects the root "html" element.

=item C<body/p>

Selects all "p" elements that are children of the "body" element.

=item C<//p>

Selects all "p" elements no matter where they are in the document.

=item C<body//p>

Selects all "p" elements that are descendants of the "body" element, no matter
where they appear under the "body" element.

=item C<//@lang>

Selects all attributes named "lang".

=back

There are also useful predicates to select certain nodes. Some examples:

=over

=item C<body//p[1]>

Select the first paragraph under the body element.

=item C<body//p[last()]>

Select the last paragraph under the body element.

=item C<//script[@src]>

Select all "script" nodes that have a "src" attribute.

=item C<//script[@src='foo.js']>

Select all "script" nodes that have a "src" attribute set to "foo.js".

=item C<< //img[@height > 400] >>

Select all "img" nodes with a height attribute greater than 400.

=item C<head/*>

Select all child nodes below the "head" node.

=item C<p[@*]>

Select all "p" nodes that have any attribute.

=item C<count(//p)>

Select a count of all "p" nodes in the document.

=back

There are a bunch of core functions in XPath. In addition to the (C<last()>
and C<count()>) examples above, there are functions for node sets, booleans,
numbers, and strings. See the XPath 1.0 W3C Recommendation,
L<http://www.w3.org/TR/xpath>, for thorough (and quite readable) documentation
of XPath syntax and support, including syntax and the core functions. The
W3Schools tutorial, L<http://www.w3schools.com/Xpath/default.asp> --
especially the part on syntax,
L<http://www.w3schools.com/Xpath/xpath_syntax.asp> -- provides a nice overview
of XPath.

=head2 Testing HTML

If you want to use XPath to test the content and structure of an HTML document,
be sure to pass the C<is_html> option to C<new()>, like so:

  my $tx = Test::XPath->new( xml => $html, is_html => 1 );

Test::XPath will then use XML::LibXML's HTML parser to parser the document,
rather than its XML parser. The upshot is that you won't have to worry about
namespace prefixes, and XML::LibXML won't try to fetch any DTD specified in
the DOCTYPE section of your HTML.

=head1 Class Interface

=head2 Constructor

=head3 C<new>

  my $tx = Test::XPath->new( xml => $xml );

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
"validation", "recover", and "no_network". These can be useful for tweaking
the behavior of the parser.

=back

=head1 Instance Interface

=head2 Assertions

=head3 C<ok>

  $tx->ok( $xpath, $description)
  $tx->ok( $xpath, $coderef, $description)

Test that an XPath expression evaluated against the XML document returns a
true value. If the XPath expression finds no nodes, the result will be false.
If it finds a value, the value must be a true value (in the Perl sense).

  $tx->ok( '//foo/bar', 'Should have bar element under foo element' );
  $tx->ok('contains(//title, "Welcome")', 'Title should contain "Welcome"');

You can also run recursive tests against your document by passing a code
reference as the second argument to C<ok()>. Once the initial selection has
been completed, each selected node will be assigned to the C<node> attribute
and the XML::XPath object passed to the code reference. For example, if you
wanted to test for the presence of "story" elements in your document, and to
test that each such element had an incremented "id" attribute, you'd do
something like this:

  my $i = 0;
  $tx->ok('//assets/story', sub {
      shift->is('./@id', ++$i, "ID should be $i in story $i");
  }, 'Should have story elements' );

For convenience, the XML::XPath object is also assigned to C<$_> for the
duration of the call to the code reference. Either way, you can call C<ok()>
and pass code references anywhere in the hierarchy. For example, to ensure
that an Atom feed has entries and that each entry has a title, a link, and a
very specific author element with name, uri, and email subnodes you can do:

  $tx->ok('/feed/entry', sub {
      $_->ok('./title', 'Should have a title');
      $_->ok('./author', sub {
          $_->is('./name',  'Mark Pilgrim',        'Mark should be author');
          $_->is('./uri',   'http://example.org/', 'URI should be correct');
          $_->is('./email', 'f8dy@example.com',    'Email should be right');
      }, 'Should have author elements');
  }, 'Should have entry elments');

=head3 C<is>

=head3 C<isnt>

  $tx->is($xpath, $want, $description);
  $tx->isnt($xpath, $dont_want, $description);

C<is()> and C<isnt()> compare the value returned by evaluation of the XPath
expression against the document to a value using C<eq> and C<ne>,
respectively.

  $tx->is('/html/head/title', 'Welcome', 'Title should be welcoming');
  $tx->isnt('/html/head/link/@type', 'hello', 'Link type should not');

As with C<Test::More::ok()>, a failing test will yield a useful diagnostic
message, something like:

  #   Failed test 'Title should be welcoming'
  #   at t/foo.t line 47.
  #          got: 'Bienvenidos'
  #     expected: 'Hello'

=head3 C<like>

=head3 C<unlike>

  $tx->like($xpath, qr/want/, $description);
  $tx->unlike($xpath, qr/dont_want/, $description);

Similar to C<is()> and C<isnt()>, but these methods match the value returned
by the XPath expression against a regular expression.

  $tx->like('/html/head/title', qr/^Foobar Inc.: .+/, 'Title context');
  $tx->unlike('/html/head/title', qr/Error/, 'Should be no error in title');

As with C<Test::More::like()>, a failing test will yield a useful diagnostic
message, something like:

  #   Failed test 'Title should, like, welcome'
  #   at t/foo.t line 62.
  #                   'Hello'
  #     doesn't match '(?-xism:^Bye$)'

=head3 C<cmp_ok>

Like C<Test::More::cmp_ok()>, this method allows you to compare the value
returned by an XPath expression to a value using any binary Perl operator.

  $tx->cmp_ok('/html/head/title', 'eq', 'Welcome');
  $tx->cmp_ok('//story[1]/@id', '==', 1);

As with C<Test::More::cmp_ok()>, a failing test will yield a useful diagnostic
message, something like:

  #   Failed test
  #   at t/foo.t line 104.
  #     '0'
  #         &&
  #     '1'

=head2 Accessors

=head3 C<node>

Returns the current context node. This will usually be the node for the
entire document, but in recursive tests run in code references passed to
C<ok()>, the node will be one of the nodes selected for the test.

=head3 C<xpc>

Returns the L<XML::LibXML::XPathContext|XML::LibXML::XPathContext> used to
execute the XPath expressions. It can be useful to access this object in order
to, for example, create new XPath functions to use in your tests. For example,
say that you wanted to define a C<grep()> XPath function that returns true for
a node value that matches a regular expression. You can define one like so:

  $tx->xpc->registerFunction( grep => sub {
      my ($nodelist, $regex) =  @_;
      my $result = XML::LibXML::NodeList->new;
      for my $node ($nodelist->get_nodelist) {
          $result->push($node) if $node->textContent =~ $regex;
      }
      return $result;
  });

You can then use C<grep()> like any other XPath function to select only those
nodes with content matching a regular expression. This example makes sure that
there are node email "nodes" under "author" nodes that end in "@example.com"
or "example.org":

  $tx->ok(
      'grep(//author/email, "@example[.](?:com|org)$")',
      'Should have example email'
  );

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

