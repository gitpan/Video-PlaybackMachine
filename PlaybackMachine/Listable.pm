package Video::PlaybackMachine::Listable;

####
#### Video::PlaybackMachine::Listable
####
#### $Revision: 1.1 $
####
#### Represents something that can be listed in a schedule.
#### In other words, it's a movie.
#### This is an interface.
####

use strict;
use warnings;

############################# Class Constants #############################

############################## Class Methods ##############################

############################# Object Methods ##############################


##
## get_title()
##
## Returns the title of the item.
##
sub get_title { }

##
## get_description()
##
## Returns a description of the item.
##
sub get_description { }

##
## get_length()
##
## Returns the length of the item in seconds. Items with no
## set length return 0.
##
sub get_length { }

##
## prepare()
##
## Does whatever is necessary to make this item ready to play. Called
## when the item is scheduled. Returns true if the item was successfully
## prepared and should be scheduled, false otherwise.
##
sub prepare { }

##
## play()
## 
## Arguments:
##   OFFSET: integer -- amount of time to skip before beginning.
##
## Issues whatever command is necessary to play this item.
##
sub play {}


1;
