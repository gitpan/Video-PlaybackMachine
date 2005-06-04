package Video::PlaybackMachine::AbstractListable;

=pod

=head1 NAME

Video::PlaybackMachine::AbstractListable

=head1 DESCRIPTION

Abstract class for anything that can be listed in a schedule.

=cut

####
#### Video::PlaybackMachine::AbstractListable
####
#### $Revision: 1.2 $
####
#### Represents something that can be listed in a schedule.
#### This class contains some methods common to all types of movies.
####

use strict;
use warnings;
use base 'Video::PlaybackMachine::Listable';

############################# Class Constants #############################

############################## Class Methods ##############################

=pod

=head1 CLASS METHODS

=over 4

=cut

=pod

=item

new( title => $title, description => $desc )

Creates a new AbstractListable object.

=cut
sub new {
  my $type = shift;
  my %in = @_;

  my $self = {
	      title => $in{title},
	      description => $in{description}
	     };

  bless $self, $type;

}

=pod

=back

=cut

############################# Object Methods ##############################

=pod

=head1 OBJECT METHODS

=over 4

=cut

##
## get_title()
##
## Returns the title of the item.
##
=pod

=item get_title()

Returns the title of the item.

=cut
sub get_title { 
  return $_[0]->{'title'};
}

##
## get_description()
##
## Returns a description of the item.
##
=pod

=item get_description()

=cut
sub get_description { 
  return $_[0]->{'description'};
}

1;
