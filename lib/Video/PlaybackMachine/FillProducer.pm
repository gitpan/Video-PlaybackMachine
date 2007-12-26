package Video::PlaybackMachine::FillProducer;

####
#### Video::PlaybackMachine::FillProducer
####
#### $Revision: 186 $
####
#### Interface for different ways of producing Fill content.
####

use strict;
use warnings;
use Carp;

############################# Class Constants #############################

############################## Class Methods ##############################

############################# Object Methods ##############################

##
## start()
##
## Arguments:
##  TIME: int -- time in seconds that we're to fill
##
## Starts production of fill content. When it's ready, the
## FillProducer will send a 'still_ready' or 'movie_ready'
## signal.
##
sub start { }

##
## get_time_layout()
##
## Returns:
##   Video::PlaybackMachine::TimeLayout
##
## Returns a TimeLayout that tells us how long the given
## content should be played.
##
sub get_time_layout { }

##
## is_available()
##
## Returns:
##   boolean
##
## Returns true if this producer has something it can do, false otherwise.
##
sub is_available { }

##
## has_audio()
##
## Returns:
##  boolean
##
## Returns true if this producer will produce audio content.
##
sub has_audio { }


1;
