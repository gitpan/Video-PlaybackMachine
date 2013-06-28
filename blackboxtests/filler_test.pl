#!/usr/local/bin/perl

use strict;
use warnings;

use POE;
use POE::Kernel;

use Video::PlaybackMachine::MockScheduleTable;
use Video::PlaybackMachine::FillProducer::StillFrame;
use Video::PlaybackMachine::FillSegment;
use Video::PlaybackMachine::Filler;
use Video::PlaybackMachine::Scheduler;

use constant TEST_FILE => 't/test_movies/time_015.mp4';
use constant TEST_STILL => 't/test_movies/test_logo.png';

MAIN: {

  # Create a mock ScheduleTable playing the test pattern now, doing a fill for 15 seconds, then restarting the test pattern after 2
  my $now = time();
  my $sched_table = Video::PlaybackMachine::MockScheduleTable->new($now,
								  'Video::PlaybackMachine::Movie');
  $sched_table->add({
		     start_off => 0,
		     duration => 15,
		     file => TEST_FILE
		    });
  $sched_table->add({
		     start_off => 32,
		     duration => 15,
		     file => TEST_FILE
		    });

  # Create a Filler that can fill in with a slide
  my $still_producer = Video::PlaybackMachine::FillProducer::StillFrame->new(
									     image => TEST_STILL,
									     time => 15
									    );
  my $still_seg = Video::PlaybackMachine::FillSegment->new(
							   name => 'Identification',
							   sequence_order => 0,
							   priority_order => 0,
							   producer => $still_producer
							   );
  my $filler = Video::PlaybackMachine::Filler->new(
						   segments => [$still_seg]
						  );

  # Create a Scheduler that will use these
  my $scheduler = Video::PlaybackMachine::Scheduler->new(
							 filler => $filler,
							 schedule_table => $sched_table,
							 offset => 0
							 );

  $scheduler->spawn();
  
  POE::Kernel->run();


}
