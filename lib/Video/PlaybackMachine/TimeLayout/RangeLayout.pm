package Video::PlaybackMachine::TimeLayout::RangeLayout;

####
#### Video::PlaybackMachine::TimeLayout::RangeLayout
####
#### $Revision$
####
#### A TimeLayout that indicates that the FillProducer can produce
#### content for a certain minimum and a certain maximum amount of
#### time.
####
#### An example is the FillShort producer, which plays short films.
#### It has short films available to it in a certain range of sizes.
#### It would return a RangeLayout consisting of the time of the
#### shortest short for the minimum and the time of the longest
#### fitting short for the maximum.
####

use strict;
use warnings;

use Carp;

############################ Class Constants #########################

############################# Class Methods ##########################

##
## new()
##
## Arguments:
##   MIN_TIME: int -- minimum amount of time we can run
##   MAX_TIME: int -- maximum amount of time we can run
##
sub new {
  my $type = shift;
  my ($min_time, $max_time) = @_;

  defined $min_time or croak($type, "::new() missing 'MIN_TIME' parameter");
  defined $max_time or croak($type, "::new() missing 'MAX_TIME' parameter");

  my $self = { min_time => $min_time,
	       max_time => $max_time
	     };

  bless $self, $type;

}


############################ Object Methods ####################

##
## min_time()
##
## Returns the minimum amount of time the fill can take.
##
sub min_time {
  return $_[0]->{'min_time'};
}
