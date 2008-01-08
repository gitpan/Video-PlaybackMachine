use strict;
use warnings;

use lib qw{lib t/lib};

#use Test::More tests => 9;
use Test::More skip_all => 'Need to find POE::Component::MockSession';
BEGIN { use_ok('Video::PlaybackMachine::Scheduler') };

use Test::MockObject;
use POE;
use POE::Component::MockSession;
use Video::PlaybackMachine::MockScheduleTable qw(mock_schedule_table);

use Video::PlaybackMachine::AVFile;
use Video::PlaybackMachine::ScheduleEntry;
use Video::PlaybackMachine::Scheduler;

use Data::Dumper;
use Log::Log4perl;

#########################

Log::Log4perl::init( \'log4perl.logger.Video = OFF, Screen
log4perl.appender.Screen = Log::Log4perl::Appender::Screen
log4perl.appender.Screen.layout = Log::Log4perl::Layout::SimpleLayout
' );


MAIN: {

  # Mock up a fake ScheduleTable
  my $now = time();
  my $mock_table = mock_schedule_table($now);

  # Spawn a fake Player/Filler to check play and fill calls
  my $mock_player = POE::Component::MockSession->new(alias => ['Player']);
  my $mock_filler = POE::Component::MockSession->new(alias => ['Filler']);

  # Spawn a Scheduler with our fake ScheduleTable, resetting the skip tolerance to 5 seconds
  # and telling it to terminate when finished
  my $scheduler = Video::PlaybackMachine::Scheduler->new(
							 skip_tolerance => 5,
							 schedule_table => $mock_table,
							 player => $mock_player,
							 filler => $mock_filler
							);

  is($scheduler->get_time_to_next(), 20, "get_time_to_next");


  $scheduler->spawn();
  
  # Roll 'em
  $poe_kernel->run();

  # Check that the player was called the expected number of times
  is(scalar $mock_player->get_calls('play'), 5, 'Number of times Player got called');

  # Check fill calls and args against expected time
 SKIP: {
      skip('Need to reconstruct MockSession', 1);
      compare_calltimes($mock_filler, 'start_fill', $now, [ 10 ]);
  }
}

##
## compare_calltimes()
##
## Arguments:
##   MOCK_SESSION: POE::Component::MockSession -- Mock object with times
##   STATE: string -- Name of state we're comparing times for
##   NOW: integer -- Start time
##   TIMES: arrayref -- Times, within tolerance, we expected to be called
##   TOLERANCE: integer -- Number of seconds of tolerance
##
## Generates a single test for each call, and a test for each call time.
##
sub compare_calltimes {
  my ($mock_session, $state, $now, $times, $tolerance) = @_;

  defined $tolerance or $tolerance = 2;

  my @calltimes = map { $_->[0] } ($mock_session->get_calls($state));


  for (my $idx = 0; $idx < scalar(@$times); $idx++) {
    my $act_diff = abs($calltimes[$idx] - $now);
    if (defined $times->[$idx]) {
	ok( abs( $act_diff - $times->[$idx] ) < $tolerance,
	    "For state '$state': call time '$act_diff' - '$times->[$idx]' within tolerance" );
    }
    else {
	fail("Missing time entry");
    }
  }

}



BEGIN {
  sub POE::Component::MockSession::get_status { 1; }
}
