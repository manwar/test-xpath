package Test::XPath;

use strict;
use XML::LibXML '1.69';
use Test::Builder;

our $VERSION = '0.01';

sub new {
    my ($class, %p) = @_;

    # Create and configure the parser.
    my $parser = XML::LibXML->new;
    while (my ($k, $v) = each %p) {
        next if $k eq 'html' or $k eq 'xml' or $k eq 'opts';
        $parser->$k($v);
    }

    # Parse the document.
    my $doc = $p{html}
        ? $parser->parse_html_string($p{html}, $p{opts})
        : $parser->parse_string($p{xml});

    return bless \$doc;
}

sub xpath_ok {
    my $doc  = $ { +shift };
    my $desc = shift;
    my $code;
    if (ref $desc eq 'CODE') {
        $code = $desc;
        $desc = shift;
    } else {
        $code = sub { };
    }

    my $Test = Test::Builder->new;
}

sub xpath_is {

}

1;
__END__

=begin comment

Fake-out Module::Build. Delete if it ever changes to support =head1 headers
other than all uppercase.

=head1 NAME

Test::XPath - Test XML and HTML using XML::LibXML XPath expressions

=end comment

=head1 Name

Test::XPath - Test XML and HTML using XML::LibXML XPath expressions

=head1 Synopsis

  use Test::More plan => 1;
  use Test::XPath;

  # Simple tests.
  xpath_ok $xml, $xpath, $description;
  xpath_is $xml, $xpath, $want, $description;

  # When testing a document multilple times:
  my $tx = Test::XPath->new(
      html => $html,
      no_network => 1,
  );

  $tx->xpath_ok( $xpath, $description );
  $tx->xpath_is( $xpath, $want, $description );

  # Recursing into a document:
  $tx->xpath_ok( $xpath, $description, sub {
      for my $elem (@_) {
          $tx->xpath_is($xpath, $want, $description);
      }
  });

=head1 Description

Use the power of the XPath syntax supported by XML::LibXML to validate the
structure of your XML and HTML documents.

=head2 Functional Interface



=head3 xpath_ok



=head3 xpath_is



=head2 Object-Oriented Interface



=head3 new



=head3 xpath_ok



=head3 xpath_is



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

