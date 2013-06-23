package Video::PlaybackMachine::ScheduleEntry;

####
#### Video::PlaybackMachine::ScheduleEntry
####
#### Represents a single listing in the schedule.
####

use strict;
use warnings;
use diagnostics;
use Carp;

use overload '""' => sub { $_[0]->as_string() };

########################### Class Methods #################################

##
## new()
##
##  Arguments:
##   START_TIME: scalar -- Unix raw time that the entry will start
##   LISTING: Video::PlaybackMachine::Movie -- Listing for content appearing here
##
sub new {
  my $type = shift;
  my ($time, $listing) = @_;
  defined($time) && defined($listing) or croak("Usage: $type->new(TIME, LISTING)");
  $time =~ m{^\d+$} or croak("TIME '$time' must be an integer");

  my $self = {
	      Start_Time => $time,
	      Listing => $listing
	     };

  bless $self, $type;
}

########################## Object Methods #################################

##
## get_start_time()
##
## Returns the time that the entry should be scheduled to begin.
##
sub get_start_time {
  my $self = shift;

  return $self->{Start_Time};

}

##
## get_finish_time()
##
## Returns the time that the entry is scheduled to end.
##
sub get_finish_time {
  my $self = shift;

  return $self->{Start_Time} + $self->get_listing()->get_length();
}

##
## get_listing()
##
## Returns the listing that will take place at the given time.
##
sub get_listing {
  my $self = shift;

  return $self->{Listing};
}

sub get_title {
  return $_[0]->{'Listing'}->get_title();
}

sub as_string {
    return $_[0]->get_title();
}

1;
