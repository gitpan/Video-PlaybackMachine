package Video::PlaybackMachine::FillProducer::StaticFrame;

use strict;
use warnings;

use base 'Video::PlaybackMachine::FillProducer::TextFrame';

sub new {
  my ($type, %in) = @_;

  my $self = $type->SUPER::new(%in);

  $self->{'static_text'} = $in->{'static_text'};
}

##
## add_text()
##
## Write our static text on the frame.
##
sub add_text {
  my ($self) = @_;

  $self->write_centered( $self->{'static_text'} );
}
