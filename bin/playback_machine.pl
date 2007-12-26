#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Getopt::Long;

use Log::Log4perl;

use FindBin '$Bin';
use lib "$Bin/../lib";

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
	
	my $start_time = time();

	while (1) {
	
		# Spawn off a child to do actual running
		my $pid;
		if ( my $pid = fork ) {
			sleep 5;
			wait;
		}
		else {
			
			open(STDERR, '>>' . $config->stderr_log())
				or die "Couldn't open '" . $config->stderr_log() ."' for STDERR log: $!; stopped";

			Log::Log4perl::init(
				$config->log_config_file()
			);


			my $schedule_name = $config->schedule();

			my $table =
			  Video::PlaybackMachine::ScheduleTable::DB->new(
				schedule_name => $schedule_name, );

			my $offset = 0;
			$date = $config->start();

			if ( $config->offset() > 0 || defined($date) ) {
				$offset = $config->offset() - ( time() - $start_time );				

				if ( defined($date) ) {
					if ( $date eq 'first' ) {
						$offset += $table->get_offset_to_first() + 1;
					}
					else {
						$offset += $table->get_offset($date);
					}
				}
			
			}
			
			my $watcher = Video::PlaybackMachine::DatabaseWatcher->new(
				dbh     => $table->getDbh(),
				table   => 'content_schedule',
				session => 'Scheduler',
				event   => 'update',
			);
			
			my $watcher_session = $watcher->spawn();

			my $scheduler = Video::PlaybackMachine::Scheduler->new(
				skip_tolerance => $Skip_Tolerance,
				schedule_table => $table,
				filler         => $config->get_fill($table),
				offset         => $offset,
				watcher        => $watcher_session
			);

			$scheduler->spawn();

			POE::Kernel->run();

		}

	}

}

