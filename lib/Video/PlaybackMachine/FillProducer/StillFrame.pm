package Video::PlaybackMachine::FillProducer::StillFrame;

####
#### Video::PlaybackMachine::FillProducer::StillFrame
####
#### $Revision$
####
#### 
####

use strict;
use warnings;
use Carp;

use base 'Video::PlaybackMachine::FillProducer::AbstractStill';
use POE;

############################# Class Constants #############################

############################## Class Methods ##############################

##
## new()
##
## Arguments: (hash)
##  image => string -- filename of image
##  time => int -- time in seconds image should be displayed
##
sub new {
  my $type = shift;
  my %in = @_;

  my $self = $type->SUPER::new(@_);

  $self->{image} = $in{image};

  return $self;
}

############################# Object Methods ##############################



##
## start()
##
## Displays the StillFrame for the appropriate time. Assumes that
## it's being called within a POE session.
##
sub start {
  my $self = shift;

  $poe_kernel->post('Player', 'play_still', $self->{image}, sub {
  	my ($rv) = @_;
  	if ( $rv == 2 ) {
  		$poe_kernel->delay('next_fill');
  		$poe_kernel->yield('next_fill');
  	}
  });
  $poe_kernel->delay('next_fill', , $self->get_time_layout()->preferred_time());
}

##
## is_available()
##
## Reports that the still is available if the image file is readable.
##
sub is_available {
  return -r $_[0]->{'image'};
}

1;
