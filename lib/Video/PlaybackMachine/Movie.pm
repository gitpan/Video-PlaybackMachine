package Video::PlaybackMachine::Movie;

####
#### Video::PlaybackMachine::Movie
####
#### $Revision$
####
#### Represents a movie on the schedule.
####

use strict;
use warnings;
use diagnostics;

use POE;
use Carp;

############################# Class Constants #############################

##
## new()
##
## Arguments: hash
##   title: string
##   description: string
##   av_files: arrayref -- list of Video::PlaybackMachine::AVFile objects
##
sub new {
  my $type = shift;
  my %in = @_;

  unless (ref $in{'av_files'} && ref $in{'av_files'} eq 'ARRAY') {
  	croak("${type}::new(): Argument '$in{av_files}' for 'av_files' must be an array reference; stopped");
  }
  @{ $in{av_files} } > 0
    or confess("${type}::new(): Must have at least one AV::File object");
  foreach (@{ $in{av_files} } ){
    ( ref $_ && ref $_ eq 'Video::PlaybackMachine::AVFile' )
      or croak("$type::new(): Argument '$_' is not an AVFile object");
  }

  my $self = {
	      title => $in{title},
	      description => $in{description},
	      av_files => [ @{ $in{av_files} } ]
	     };

  bless $self, $type;

  return $self;
}

############################## Object Methods ##############################

##
## get_length()
##
## Returns the length of the item in seconds. Items with no
## set length return 0.
##
sub get_length {
  my $self = shift;
  
  my $length = 0;
  foreach ( @{ $self->{av_files} } ) {
    $length += $_->get_length();
  }
  return $length;
}

##
## prepare()
##
## Does whatever is necessary to make this item ready to play. Called
## when the item is scheduled. Returns true if the item was successfully
## prepared and should be scheduled, false otherwise.
##
sub prepare {
  my $self = shift;

  foreach ( $self->get_av_files() ) {
    -e $_->get_file() or do {
      warn "Attempt to use nonexistent file '@{[ $_->get_file() ]}'\n";
      return;
    };
  }

  return 1;

}

##
## play()
## 
## Arguments:
##   OFFSET: integer -- amount of time to skip before beginning.
##
## Issues whatever command is necessary to play this item.
##
sub play {
  my $self = shift;
  my ($offset) = @_;

  my $session = $poe_kernel->get_active_session();

  $poe_kernel->post('Player', 'play', $session->postback('finished', $self, time()), $offset, map { $_->get_file() } $self->get_av_files());
}

##
## get_av_files()
##
## Returns a list of the AV files associated with this movie.
##
sub get_av_files {
  my $self = shift;

  return @{ $self->{av_files} };
}

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
