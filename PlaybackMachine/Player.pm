package Video::PlaybackMachine::Player;

####
#### Video::PlaybackMachine::Player
####
#### A POE::Session which displays movies and still frames onscreen
#### based on events.
####

use strict;
use base 'Exporter';
our @EXPORT_OK = qw(PLAYER_STATUS_STOP PLAYER_STATUS_PLAY PLAYER_STATUS_STILL
                    PLAYBACK_OK PLAYBACK_ERROR PLAYBACK_STOPPED);

use POE;
use Log::Log4perl;
use Video::PlaybackMachine::Config;
use Carp;

############################# Class Constants ################################

## Status codes backend will report
use constant PLAYER_STATUS_STOP => 0;
use constant PLAYER_STATUS_PLAY => 1;

## How-the-movie-played status codes

# OK == played through and stopped at the end
use constant PLAYBACK_OK => 1;

# ERROR == problem in trying to play
use constant PLAYBACK_ERROR => 2;

## Types of playback
use constant PLAYBACK_TYPE_MUSIC => 0;
use constant PLAYBACK_TYPE_MOVIE => 1;

############################## Class Methods #################################

##
## new()
##
## Returns a new instance of Player. Note that the session is not created
## until you call spawn().
##
sub new {
  my $type = shift;

  my $self = 
    {
     logger => Log::Log4perl->get_logger('Video.PlaybackMachine.Player'),
     be => Video::PlaybackMachine::Config->config()->get_player_backend()
    };


  bless $self, $type;
}

############################## Session Methods ###############################

##
## On session start, initializes Xine and prepares it to start playing.
##
sub _start {
  my $kernel = $_[KERNEL];
  my $self = $_[OBJECT];

  $_[KERNEL]->alias_set('Player');
  $_[OBJECT]{be}->initialize();
  
}

##
## Responds to a 'play' request by playing a movie.
## Arguments:
##   ARG0: $postback -- what to call after the play is completed
##   ARG1: $offset -- number of seconds after the movie's start to begin
##   ARG2: @filenames -- ARG1 onward contains the files to play, in order.
##
##
sub play {
  my ($kernel, $self, $heap, $postback, $offset, @files) = @_[KERNEL, OBJECT, HEAP, ARG0, ARG1, ARG2 .. $#_ ];

  defined $offset or $offset = 0;

  my $log = $_[OBJECT]{'logger'};

  @files or die "No files specified! stopped";

  $self->{'be'}->stop();

  $log->info("Playing $files[0]");

  $self->{'be'}->play_movie($files[0], $offset)
    or do {
      $log->error("Unable to play '$files[0]': Error " . $self->{'be'}->get_error() );
      $postback->(PLAYBACK_ERROR);
      return;
    };

  # Spawn a watcher to call the postback after the fact
  $self->{'be'}->get_stream_queue()->set_stop_handler($postback);
  $self->{'be'}->get_stream_queue()->spawn();
  $heap->{'playback_type'} = PLAYBACK_TYPE_MOVIE;

}

##
## stop()
##
## Stops the currently-playing movie.
##
sub stop { $_[OBJECT]->{'be'}->stop(); }

##
## play_still()
##
## Arguments:
##   STILL_FILE: Filename of our stillstore.
## 
## Responds to a 'play_still' request by playing a still frame. The
## stillframe will remain there until something replaces it.
##
sub play_still {
  my ($self, $kernel, $heap, $still, $callback, $time) = @_[OBJECT, KERNEL, HEAP, ARG0, ARG1];
  my $log = $self->{'logger'};
  $log->debug("Showing '$_[ARG0]'");

  $self->{'be'}->play_still($still)
    or do {
      $log->error("Error displaying still '$still': $@");
      $callback->(PLAYBACK_ERROR) if defined $callback;
    };

  if (defined $time) {
    POE::Session->create(
			 inline_states => {
					   _start => sub {
					     $_[KERNEL]->delay('end_delay', $time);
					   },
					   end_delay => sub {
					     $log->debug("Still playback finished for '$still'");
					     $callback->($still, PLAYBACK_OK);
					   }
					  }
			);
  }

}

##
## play_music()
##
## Arguments:
##  ARG0 -- callback. What to call when the music's over.
##  ARG1 -- song file. Filename of the song to play.
##
## Responds to a 'play_music' request by playing a particular song.
## Logs a warning and does nothing if we tried to play music during a
## movie. If a song was already playing, lets it play, but substitutes
## the current callback.
##
sub play_music {
  my ($self, $heap, $kernel, $callback, $song_file) = @_[OBJECT,HEAP,KERNEL,ARG0,ARG1];

  defined $callback or die "Must define callback!\n";

  defined $song_file or die "Must define song file!\n";

  # If there's a movie running, let it play
  if ($self->get_status() == PLAYER_STATUS_PLAY) {
    if ($heap->{'playback_type'} == PLAYBACK_TYPE_MOVIE) {
      $self->{'logger'}->warn("Attempted to play '$song_file' while a movie is playing");
      $callback->($song_file, PLAYBACK_ERROR);
      return;
    }
    else {
      $self->{'be'}->get_stream_queue()->set_stop_handler($callback);
    }
  }
  else {
    $self->{'logger'}->debug("Playing music file '$song_file'");
    $self->{'be'}->play_music($song_file)
      or do {
	$self->{'logger'}->warn("Unable to play '$song_file'");
	$callback->($song_file, PLAYBACK_ERROR);
	return;
      };

    $self->{'be'}->get_stream_queue()->set_stop_handler($callback);

    $heap->{'playback_type'} = PLAYBACK_TYPE_MUSIC;
  }
}



############################## Object Methods ################################

##
## spawn()
##
## Creates the appropriate Player session.
##
sub spawn {
  my $self = shift;

  POE::Session->create(
		       object_states => 
		       [
			$self => [
				  qw(_start
                                     play
                                     play_still
				     play_music
                                     stop
                                  )
				 ] ,
		       ],
		     );

}

##
## get_status()
##
## Returns one of:
##   PLAYER_STATUS_PLAY if a movie (or music) is playing
##   PLAYER_STATUS_STOP if nothing is playing.
##
sub get_status {
  my $self = shift;

  return $self->{'be'}->get_status();
}

1;
