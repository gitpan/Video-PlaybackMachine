package Video::PlaybackMachine::EventWheel::FullScreen;

use strict;
use warnings;

use X11::FullScreen;

use base 'Video::PlaybackMachine::EventWheel';

######################### Class Methods #########################

sub new {
  my $type = shift;
  my ($source, $window, %handlers) = @_;
  my $self = $type->SUPER::new($source, %handlers);
  $self->{'window'} = $window;
  return $self;
}

######################### Object Methods ########################

sub get_event {
  my $self = shift;
  my ($heap) = @_;

  return $self->{'source'}->checkWindowEvent($self->{'window'});
}


# Expose is 12
sub set_expose_handler {
  $_[0]->set_handler(12, $_[1]);
}

# TODO: Make is_running check the display handle


1;
