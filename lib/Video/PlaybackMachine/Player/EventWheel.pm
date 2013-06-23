package Video::PlaybackMachine::Player::EventWheel;

# TODO: Make a subclass of EventWheel

###
###

use strict;
use POE;
use Video::Xine;
use Video::PlaybackMachine::Player;
use Video::Xine::Stream qw/:status_constants/;
use Video::Xine::Event qw/:type_constants/;

## How often to check to see if Xine has stopped, in seconds
use constant XINE_CHECK_INTERVAL_SECS => 2;

sub new {
  my $type = shift;
  my ($stream, %handlers) = @_;

  my $self = {
	      type => $type,
	      stream => $stream,
	      handlers => { %handlers },
	      queue => undef,
	      logger => Log::Log4perl->get_logger('Video.PlaybackMachine.Player.EventWheel'),	     
	     };

  $self->{queue} = Video::Xine::Event::Queue->new($self->{'stream'})
    or die "Couldn't create Xine::Event::Queue";

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

  $kernel->yield('get_events');
}


sub clear_events {
	my $self = shift;
		
	1 while $self->{queue}->get_event();	
}

sub get_events {
  my ($self, $heap, $kernel) = @_[OBJECT, HEAP, KERNEL];

  # Translate all events into callbacks
  while ( my $event = $self->{queue}->get_event() ) {
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
}

sub set_handler {
  my $self = shift;
  my ($event, $callback) = @_;
  $self->{'handlers'}{$event} = sub { $callback->($_[0], Video::PlaybackMachine::Player::PLAYBACK_OK() ) };
}


# Convenience method
sub set_stop_handler {
  $_[0]->set_handler(XINE_EVENT_UI_PLAYBACK_FINISHED, $_[1]);
}

1;

__END__

=head1 NAME

Video::PlaybackMachine::Player::EventWheel - Bridge between Player events and POE events

=head1 SYNOPSIS

  use Video::PlaybackMachine::Player::EventWheel;

  # Create an event wheel watching $stream
  my $wheel = Video::PlaybackMachine::Player::EventWheel->new($stream);

  # Clear out any previous events
  $wheel->clear_events();

  # Call a handler when the stream stops
  $wheel->set_stop_handler(sub { print "All done!\n"});

  # Start the session
  $wheel->spawn();
  

=head1 DESCRIPTION

When spawned, will pass along events from the given streams to the
appropriate callbacks.

=cut
