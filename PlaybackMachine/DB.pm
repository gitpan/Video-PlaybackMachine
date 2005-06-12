package Video::PlaybackMachine::DB;

use strict;
use warnings;
use diagnostics;

=pod

=head1 NAME

Video::PlaybackMachine::DB

=head1 DESCRIPTION

Singleton database class for PlaybackMachine.

=cut

use Carp;

use Video::PlaybackMachine::Config;


####################### Module Constants #########################

our $Database_Name = Video::PlaybackMachine::Config->config()->database();

####################### Class Methods ############################

sub db {
  my $type = shift;

  my $dbh = DBI->connect_cached( "dbi:Pg:dbname=$Database_Name", '', '', 
			      {
			       RaiseError => 1,
			       AutoCommit => 1
			      }
			    )
    or croak("Couldn't open database '$Database_Name' for reading: ",
	     DBI->errstr(), ", stopped");

  return $dbh;

}



1;
