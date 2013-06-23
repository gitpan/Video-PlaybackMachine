package Video::PlaybackMachine::FillProducer::SlideShow;

####
#### Video::PlaybackMachine::FillProducer::SlideShow
####
#### $Revision$
####
#### Plays a bunch of random photos. Since we need to do things
#### at particular delay times, launches its own POE session.
####

use strict;
use warnings;

use Carp;
use POE;
use Log::Log4perl;

use base 'Video::PlaybackMachine::FillProducer';

use Video::PlaybackMachine::TimeLayout::GranularTimeLayout;
use Video::PlaybackMachine::Player qw(PLAYBACK_OK PLAYBACK_STOPPED);
use Video::PlaybackMachine::FillProducer::Chooser;

############################# Class Constants #############################

# Maximum number of slides to play in a row
our $Max_Slides = 5;

############################## Class Methods ##############################

##
## new()
##
## Arguments: (hash)
##  TIME: int -- Time in seconds that we want to display a still
##  DIRECTORY: string -- Directory containing stills we want to display
##
sub new
{
	my $type = shift;
	my %in   = @_;

	defined $in{time} or croak( $type, "::new() called incorrectly" );

	my $self = {

		time_layout =>
		  Video::PlaybackMachine::TimeLayout::GranularTimeLayout->new(
			$in{time}, $Max_Slides
		  ),
		frame_chooser => Video::PlaybackMachine::FillProducer::Chooser->new(
			DIRECTORY => $in{'directory'},
		),
		music_chooser => Video::PlaybackMachine::FillProducer::Chooser->new(
			DIRECTORY => $in{'music_directory'},
			FILTER    => qr/\.(mp3|wav|ogg)$/
		),
		time   => $in{time},
		logger => Log::Log4perl->get_logger(
			'Video::PlaybackMachine::Filler::Slideshow'),

	};

	bless $self, $type;
}

############################# Object Methods ##############################

##
## get_time_layout()
##
## Returns the FixedTimeLayout for the appropriate time.
##
sub get_time_layout
{
	$_[0]->{time_layout};
}

##
## has_audio()
##
## The slide show provides an audio track.
##
sub has_audio { return 1; }

##
## Slideshow is available if the directory exists
## and there are images in it.
##
sub is_available
{
	my $self = shift;

	return $self->{'frame_chooser'}->is_available();

}

##
## show_slide()
##
## Displays a set of random still frames.
##
sub show_slide
{
	my ( $self, $kernel, $heap ) = @_[ OBJECT, KERNEL, HEAP ];

	# If we have enough time to play another slide, call the player
	# to play it.
	my $time_played = ( time() - $heap->{'slide_start_time'} );
	if ( $heap->{planned_time} > $time_played )
	{
		my $frame = $self->{'frame_chooser'}->choose();
		$kernel->post( 'Player', 'play_still', $frame );
		$kernel->delay( 'show_slide', $self->{'time'} );
	}

	# Otherwise, cancel all slides and shut things down.
	# (The alarm cancel should be redundant.)
	else
	{
		$self->{'logger'}->debug(
"Shutting down slideshow (time left=$time_played, $heap->{planned_time})"
		);
		$kernel->alarm_remove('show_slide');
		$kernel->state('show_slide');
		$kernel->state('next_song');
		$kernel->alarm_remove('next_song');
		$kernel->state('song_done');
		$kernel->alarm_remove('song_done');
		delete $heap->{'slide_start_time'};
		delete $heap->{'planned_time'};

		$kernel->yield('next_fill');
	}

}

##
## start()
##
## Starts the display of random still frames. Adds event handlers to
## the current session to show slides. Assumes that we're being called
## in a POE Filler session.
##
sub start
{
	my $self = shift;
	my ($planned_time) = @_;

	$self->{'logger'}->debug("Starting slideshow");
	my $heap = $poe_kernel->get_active_session->get_heap();
	$heap->{'slide_start_time'} = time();
	$heap->{'planned_time'}     = $planned_time;
	$poe_kernel->state( 'show_slide', $self );
	$poe_kernel->state( 'next_song',  $self );
	$poe_kernel->state( 'song_done',  $self );
	$poe_kernel->yield('show_slide');
	$poe_kernel->yield('next_song');
}

sub next_song
{
	$_[OBJECT]{'logger'}->debug("Running next song");
	$_[KERNEL]->post(
		'Player', 'play_music',
		$_[SESSION]->postback('song_done'),
		$_[OBJECT]->{'music_chooser'}->choose()
	);
}

sub song_done
{
	$_[OBJECT]{'logger'}->debug("Song done");
	my ( $stream, $status ) = @{ $_[ARG1] };
	if ( $status == PLAYBACK_OK() )
	{
		$_[OBJECT]{'logger'}->debug("Returned OK, playing next song");
		$_[KERNEL]->yield('next_song');
	}
	else
	{
		$_[OBJECT]{'logger'}->debug("'$status' Not OK, stopping");
		$_[KERNEL]->alarm('next_song');
	}
}

1;

