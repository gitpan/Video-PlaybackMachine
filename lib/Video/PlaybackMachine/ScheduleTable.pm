package Video::PlaybackMachine::ScheduleTable;

####
#### Video::PlaybackMachine::ScheduleTable
####
#### This module documents the interface for accessing schedule-table objects.
#### 

use strict;

############################## Class Constants #####################################

############################## Class Methods #######################################

############################## Object Methods ######################################

##
## get_entries_after()
##
## Arguments:
##    TIME: scalar -- UNIX raw time
##
## Returns all entries which start after a given time. In scalar context,
## returns the first entry after the given time.
##
sub get_entries_after { }


##
## get_entry_during()
##
## Arguments:
##    TIME: scalar -- UNIX raw time
##
## Returns the schedule entry in which TIME takes place.
## Returns an empty list / undef if there is no scheduled program taking place
## at the given time.
##
sub get_entry_during { }


1;
