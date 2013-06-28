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
use X11::FullScreen;
use Video::Xine;
use Video::Xine::Stream qw/:status_constants/;
use Video::PlaybackMachine::EventWheel::FullScreen;
use Video::PlaybackMachine::Player::EventWheel;
use Video::PlaybackMachine::Config;
use Log::Log4perl;
use Carp;

############################# Class Constants ################################

## Status codes Xine will report
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

  my $self = {
	      logger => Log::Log4perl->get_logger('Video.PlaybackMachine.Player'),
	     };


  bless $self, $type;
}

############################## Session Methods ###############################

##
## On session start, initializes Xine and prepares it to start playing.
##
sub _start {
  my $kernel = $_[KERNEL];

  $kernel->alias_set('Player');
  my $x_display = Video::PlaybackMachine::Config->config()->x_display();
  my $display = X11::FullScreen::Display->new($x_display);
  $_[HEAP]->{'display'} = $display;
  $_[HEAP]->{'window'} = $display->createWindow();
  $display->sync();
  my $xine = Video::Xine->new();
  my $config = Video::PlaybackMachine::Config->config();
  $xine->set_param(XINE_ENGINE_PARAM_VERBOSITY, $config->player_verbose());
  $_[HEAP]->{'xine'} = $xine;
  my $x11_visual = Video::Xine::Util::make_x11_visual($display,
						      $display->getDefaultScreen(),
						      $_[HEAP]->{'window'},
						      $display->getWidth(),
						      $display->getHeight(),
						      $display->getPixelAspect()
						     );
	# TODO Move "auto" to config file
  my $driver = Video::Xine::Driver::Video->new($xine,"auto",1,$x11_visual, $display);
  my $s = $xine->stream_new(undef, $driver)
    or croak "Unable to open video stream";
  $_[OBJECT]->{'stream'} = $s;
  $_[HEAP]->{'stream_queue'} =
    Video::PlaybackMachine::Player::EventWheel->new($s);
  my $fq =
    Video::PlaybackMachine::EventWheel::FullScreen->new($display, $_[HEAP]->{'window'});
  $fq->set_expose_handler(
			  sub { $s->get_video_port()->send_gui_data(XINE_GUI_SEND_EXPOSE_EVENT, $_[1]); } );
  $fq->spawn();

  $_[HEAP]->{'fullscreen_queue'} = $fq

}

##
## Responds to a 'play' request by playing a movie on Xine.
##
## Arguments:
##
##   ARG0: $postback -- what to call after the play is completed
##   ARG1: $offset -- number of seconds after the movie's start to begin
##   ARG2: @filenames -- ARG1 onward contains the files to play, in order.
##
## After Xine is started, we'll check on it every $XINE_CHECK_INTERVAL
## seconds to see if it has stopped.
##
sub play {
  my ($kernel, $self, $heap, $postback, $offset, @files) = @_[KERNEL, OBJECT, HEAP, ARG0, ARG1, ARG2 .. $#_ ];

  defined $offset or $offset = 0;

  my $log = $_[OBJECT]{'logger'};

	# TODO Remove fatal
  @files or die "No files specified! stopped";

  # Stop if we're playing
  if ( $self->{'stream'}->get_status() == XINE_STATUS_PLAY ) {
    $self->{'stream'}->stop();
    $self->{'stream'}->close();
  }
  
  # Clear out any previous events
  $heap->{'stream_queue'}->clear_events();

  $log->info("Playing $files[0]");

  my $s = $_[OBJECT]->{'stream'};
  $s->open($files[0])
    or do {
      $log->error("Unable to open '$files[0]': Error " . $s->get_error());
      $postback->(PLAYBACK_ERROR);
      return;
    };
  $s->play(0,$offset * 1000)
    or do {
      $log->error("Unable to play '$files[0]': Error " . $s->get_error());
      $postback->(PLAYBACK_ERROR);
      return;
    };

  # Tell the system to refresh the window
  # Drawable changed
  $s->get_video_port()->send_gui_data(XINE_GUI_SEND_DRAWABLE_CHANGED, $heap->{'window'});
  $s->get_video_port()->send_gui_data(XINE_GUI_SEND_VIDEOWIN_VISIBLE, 1);

  # Spawn a watcher to call the postback after the fact
  $heap->{'stream_queue'}->set_stop_handler($postback);
  $heap->{'stream_queue'}->spawn();

			     
  $heap->{'playback_type'} = PLAYBACK_TYPE_MOVIE;

}

##
## stop()
##
## Stops the currently-playing movie.
##
sub stop {
  # Stop if we're playing
  if ( $_[OBJECT]->{'stream'}->get_status() == XINE_STATUS_PLAY ) {
    $_[OBJECT]->{'stream'}->stop();
  }
  
}

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
  my ($self, $kernel, $heap, $still, $callback, $time) = @_[OBJECT, KERNEL, HEAP, ARG0, ARG1, ARG2];
  my $log = $self->{'logger'};
  if ($self->{'stream'}->get_status() == XINE_STATUS_PLAY
  	&& $heap->{'playback_type'} == PLAYBACK_TYPE_MOVIE 
  ) {
  		$log->error("Attempted to show still '$still' while playing a movie");
  		return;
  }
  $log->debug("Showing still '$_[ARG0]'");
  eval {
    $heap->{'display'}->displayStill($heap->{'window'}, $still);
  };
  if ($@) {
    $log->error("Error displaying still '$still': $@");
    $callback->(PLAYBACK_ERROR) if $callback;
    return;
  }

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
      $callback->($self->{'stream'}, PLAYBACK_ERROR);
      return;
    }
    else {
      $heap->{'stream_queue'}->set_stop_handler($callback);
    }
  }
  else {
    $self->{'logger'}->debug("Playing music file '$song_file'");
    $heap->{'stream_queue'}->clear_events();
    $self->{'stream'}->open($song_file)
      or do {
	$self->{'logger'}->warn("Unable to play '$song_file'");
	$callback->($self->{'stream'}, PLAYBACK_ERROR);
	return;
      };
    $self->{'stream'}->play(0,0);
    $heap->{'stream_queue'}->set_stop_handler($callback);
    $heap->{'stream_queue'}->spawn();
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


  my $session = $poe_kernel->get_active_session();
  my $heap = $session->get_heap();

  if (! defined $self->{'stream'} ) {
    $self->{'logger'}->fatal("Undefined stream! Called on session $session, caller " . join(' ', caller()) );
    confess("Undefined stream!");
  }

  $self->{'stream'}->get_status() == XINE_STATUS_PLAY
    and return PLAYER_STATUS_PLAY;

  return PLAYER_STATUS_STOP;
}


1;

__END__

=head1 NAME

Video::PlaybackMachine::Player - POE component to play movies

=head1 SYNOPSIS

  use Video::PlaybackMachine::Player;

  my $player = Video::PlaybackMachine::Player->new();

  # Start the Player session
  $player->spawn();

  # Then, in another session...
  $kernel->post('Player', 'play', sub { "Finished"; }, 0, 'mymovie.mp4');

  # Is the movie still running?
  print "Playing\n" if $player->get_status() == PLAYER_STATUS_PLAY;


=cut
