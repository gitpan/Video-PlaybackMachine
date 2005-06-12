package Video::PlaybackMachine::PlayerBackEnd::XineBackEnd;

use strict;
use warnings;

use X11::FullScreen;
use Video::PlaybackMachine::EventWheel::FullScreen;
use Video::Xine;
use POSIX 'ceil';


use Carp;

use constant X_DISPLAY => ':0.0';

## Status codes backend will report
use constant PLAYER_STATUS_STOP => 0;
use constant PLAYER_STATUS_PLAY => 1;


use base 'Video::PlaybackMachine::PlayerBackEnd';

sub initialize {
  my $self = shift;

  my $display = X11::FullScreen::Display->new(X_DISPLAY);
  $self->{'display'} = $display;
  $self->{'window'} = $display->createWindow();
  $display->sync();
  my $xine = Video::Xine->new();
  $self->{'xine'} = $xine;
  my $x11_visual = Video::Xine::Util::make_x11_visual($display,
						      $display->getDefaultScreen(),
						      $self->{'window'},
						      $display->getWidth(),
						      $display->getHeight(),
						      $display->getPixelAspect()
						     );
  my $driver = Video::Xine::Driver::Video->new($xine,"auto",1,$x11_visual);
  my $s = $xine->stream_new(undef, $driver)
    or croak "Unable to open video stream";
  $self->{'stream'} = $s;
  $self->{'stream_queue'} =
    Video::PlaybackMachine::Player::EventWheel->new($s);
  my $fq =
    Video::PlaybackMachine::EventWheel::FullScreen->new($display, $self->{'window'});
  $fq->set_expose_handler(
			  sub { $s->get_video_port()->send_gui_data(XINE_GUI_SEND_EXPOSE_EVENT, $_[1]); } );
  $fq->spawn();

  $self->{'fullscreen_queue'} = $fq;

}

sub get_stream_queue { return $_[0]->{'stream_queue'}; }

sub get_status {
  my $self = shift;

  $self->{'stream'}->get_status() == XINE_STATUS_PLAY
    and return PLAYER_STATUS_PLAY;

  return PLAYER_STATUS_STOP;
}

sub stop {
  my $self = shift;

  if ( $self->{stream}->get_status() == XINE_STATUS_PLAY ) {
    $self->{'stream'}->stop();
    $self->{'stream'}->close();
  }
}

sub play_movie {
  my $self = shift;
  my ($file, $offset) = @_;

  my $s = $self->{'stream'};
  $s->open($file)
    or return;
  $s->play(0,$offset * 1000)
    or return;

  # Tell the system to refresh the window
  # Drawable changed
  $s->get_video_port()->send_gui_data(XINE_GUI_SEND_DRAWABLE_CHANGED, $self->{'window'});
  $s->get_video_port()->send_gui_data(XINE_GUI_SEND_VIDEOWIN_VISIBLE, 1);


  return 1;
}

sub play_still {
  my $self = shift;
  my ($still) = @_;

  eval {
    $self->{'display'}->displayStill($self->{'window'}, $still);
  };
  if ($@) {
    return;
  }

  return 1;

}

sub play_music {
  my $self = shift;
  my ($song_file) = @_;

  $self->{'stream'}->open($song_file) or return;
  $self->{'stream'}->play(0,0) or return;
  $self->{'stream_queue'}->spawn();
  
  return 1;
}

sub get_error {
  return $_[0]->{'stream'}->get_error();
}

sub movie_length {
  my $self = shift;
  my ($filename) = @_;

  my $xine = Video::Xine->new(config_file => '/dev/null');
  my $null_ao_driver = Video::Xine::Driver::Audio->new($xine, 'none')
      or die "Couldn't open audio driver\n";
  my $stream = $xine->stream_new($null_ao_driver);
  $stream->open($filename)
    or croak "Couldn't open '$filename'";
  my (undef, undef, $length_millis) = $stream->get_pos_length();

  return ceil($length_millis / 1000);
}


package Video::PlaybackMachine::Player::EventWheel;

# TODO: Make a subclass of EventWheel

###
### When spawned, these will pass along events from the given
### streams to the appropriate callbacks.
###

use strict;
use POE;
use Video::Xine;

## How-the-movie-played status codes

# OK == played through and stopped at the end
use constant PLAYBACK_OK => 1;

# ERROR == problem in trying to play
use constant PLAYBACK_ERROR => 2;

## How often to check to see if Xine has stopped, in seconds
use constant XINE_CHECK_INTERVAL_SECS => 2;

sub new {
  my $type = shift;
  my ($stream, %handlers) = @_;

  my $self = {
	      type => $type,
	      stream => $stream,
	      handlers => { %handlers },
	      logger => Log::Log4perl->get_logger('Video.PlaybackMachine.Player.EventWheel'),	     
	     };

  bless $self, $type;
}

sub spawn {
  my $self = shift;
  my ($callback) = @_;

  POE::Session->create(
		       object_states => [$self=>[qw(_start get_events)]]
		      );
}

sub _start {
  my ($self, $heap, $kernel) = @_[OBJECT, HEAP, KERNEL];

  $heap->{queue} = Video::Xine::Event::Queue->new($self->{'stream'})
    or die "Couldn't create Xine::Event::Queue";

  $kernel->yield('get_events');
}

sub get_events {
  my ($self, $heap, $kernel) = @_[OBJECT, HEAP, KERNEL];

  # Translate all events into callbacks
  while ( my $event = $heap->{queue}->get_event() ) {
    $self->{'logger'}->debug("Received event: ", $event->get_type(), "\n");
    if ( $event->get_type() == XINE_EVENT_UI_PLAYBACK_FINISHED ) {
      $self->{'stream'}->close();
    }
    if ( exists $self->{'handlers'}{$event->get_type()} ) {
      $self->{'logger'}->debug("Invoking handler for ", $event->get_type(), "\n");
      $self->{'handlers'}{$event->get_type()}->($self->{'stream'}, $event);
    }
  }

  # Keep checking so long as we're playing
  if ( $self->{'stream'}->get_status() == XINE_STATUS_PLAY ) {
    $kernel->delay('get_events', XINE_CHECK_INTERVAL_SECS);
  }
  else {
    delete $heap->{queue};
  }
}

sub set_handler {
  my $self = shift;
  my ($event, $callback) = @_;
  $self->{'handlers'}{$event} = sub { $callback->($_[0], PLAYBACK_OK) };
}


# Convenience method
sub set_stop_handler {
  $_[0]->set_handler(XINE_EVENT_UI_PLAYBACK_FINISHED, $_[1]);
}



1;
