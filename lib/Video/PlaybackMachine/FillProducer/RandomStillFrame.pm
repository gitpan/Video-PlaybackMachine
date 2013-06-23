package Video::PlaybackMachine::FillProducer::RandomStillFrame;

####
#### Video::PlaybackMachine::FillProducer::RandomStillFrame
####
#### $Revision$
####
#### Plays a randomly-chosen still frame from a directory.
####

use strict;
use warnings;
use Carp;

use base 'Video::PlaybackMachine::FillProducer';
use POE;

use IO::Dir;

############################# Class Constants ############################

############################## Class Methods ##############################

##
## new()
##
## Arguments: (hash)
##  directory => string -- Directory containing images to display
##  time => int -- time in seconds image should be displayed
##
sub new {
  my $type = shift;
  my %in = @_;

  my $self = $type->SUPER::new(@_);

  $self->{directory} = $in{directory};

  return $self;
}

############################# Object Methods ##############################


sub is_available {
  my $self = shift;

  -d $self->{'directory'} or return;
  $self->getFrames() >= 1 or return;
  return 1;

}

sub getFrames {
  my $self = shift;

  my $dh = IO::Dir->new($self->{'directory'});
  my @frames = ();
  while ( my $file = $dh->read() ) {
    next if $file =~ /^\./;
    next unless -f "$self->{'directory'}/$file";
    push(@frames, "$self->{'directory'}/$file");
  }
  return @frames;
}


##
## start()
##
## Displays a random still frame for the appropriate time. Assumes that
## it's being called within a POE session.
##
sub start {
  my $self = shift;

  my @frames = $self->getFrames();
  my $frame = $frames[ rand( scalar @frames ) ];

  $poe_kernel->yield('still_ready', $frame, $self->get_time_layout()->min_time());
}

1;
