package Video::PlaybackMachine::AVFile;

####
#### Video::PlaybackMachine::AVFile
####
#### $Revision$
####
####

use strict;
use warnings;

############################# Class Constants #############################

############################## Class Methods ##############################

##
## new()
##
## Arguments:
##   FILE: string -- Path to a file
##   LENGTH: integer -- Play length of the file in seconds.
##
sub new {
  my $type = shift;
  my ($file, $length) = @_;

  my $self = {
	      file => $file, 
	      length => $length
	     };
  bless $self, $type;
}


############################# Object Methods ##############################

##
## get_length()
##
## Returns the duration of the AV file in seconds.
##
sub get_length { return $_[0]->{length}; }

##
## get_file()
##
## Returns the filename.
##
sub get_file { return $_[0]->{file}; }

1;

__END__

=head1 NAME

Video::PlaybackMachine::AVFile - An MPEG, PNG, OGG, or other file which can be played

=head1 SYNOPSIS

  use Video::PlaybackMachine::AVFile;

  my $avfile = Video::PlaybackMachine::AVFile->new($file, $duration);

  my $filename = $avfile->get_file();
  my $length = $avfile->get_length();

=head1 DESCRIPTION

Simple object representing a playable file.

=head1 METHODS

=head2 CLASS METHODS

=head3 new()

  new({file => $file, length => $length_secs });

Constructor. The C<$file> parameter should be a filename. The
C<$length> parameter should be the duration of the file in seconds.

=head2 OBJECT METHODS

=head3 get_length()

Returns the duration of the AV file in seconds.

=head3 get_file()

Returns the filename.

=cut

