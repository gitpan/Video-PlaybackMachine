#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Time::HiRes;
use POE;
use POE::Session;
use POE::Kernel;

use Video::PlaybackMachine::Player;
use DBI;

########################## Script Constants #############################

our $Scan_Seconds = 3;

############################ Main Program ###############################

MAIN: {

  # Initialize logger
  Log::Log4perl::init('/etc/playback_machine/playback_log.conf');  

  # Get movies from database
  my @movies = get_movies();

  # Spawn a session to play movies one after the other
  POE::Session
      ->create(
	       inline_states 
	       => {

		   # Start sets up the Player and runs the first movie
		   _start
		   => sub {
		     $_[HEAP]{'movies'} = \@movies;
		     my $player = Video::PlaybackMachine::Player->new();
		     $player->spawn();
		     run_next();
		   },

		   # After five seconds the movie is stopped
		   stop_movie
		   => sub {
		     $_[KERNEL]->call('Player', 'stop');
		     $_[KERNEL]->yield('finished', $_[ARG0], ["OK"]);
		   },

		   # When the Player says we're done, print the result code
		   finished
		   => sub {
		     $_[KERNEL]->delay('stop_movie'); # clear stops
		     print $_[ARG0]->[0], "\t", @{ $_[ARG1] }, "\n";
		     run_next() or exit(0);
		   }

		  }
		      );

  POE::Kernel->run();


}

############################ Subroutines ##############################


##
## Returns a list of movies
##
sub get_movies {
  my $dbh = DBI->connect( "dbi:Pg:dbname=playback_machine", '', '' )
    or die "Couldn't connect to database: $DBI::errstr";
  $dbh->{'RaiseError'} = 1;

  return @{ $dbh->selectall_arrayref('SELECT title, file from av_file_component ORDER BY title') };

}

##
## Runs the next movie
##
sub run_next {
  my $session = $poe_kernel->get_active_session();
  my $movies = $session->get_heap()->{'movies'};
  scalar(@$movies) or return;
  my $next_movie = shift @$movies;
  my $postback = $session->postback('finished', $next_movie->[0], $next_movie->[1]);
  $poe_kernel->post('Player', 'play', $postback, 0, $next_movie->[1]);
  $poe_kernel->delay('stop_movie', $Scan_Seconds, $next_movie);
  return 1;

}

