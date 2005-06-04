package Video::PlaybackMachine::FillProducer::Chooser;

####
#### Video::PlaybackMachine::FillProducer::Chooser
####
#### $Revision: 1.1 $
####
#### Picks content in random or quasi-random order. Does not pick
#### anything twice until all have been chosen. Will preferentially display
#### new content.
####

use strict;
use warnings;
use IO::Dir;
use File::stat;
use Log::Log4perl;


############################# Class Constants ###########################

############################## Class Methods ############################

##
## new()
##
## Arguments: (hash)
##   DIRECTORY: string -- Directory from which we should choose things
##   FILTER: regexp -- Regular expression matching things we should return
##
sub new {
  my $type = shift;
  my (%in) = @_;
  my $self = {
	      DIRECTORY => $in{DIRECTORY},
	      FILTER => $in{FILTER},
	      SEEN => {},
	      ITEMS => [],
	      LOGGER => Log::Log4perl->get_logger('Video::PlaybackMachine::Filler::Chooser'),
	     };
  bless $self, $type;
}

############################# Object Methods ##############################

##
## choose()
##
## Returns an item from a randomly-selected list. Items which have
## appeared during program run are played sooner.
##
sub choose {
  my $self = shift;

  $self->_reload_items();

  return shift @{ $self->{'ITEMS'} };

}

##
## is_available()
##
## Returns true if calling choose() would return an item.
##
sub is_available {
  my $self = shift;

  $self->_reload_items();
  return @{ $self->{'ITEMS'} } > 0;
}

##
## Loads any new items (i.e. files)
##
sub _reload_items {
  my $self = shift;
  my @new_items = $self->_get_new_items();
  $self->{'ITEMS'} = [ @new_items, @{ $self->{'ITEMS'} } ];

  if (@{$self->{'ITEMS'}} == 0) {
    $self->{'SEEN'} = {};
    $self->{'ITEMS'} = [ $self->_get_new_items() ];
  }

  return 1;
}


sub _get_new_items {
  my $self = shift;

  -d $self->{'DIRECTORY'}
    or do {
      $self->{'LOGGER'}->warn("Directory '$self->{'DIRECTORY'}' does not exist");
      return;
    };
  my $dh = IO::Dir->new($self->{'DIRECTORY'})
    or die "Couldn't open directory $self->{'DIRECTORY'}: $!; stopped";
  my @files = ();
  while ( my $file = $dh->read() ) {
    $file =~ /\.^/ and next;
    if ($self->{'FILTER'}) {
      $file =~ /$self->{'FILTER'}/ or next;
    }
    my $full_file = "$self->{'DIRECTORY'}/$file";
    -f $full_file or next;
    $self->{'SEEN'}{$full_file}++ and next;
    push(@files, $full_file);
  }

  return $self->_random_sort(@files);
}

sub _random_sort {
  my $self = shift;
  my (@items) = @_;

  my %st = ();
  my $getval = sub {
    my ($x) = @_;

    if (! exists $st{$x}) {
      $st{$x} = rand();
    }
    return $st{$x};
  };
  return sort {$getval->($a) <=> $getval->($b)} @items;

}


1;
