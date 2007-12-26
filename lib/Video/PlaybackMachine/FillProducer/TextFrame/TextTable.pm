package Video::PlaybackMachine::FillProducer::TextFrame::TextTable;

use strict;
use warnings;

sub new {
  my $type = shift;
  my %in = @_;

  my $self = {
	      image => $in{image},
	      border => $in{border},
	      rows => [],
	      height => 0,
	      width => 0
	     };

  bless $self, $type;
}

sub get_image {
  return $_[0]->{'image'};
}

sub get_height {
  return $_[0]->{'height'};
}

sub get_width {
  return $_[0]->{'width'};
}

sub add_row {
  my $self = shift;
  my (@columns) = @_;

  my $row = 
    Video::PlaybackMachine::FillProducer::TextFrame::Row->new(
							      $self->{'image'},
							      $self->{'border'},
							      @columns);
  
  # Return undef if we're too long (vertically) for the screen
  my $new_height = $self->{'height'} + $row->get_height() + $self->{'border'};
  $new_height > $self->get_image()->get_height()
    and return;
  $self->{'height'} = $new_height;

  # Update maximum width
  $self->{'width'} = $row->get_width()
    if $row->get_width() > $self->{'width'};

  # Store the row
  push(@{ $self->{'rows'} }, $row);

  return 1;
}

sub get_start_ycoord {
  my $self = shift;

  return int(($self->get_image()->get_height() - $self->get_height()) / 2);
}

sub get_start_xcoord {
  my $self = shift;

  return int(($self->get_image()->get_width() - $self->get_width()) / 2);

}

sub draw {
  my $self = shift;

  my $x = $self->get_start_xcoord();
  my $y = $self->get_start_ycoord();
  foreach my $row (@{ $self->{'rows'} }) {
    $row->draw($x, $y);
    $y += $row->get_height();
  }
}

package Video::PlaybackMachine::FillProducer::TextFrame::Row;

use strict;
use warnings;

sub new {
  my $type = shift;
  my ($image, $border, @columns) = @_;

  my $self = {
	     image => $image,
	     border => $border,
	     columns => [ 
			 map { Video::PlaybackMachine::FillProducer::TextFrame::Column->new($image, $_); } @columns
			],
	    };

  bless $self, $type;
}

sub get_columns {
  return @{ $_[0]->{'columns'} };
}

sub get_dimensions {
  my $self = shift;

  if (! defined $self->{'dimensions'} ) {

    my $total_width = 0;
    my $max_height = 0;

    foreach my $column ( @{ $self->{'columns'} } ) {
      my ($width, $height) = $column->get_dimensions( $self->{'image'}->get_width() - $total_width );
      $total_width += ($width + $self->{'border'});
      $max_height = $height if $height > $max_height;
    }

    $self->{'dimensions'} = [$total_width - $self->{'border'}, $max_height];
  }

  return @{ $self->{'dimensions'} };

}

sub get_width {
  my $self = shift;
  my ($width, undef) = $self->get_dimensions();
  return $width;
}

sub get_height {
  my $self = shift;
  my (undef, $height) = $self->get_dimensions();
  return $height;
}

sub draw {
  my $self = shift;
  my ($x, $y) = @_;

  my $currx = $x;
  foreach my $column ( $self->get_columns() ) {
    my $width_left = $self->{'image'}->get_width() - $currx;
    $column->draw($currx, $y,  $width_left);
    $currx += ($column->get_dimensions($width_left))[0];
    $currx += $self->{'border'};
  }
  return 1;
}

package Video::PlaybackMachine::FillProducer::TextFrame::Column;

# TODO: Make 'wrap_width' a parameter to 'new'

use strict;
use warnings;

sub new {
  my $type = shift;
  my ($image, $text) = @_;

  my $self = {
	      image => $image,
	      text => $text,
	     };
  bless $self, $type;
}

sub draw {
  my $self = shift;
  my ($x, $y, $width) = @_;

  my $y_curr = $y;
  foreach my $line ( $self->get_lines($width) ) {
    chomp($line);
    my ($width, $height) = $self->{'image'}->get_text_size($line);
    $self->{'image'}->draw_text($x, $y_curr, $line);
    $y_curr += $height;
  }
}

sub get_dimensions {
  my $self = shift;
  my ($wrap_width) = @_;
  my ($width, $height) = $self->_wrap_lines($wrap_width);
  return $width, $height;
}


sub get_lines {
  my $self = shift;
  my ($wrap_width) = @_;
  my (undef, undef, @lines) = $self->_wrap_lines($wrap_width);
  return @lines;
}


sub _wrap_lines {
  my $self = shift;
  my ($wrap_width) = @_;


  my @lines = ();
  my $total_height = 0;
  my $max_width = 0;

  foreach my $text ( split(/\n/, $self->{'text'}) ) {

    my @atoms = split(/(\s+)/, $text);
    
    my $curr_line = shift @atoms;
    defined $curr_line or $curr_line = '';
    my ($line_width, $line_height) = $self->{'image'}->get_text_size($curr_line);
    $total_height += $line_height;

    
    foreach my $atom (@atoms) {
      my ($width, $height) = $self->{'image'}->get_text_size($atom);

      # If the current atom makes the line wrap, do it
      if ( ( $line_width + $width ) > $wrap_width ) {
	push(@lines, $curr_line);
	$curr_line = $atom;
	$max_width = $line_width if $line_width > $max_width;
	$line_width = $width;
	$total_height += $height;
      }
      # Otherwise, append atom to current line
      else {
	$curr_line .= $atom;
	$line_width += $width;
      }
    }
    push(@lines, $curr_line);
    $max_width = $line_width if $line_width > $max_width;
  }

  return $max_width, $total_height, @lines;
  
}

1;
