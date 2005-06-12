#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Getopt::Long;

use Log::Log4perl;


use Video::PlaybackMachine::Config;
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


our $config = Video::PlaybackMachine::Config->config();

our $Skip_Tolerance = $config->skip_tolerance();

MAIN: {
  my ($date);

  while (1) {
    # Spawn off a child to do actual running
  my $pid;
  if (my $pid = fork) {
    sleep 5;
    wait;
  }
  else {

  my $offset = $config->offset();
  $date = $config->start();

  Log::Log4perl::init('/etc/playback_machine/playback_log.conf');

  my $schedule_name = $config->schedule();

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
							 filler => $config->get_fill($table),
							 offset => $offset,
							 watcher => $watcher_session
							);

  $scheduler->spawn();

  POE::Kernel->run();

}

}

}

