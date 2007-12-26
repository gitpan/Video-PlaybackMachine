package Video::PlaybackMachine::AbstractListable;

####
#### Video::PlaybackMachine::AbstractListable
####
#### $Revision: 134 $
####
#### Represents something that can be listed in a schedule.
#### This class contains some methods common to all types of movies.
####

use strict;
use warnings;
use base 'Video::PlaybackMachine::Listable';

############################# Class Constants #############################

############################## Class Methods ##############################

sub new {
  my $type = shift;
  my %in = @_;

  my $self = {
	      title => $in{title},
	      description => $in{description}
	     };

  bless $self, $type;

}

############################# Object Methods ##############################

##
## get_title()
##
## Returns the title of the item.
##
sub get_title { 
  return $_[0]->{'title'};
}

##
## get_description()
##
## Returns a description of the item.
##
sub get_description { 
  return $_[0]->{'description'};
}

1;
