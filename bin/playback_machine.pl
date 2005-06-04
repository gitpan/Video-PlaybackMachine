#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Getopt::Long;

use Log::Log4perl;


use Video::PlaybackMachine::ScheduleTable::DB;
use Video::PlaybackMachine::DatabaseWatcher;
use Video::PlaybackMachine::FillSegment;
use Video::PlaybackMachine::Filler;
use Video::PlaybackMachine::Scheduler;
use Video::PlaybackMachine::FillProducer::SlideShow;
use Video::PlaybackMachine::FillProducer::FillShort;
use Video::PlaybackMachine::FillProducer::StillFrame;
use Video::PlaybackMachine::FillProducer::UpNext;
use Video::PlaybackMachine::FillProducer::NextSchedule;

our $TZ = 'PDT';
our $Skip_Tolerance = 15;
our $Fill_Directory = "$ENV{'HOME'}/stills";
our $Music_Directory = "$ENV{'HOME'}/ogg/";

MAIN: {
  my ($date);

  while (1) {
    # Spawn off a child to do actual running
  my $pid;
  if (my $pid = fork) {
    wait;
  }
  else {

  my $offset = 0;

  GetOptions(
	     'start=s' => \$date,
	     'offset=f' => \$offset
	    )
    or die "Allowed options are: start offset\n";

  @ARGV or die "Usage: $0 [options] <schedule_name>\n";

  Log::Log4perl::init('/etc/playback_machine/playback_log.conf');

  my ($schedule_name) = @ARGV;

  my $table = Video::PlaybackMachine::ScheduleTable::DB->new(
							     schedule_name => $schedule_name,
							    );
  
  if (defined $date) {
    if ($date eq 'first' ) {
      $offset += $table->get_offset_to_first() - 1;
    }
    else {
      $offset += $table->get_offset($date);
    }
  }

  my $watcher = Video::PlaybackMachine::DatabaseWatcher->new(
							     dbh => $table->getDbh(),
							     table => 'content_schedule',
							     session => 'Scheduler',
							     event => 'update',
							    );
  my $watcher_session = $watcher->spawn();

  my $scheduler = Video::PlaybackMachine::Scheduler->new(
							 skip_tolerance => $Skip_Tolerance,
							 schedule_table => $table,
							 filler => get_fill($table),
							 offset => $offset,
							 watcher => $watcher_session
							);

  $scheduler->spawn();

  POE::Kernel->run();

}

}

}

sub get_fill {
  my ($table) = @_;

  # Leading ID
  my $id_producer = 
    Video::PlaybackMachine::FillProducer::StillFrame->new(
							  image => '/home/steven/other_stills/bctv-id.png',
							  time => 6
							 );

  my $leading_id = 
    Video::PlaybackMachine::FillSegment->new(
					     name => 'Station ID',
					     sequence_order => 1,
					     priority_order => 2,
					     producer => $id_producer
					    );
  
  # Random fill frame producer
  my $rand_producer = Video::PlaybackMachine::FillProducer::SlideShow->new(
										  directory => $Fill_Directory,
  music_directory => $Music_Directory,
										  time => 10,
										 );

  # "Up Next" announcement
  my $upnext_producer = 
    Video::PlaybackMachine::FillProducer::UpNext->new(
						      time => 6,
						     );
  my $upnext_segment = 
    Video::PlaybackMachine::FillSegment->new(
					     name => 'Up Next',
					     sequence_order => 3,
					     priority_order => 1,
					     producer => $upnext_producer
					    );

  # Next 5 programs
  my $nextsched_producer =
    Video::PlaybackMachine::FillProducer::NextSchedule->new(
							    time => 8,
							    font_size => 30,
							   );
  my $nextsched_segment =
    Video::PlaybackMachine::FillSegment->new(
					     name => 'Next Schedule',
					     sequence_order => 4,
					     priority_order => 3,
					     producer => $nextsched_producer
					    );

  # First batch of slides
  my $before_segment = Video::PlaybackMachine::FillSegment->new(
							 name => 'pre slideshow',
							 sequence_order => 2,
							 priority_order => 5,
							 producer => $rand_producer
							);
  
  

  # Short film segment
  my $short_producer = 
    Video::PlaybackMachine::FillProducer::FillShort->new($table);

  my $short_segment =
    Video::PlaybackMachine::FillSegment->new(
					     name => 'shorts',
					     sequence_order => 5,
					     priority_order => 3,
					     producer => $short_producer
					    );




  my $segment = Video::PlaybackMachine::FillSegment->new(
							 name => 'slideshow',
							 sequence_order => 5,
							 priority_order => 3,
							 producer => $rand_producer
							);
  my $filler = 
    Video::PlaybackMachine::Filler->new(segments => [$leading_id,
						     $before_segment,
						     $upnext_segment,
						     $short_segment, 
						     $nextsched_segment,
						     $segment,
						    ]
				       );
}

sub get_offset
{
	my (@date) = @_;
	@date or return 0;
	my $start_time = ParseDate(\@date)
		or do {
			warn "Start time ", @date, " does not contain a valid date-- ignored.\n";
			return 0;
		};
	my $start_time_seconds = UnixDate($start_time, '%s');
	return $start_time_seconds - time();
}
