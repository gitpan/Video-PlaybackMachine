package Video::PlaybackMachine::PlayerBackEnd;

use strict;
use warnings;
use diagnostics;

=pod

=head1 NAME

Video::PlaybackMachine::PlayerBackEnd -- interface for different kinds of players

=head1 DESCRIPTION

This file defines the interface for PlayerBackEnds, which provide the
actual playback ability of the Playback Machine. A BackEnd must be
able to play movies, show stills, and play music files.

The PlayerBackEnd should implement the C<initialize()>,
C<play_movie()>, C<play_still()>, C<play_music()>, and C<stop()>
methods for playing content. It should also implement check_event()
and get_status(). A C<movie_length()> function is optional but
strongly suggested.

=head2 CLASS METHODS

=over 4

=cut

######################## Class Methods #########################

=pod

=item new( name => $name, config => $config )


Creates a PlayerBackEnd object. The config object will come from the
appropriate configuration file and will be a (sub)class of AppConfig.

=cut
sub new {
  my $type = shift;
  my %in = @_;
  my $self = {
	      name => $in{'name'},
	      config => $in{'config'}
	     };

  bless $self, $type;

}


=pod

=back

=head2 OBJECT METHODS

=over 4

=cut

######################### Object Methods #######################

=pod

=item initialize()

Do whatever initialization is required to show movies.

=cut
sub initialize { }


=pod

=item play_movie( $movie , $offset  )

Start playing $movie $offset seconds after the beginning. Return true
if the movie played successfully, or return false if there was an error.

=cut
sub play_movie { }

=pod

=item get_error()

Returns some kind of error message or code indicating the last error
which happened.

=cut
sub get_error { }

=pod

=item movie_length( $movie )

Returns the length of the movie in seconds, ceilinged.

=cut
sub movie_length { }


1;
