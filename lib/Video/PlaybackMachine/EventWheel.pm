package Video::PlaybackMachine::EventWheel;

use strict;
use warnings;

use POE;

############################# Class Constants ##########################

## How often to check for events
use constant DEFAULT_CHECK_SECS => 1;

############################# Class Methods ############################


sub new {
  my $type = shift;
  my ($source, %handlers) = @_;

  my $self = {
	      source => $source,
	      handlers => { %handlers },
	      logger => Log::Log4perl->get_logger('Video.PlaybackMachine.EventWheel'),
	     };

  bless $self, $type;
}



############################ Object Methods ############################


sub spawn {
  my $self = shift;
  my ($callback) = @_;

  POE::Session->create(
		       object_states => [$self=>[qw(_start get_events)]]
		      );
}

sub session_init {
  my $self = shift;
  my ($heap) = @_;

  # Initialize object and heap here for new session

}

sub session_cleanup {
  my $self = shift;
  my ($heap) = @_;

  # Do any required heap cleanup here
}

sub set_handler {
  my $self = shift;
  my ($event_id, $callback) = @_;
  $self->{'handlers'}{$event_id} = $callback;
}

sub get_event {
  my $self = shift;
  my ($heap) = @_;

  # Put code to check for new events here
}

sub is_running {
  my $self = shift;

  # Put code here to determine whether to check for new events
  1;
}

############################ Session Methods ###########################



sub _start {
  my ($self, $kernel) = @_[OBJECT, KERNEL];

  $self->session_init($_[HEAP]);
  $kernel->yield('get_events');
}

sub get_events {
  my ($self, $heap, $kernel) = @_[OBJECT, HEAP, KERNEL];

  # Translate all events into callbacks
  while ( my $event = $self->get_event($heap) ) {
    $self->{'logger'}->debug("Received event: ", $event->get_type(), "\n");
    if ( exists $self->{'handlers'}{$event->get_type()} ) {
      $self->{'logger'}->debug("Invoking handler for ", $event->get_type(), "\n");
      $self->{'handlers'}{$event->get_type()}->($self->{'source'}, $event);
    }
  }

  # Keep checking so long as we're playing
  if ( $self->is_running() ) {
    $kernel->delay('get_events', DEFAULT_CHECK_SECS);
  }
}



1;
