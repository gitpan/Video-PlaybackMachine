#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Cwd 'abs_path';
use Time::Duration;

use Video::PlaybackMachine::ContentManager qw(get_title get_length add_fill);

######################## Script Constants #######################

######################### Main Program ##########################

MAIN: {
  my ($filename, $title, $length) = @ARGV;

  -e $filename or die "File '$filename' not found!\n";

  defined $title or $title = get_title($filename);
  defined $length or $length = get_length($filename);

  add_fill(abs_path($filename), $title, $length);

  print "Added fill: '$title' (", duration($length), ")\n";


}
