package Video::PlaybackMachine::FillProducer::AbstractStill;

####
#### Video::PlaybackMachine::FillProducer::AbstractStill
####
#### $Revision: 1.3 $
####
#### 
####

use strict;
use warnings;
use Carp;

use base 'Video::PlaybackMachine::FillProducer';

use Video::PlaybackMachine::TimeLayout::FixedTimeLayout;


############################# Class Constants #############################

############################## Class Methods ##############################

##
## new()
##
## Arguments: (hash)
##  time: int -- Time in seconds that we want to display a still
##
sub new {
  my $type = shift;
  my %in = @_;

  defined $in{time} or croak($type, "::new() called incorrectly");

  my $self = {
	      time_layout => 
	      Video::PlaybackMachine::TimeLayout::FixedTimeLayout->new($in{time})
	     };

  bless $self, $type;
}


############################# Object Methods ##############################

##
## get_time_layout()
##
## Returns the FixedTimeLayout for the appropriate time.
##
sub get_time_layout {
  $_[0]->{time_layout};
}


##
## has_audio()
##
## Stills don't have an audio track.
##
sub has_audio { return; }

##
## is_available()
##
## Stills are always available. Unless they aren't.
##
sub is_available { 1; }



1;
