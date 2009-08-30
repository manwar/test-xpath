package Test::XPath;

use strict;
use XML::LibXML '1.69';
use Test::Builder;

our $VERSION = '0.01';

sub new {
    my ($class, %p) = @_;
    my $doc = delete $p{doc} || _doc(\%p);
    my $xpc = XML::LibXML::XPathContext->new( $doc->documentElement );
    $xpc->registerNs( %{ $p{xmlns} }) if $p{xmlns};
    return bless {
        xpc  => $xpc,
        node => $doc->documentElement,
    };
}

sub xpath_ok {
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

sub xpath_is {
    Test::Builder::new->is_eq( _findv(shift, shift), @_);
}

sub xpath_isnt {
    Test::Builder::new->isnt_eq( _findv(shift, shift), @_);
}

sub xpath_like {
    Test::Builder::new->like( _findv(shift, shift), @_);
}

sub xpath_unlike {
    Test::Builder::new->unlike( _findv(shift, shift), @_);
}

sub xpath_cmp_ok {
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

  use Test::More plan => 1;
  use Test::XPath;

  my $tx = Test::XPath->new(
      html       => $html,
      no_network => 1,
  );

  $tx->xpath_ok( $xpath, $description );
  $tx->xpath_is( $xpath, $want, $description );

  # Recursing into a document:
  my @css = qw(foo.css bar.css);
  $tx->xpath_ok( '/html/head/style', sub {
      shift->xpath_is( './@src', shift @css);
  }, $description);

=head1 Description

Use the power of the XPath syntax supported by XML::LibXML to validate the
structure of your XML and HTML documents.

=head2 Interface

=head3 new

  my $xp = Test::XPath->new( xml => $xml );

Creates and returns an XML::XPath object. This object can be used to run XPath
tests on the XML passed to it. The supported parameters are:

=over

=item xml

  xml => '<foo><bar>hey</bar></foo>',

The XML to be parsed and tested. Required unless the C<file> or C<doc> option
is passed.

=item file

  file => 'rss.xml',

Name of the file containing the XML to be parsed and tested. Required unless
the C<xml> or C<doc> option is passed.

=item doc

  doc => XML::LibXML->new->parse_file($xml_file),

An XML::LibXML document object. Required unless the C<xml> or C<file> option
is passed.

=item is_html

  is_html => 1,

If the XML you're testing is actually HTML, pass this option a true value and
XML::LibXML's HTML parser will be used instead of the XML parser.

=item xmlns

  xmlns => { x => 'http://www.w3.org/1999/xhtml' },

Default XML namespace to be used in the XPath queries.

=item options

  options => { recover_silently => 1, no_network => 1 },

Optional hash reference of
L<XML::LibXML::Parser options|XML::LibXML::Parser/"PARSER OPTIONS">, such as
"validation", "recover", and "no_network".

=back

=head3 xpath_is

  $xp->xpath_is('/html/head/title', 'Welcome');

=head3 xpath_isnt

  $xp->xpath_isnt('/html/head/link[@type]', 'hello');

=head3 xpath_like

  $xp->xpath_like('/html/head/title', qr/^Foobar Inc.: .+/);

=head3 xpath_unlike

  $xp->xpath_unlike()

=head3 xpath_cmp_ok

  $xp->xpath_cmp_ok()

=head3 xpath_ok

  $xp->xpath_ok( '//foo/bar', 'Should have bar element under foo element' );
  $xp->xpath_ok( '//assets/story', sub {
      my $i;
      for my $story (@_) {
          $story->xpath_is('[@id]/text()', ++$i, "ID should be $i in story" );
      }
  }, 'Should have story elements' );

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

