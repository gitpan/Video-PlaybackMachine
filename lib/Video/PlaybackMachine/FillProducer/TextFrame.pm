package Video::PlaybackMachine::FillProducer::TextFrame;

####
#### Video::PlaybackMachine::FillProducer::TextFrame
####
#### $Revision: 265 $
####

use strict;
use warnings;
use Carp;

use base 'Video::PlaybackMachine::FillProducer::AbstractStill';
use POE;

use Image::Imlib2;
use File::Temp qw(tempfile);
use POSIX qw(strftime);

############################# Class Constants #############################

our $Width = 800;
our $Height = 600;

our @Background_Color = (0,0,100,255);

our @Text_Color = (0,255,255,255);

our @Font_Path = qw(/usr/share/fonts/bitstream-vera);

our $Font = "Vera";

our $Font_Size = "40";

############################## Class Methods ##############################

##
## new()
##
## Arguments: (hash)
##  font => string  -- name of truetype font (i.e "Vera")
##  font_size => integer -- size of truetype font
##
sub new {
  my $type = shift;
  my $self = $type->SUPER::new(@_);
  my %in = @_;
  $self->{'font'} = defined $in{font} ? $in{font} : $Font;
  $self->{'font_size'} = defined $in{font_size} ? $in{font_size} : $Font_Size;
  return $self;
}


############################# Object Methods ##############################


##
## start()
##
sub start {
  my $self = shift;

  my $image = $self->create_image()
    or die "Couldn't create image for some reason";
  
  $self->add_text($image);

  my ($fh, $filename) = tempfile( SUFFIX => '.png');
  $image->save($filename);

  # Scurvy trick-- passing the filehandle as an unused argument so that 
  # it will survive as long as the event does.
  $poe_kernel->post('Player', 'play_still', $filename, undef, undef, $fh);
  $poe_kernel->delay('next_fill', , $self->get_time_layout()->preferred_time());

}

sub get_font {
  return $_[0]{'font'};
}

sub get_font_size {
  return $_[0]{'font_size'};
}

sub get_font_string {
  my $self = shift;
  return $self->get_font() . '/' . $self->get_font_size();
}


##
## create_image()
##
sub create_image {
  my $self = shift;

  my $image = Image::Imlib2->new($Width, $Height);
  
  $image->set_color(@Background_Color);
  $image->fill_rectangle(0,0,$Width,$Height);
  
  $image->set_color(@Text_Color);
  $image->add_font_path(@Font_Path);
  $image->load_font($self->get_font_string() );

  return $image;
}

sub measure_block {
  my $self = shift;
  my ($image, @lines) = @_;

  my $max = 0;
  my $total = 0;
  foreach my $line (@lines) {
    my ($width, $height) = $image->get_text_size($line);
    $max = $width if $width > $max;
    $total += $height;
  }
  return ($max,$total);
}

sub max_width {
  my $self = shift;
  my ($image, @lines) = @_;

  my ($max, undef) = $self->measure_block($image, @lines);
  return $max;

}

sub total_height {
  my $self = shift;
  my ($image, @lines) = @_;

  my (undef, $total) = $self->measure_block($image, @lines);
  return $total;
}

sub write_block {
  my $self = shift;
  my ($image, $x, $y, @lines) = @_;

  my $y_curr = $y;
  my $max_width = 0;
  foreach my $line (@lines) {
    chomp($line);
    my $y_next = $y_curr;
    my ($width, $height)  = $image->get_text_size($line);
    $y_next += $height;
    $width > $max_width and $max_width = $width;
    last if ($y_next > $image->get_height());
    $image->draw_text($x, $y_curr, $line);
    $y_curr = $y_next;
  }
  
  return ($x + $max_width, $y_curr);
}

sub write_centered {
  my $self = shift;
  my ($image, $text) = @_;

  my ($words_height, @lines) = wrap_words($image, $text);
  my $start_height = ( $Height - $words_height ) / 2;
  draw_centered($image, $start_height, @lines);

}

sub wrap_words {
  my ($image, $in_text, $wrap_width) = @_;

  defined $wrap_width 
    or $wrap_width = $image->get_width();

  my @lines = ();
  my $total_height = 0;

  foreach my $text ( split(/\n/, $in_text) ) {

    my @atoms = split(/(\s+)/, $text);
    
    my $curr_line = shift @atoms;
    defined $curr_line or $curr_line = '';
    my ($line_width, $line_height) = $image->get_text_size($curr_line);
    $total_height += $line_height;

    foreach my $atom (@atoms) {
      my ($width, $height) = $image->get_text_size($atom);
      if ( ( $line_width + $width ) > $wrap_width ) {
	push(@lines, $curr_line);
	$curr_line = $atom;
	$line_width = $width;
	$total_height += $height;
      }
      else {
	$curr_line .= $atom;
	$line_width += $width;
      }
    }
    push(@lines, $curr_line);
  }
  return $total_height, @lines;

}

sub draw_centered {
  my ($image, $starty, @lines) = @_;

  my $y = $starty;

  foreach my $line (@lines) {
    my @words = split(/(\s+)/, $line);
    my ($width, $height) = $image->get_text_size($line, TEXT_TO_RIGHT, 0);
    my $x = ($image->get_width() - $width) / 2;
    $image->draw_text($x, $y, $line);
    $y += $height;
  }

  return $y;
}

1;
