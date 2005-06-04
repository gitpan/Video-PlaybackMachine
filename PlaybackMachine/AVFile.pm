package Video::PlaybackMachine::AVFile;

####
#### Video::PlaybackMachine::AVFile
####
#### $Revision: 1.1 $
####
#### An MPEG, PNG, OGG, or other file which can be played.
####

use strict;
use warnings;

############################# Class Constants #############################

############################## Class Methods ##############################

##
## new()
##
## Arguments:
##   FILE: string -- Path to a file
##   LENGTH: integer -- Play length of the file in seconds.
##
sub new {
  my $type = shift;
  my ($file, $length) = @_;

  my $self = {
	      file => $file, 
	      length => $length
	     };
  bless $self, $type;
}


############################# Object Methods ##############################

##
## get_length()
##
## Returns the duration of the AV file in seconds.
##
sub get_length { return $_[0]->{length}; }

##
## get_file()
##
## Returns the filename.
##
sub get_file { return $_[0]->{file}; }

1;
