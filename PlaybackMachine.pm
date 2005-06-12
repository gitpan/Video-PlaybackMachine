package Video::PlaybackMachine;

use 5.008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Video::PlaybackMachine ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.03';


# Preloaded methods go here.

1;
__END__

=head1 NAME

Video::PlaybackMachine - Perl extension for creating a television station

=head1 SYNOPSIS

  use Video::PlaybackMachine;
  

=head1 ABSTRACT

Based on POE, PlaybackMachine is the basis for a television station in
a box.

=head1 DESCRIPTION

PlaybackMachine is a television broadcast system. You provide the
content, added through command-line and web-based interfaces.

=head2 EXPORT

None by default.

=head1 SEE ALSO

playback_machine.pl(1)

=head1 AUTHOR

Stephen Nelson, E<lt>stephen@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2005 by Stephen Nelson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
