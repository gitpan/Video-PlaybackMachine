package Video::PlaybackMachine::FillProducer::FillShort;

####
#### Video::PlaybackMachine::FillProducer::FillShort
####
#### $Revision: 1.3 $
####
#### Plays a randomly-chosen short from the fill contents database
#### that fits into the time available.
#### 
#### In a slightly scurvy trick, FillShort also defines its own time layout,
#### which allows it to query the database whenever someone asks it.
####

# TODO: extract DB code from ScheduleTable::DB
#
# TODO: Split fill producers from fill displayers (?)

use strict;
use warnings;
use Carp;
use POE;

use base qw(Video::PlaybackMachine::FillProducer
            Video::PlaybackMachine::TimeLayout
);
use Video::PlaybackMachine::TimeLayout::FixedTimeLayout;
use Video::PlaybackMachine::AVFile;


########################### Class Constants #######################


############################ Class Methods ########################

##
## new()
##
## Arguments:
##   TABLE -- ScheduleTable::DB
##
## Creates a new FillShort which uses the DBI connection given.
##
sub new {
  my $type = shift;
  my ($st) = @_;
  my $self = {
	      st => $st,
	      seen => {}
	     };
  bless $self, $type;

}

##
## get_time_layout()
##
## Returns:
##   Video::PlaybackMachine::FillShort
##
## In a scurvy trick, we're our own time layout object. That way, the
## time layout can query the database for minimum and preferred times.
##
sub get_time_layout {
  return $_[0];
}

##
## start()
##
## Arguments:
##  TIME: int -- time in seconds that we're to fill
##
sub start {
  my $self = shift;
  my ($time) = @_;

  my @fills = $self->{'st'}->get_fills($time)
    or return;
  foreach my $avfile (@fills) {
    my $file = $avfile->get_file();
    $self->{seen}{$file}++ and next;
    $poe_kernel->yield('short_ready', $file);
    return 1;
  }
  $self->{'seen'} = {};
  $self->start($time);
}

##
## min_time()
##
## Returns the minimum amount of time this filler can run, i.e. the
## shortest short. Caches its values to minimize database calls.
##
sub min_time {
  my $self = shift;

  unless (  defined $self->{'min_time'} ) {

    defined($self->{'min_time'} = $self->{'st'}->get_min_fill())
      or croak "No available shorts";

  }

  return $self->{'min_time'};
}

##
## preferred_time()
##
## Returns the length of the longest fillmovie. (Sorry, it just got
## too strange referring to the "longest short.") Possibly this
## behavior is a bug in the architecture, but it's the only sane
## deterministic value. Better behavior would be to return the length
## of the movie which we will play next, but there's a random factor
## there.
##
sub preferred_time {
  my $self = shift;

  unless ( defined $self->{'preferred_time'} ) {
    defined($self->{'preferred_time'} = $self->{'st'}->get_max_fill())
      or croak "No available shorts";
  }

  return $self->{'preferred_time'};
}

##
## is_available()
##
## Returns true if there are shorts available to play.
##
sub is_available {
  my $self = shift;

  return defined($self->{'st'}->get_max_fill());
}

##
## get_next()
##
## Returns the sequence number of the next short to play
##
sub get_next {
  return $_[1] + 1;
  
}
1;
