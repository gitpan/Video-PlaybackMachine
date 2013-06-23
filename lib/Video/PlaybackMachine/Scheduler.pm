package Video::PlaybackMachine::Scheduler;

####
#### Video::PlaybackMachine::Scheduler
####
#### $Revision$
####
#### Plays movies in the ScheduleTable at the appropriate times.
####

use strict;
use warnings;

use POE;
use POE::Session;
use Log::Log4perl;
use Date::Manip;
use POSIX 'INT_MAX';

use Video::PlaybackMachine::Player qw(PLAYER_STATUS_PLAY);
use Video::PlaybackMachine::ScheduleView;
use Video::PlaybackMachine::Config;

use Time::Duration;

use Carp;

############################# Class Constants #############################

use constant DEFAULT_SKIP_TOLERANCE => 30;

use constant DEFAULT_IDLE_TOLERANCE => 15;

our $Minimum_Fill = 7;


## Modes of operation

# Starting up, haven't played anything yet
use constant START_MODE => 0;

# Idle mode -- dead air
use constant IDLE_MODE => 1;

# Between scheduled content
use constant FILL_MODE => 2;

# Playing scheduled content
use constant PLAY_MODE => 3;


############################## Class Methods ##############################


##
## new()
##
## Arguments: (hash)
##  schedule_table => Video::Playback::ScheduleTable
##  offset => integer: seconds
##  player => Video::PlaybackMachine::Player (optional)
##  filler => Video::PlaybackMachine::Filler (optional)
##  skip_tolerance => integer: seconds (optional)
##  terminate_on_finish => boolean (default: true)
##  run_forever => boolean (default: false)
##
sub new {
  my $type = shift;
  my %in = @_;

  defined $in{schedule_table} or croak "Argument 'schedule_table' required; stopped";
  defined $in{skip_tolerance} or $in{skip_tolerance} = DEFAULT_SKIP_TOLERANCE;
  defined $in{'terminate_on_finish'} or $in{'terminate_on_finish'} = 1;
  defined $in{'run_forever'} or $in{'run_forever'} = 0;


  my $self = {
	      terminate_on_finish => $in{'terminate_on_finish'},
	      run_forever => $in{'run_forever'},
	      skip_tolerance => $in{skip_tolerance},
	      schedule_table => $in{schedule_table},
	      player => $in{player} || Video::PlaybackMachine::Player->new(),
	      filler => $in{filler} || Video::PlaybackMachine::Filler->new(),
	      waitlist => [],
	      mode => START_MODE,
	      offset => $in{offset},
	      minimum_fill => $Minimum_Fill,
	      schedule_view => Video::PlaybackMachine::ScheduleView->new($in{schedule_table}, $in{offset}),
	      watcher_session => $in{watcher},
	      logger => Log::Log4perl->get_logger('Video::Playback::Scheduler'),
	     };

  $self->{'logger'}->info("$0 started");

  bless $self, $type;
}

############################# Object Methods ##############################

sub spawn {
  my $self = shift;

  POE::Session->create(

		       object_states => [ 
					 $self => [qw(_start time_tick finished update play_scheduled warning_scheduled schedule_next shutdown wait_for_scheduled query_next_scheduled)]
					],
		       );
}

##
## get_mode()
##
## Returns:
##
##   integer -- START_MODE, FILL_MODE, or PLAY_MODE.
##
sub get_mode {
  return $_[0]->{'mode'};
}

##
## should_be_playing()
##
## Returns:
##
##   Video::PlaybackMachine::ScheduleEntry
##
## Returns the movie, if any, which should be playing right
## now.
##
## Enforces our playback policies.
##
## If we're just starting up, and something is scheduled to be played
## right now, we'll play it no matter how far along we're supposed to
## be. That way we can restart in the middle of a movie and not miss the
## whole thing.
##
## Otherwise, it returns a movie if there's one scheduled for right
## now and playing it would not make us miss an unacceptably long part
## of the movie.
##
sub should_be_playing {
  my $self = shift;
  my $schedule_now = $self->real_to_schedule(@_);

  my $current = $self->{schedule_view}->get_schedule_table()->get_entry_during($schedule_now);

  # If there's no entry to play right now, return nothing
  defined($current) or return;

   if ($self->get_mode() == START_MODE) {

    # Return the movie listing
    return $current;

  } # End if we're in startup mode

  # Else we're not in startup mode
  else {

    # Return the movie if it's not too far along
    if ($self->get_seek($current) < $self->{skip_tolerance} ) {
      return $current;
    }
    # TODO make sure that there's no edge condition
    else {
      return;
    }

  } # End else not in startup mode

}

sub get_seek {
  my $self = shift;
  return $self->{schedule_view}->get_seek(@_);
}


sub get_next_entry {
  my $self = shift;
  return $self->{schedule_view}->get_next_entry(@_);
}

sub get_time_to_next {
  my $self = shift;
  my $schedule_to_next = $self->{schedule_view}->get_time_to_next(@_);
  if ( (! defined($schedule_to_next) ) && $self->{'run_forever'} ) {
    return INT_MAX;
  }
  else {
    return $schedule_to_next;
  }
}

sub schedule_to_real {
  my $self = shift;
  return $self->{'schedule_view'}->schedule_to_real(@_);
}

sub real_to_schedule {
  my $self = shift;
  return $self->{'schedule_view'}->real_to_schedule(@_);
}


##
## Returns the amount of time required to skip to play
## the given movie before the next scheduled entry.
##
sub time_skip {
  my $self = shift;
  my $movie = shift;
  my $time = $self->real_to_schedule(@_);

  my $diff = $self->get_time_to_next(@_);

  if ($movie->get_length() > $diff) {
    return $movie->get_length() - $diff;
  }
  else {
    return 0;
  }

}

############################# Session Methods #############################


##
## _start()
##
## POE startup state.
##
## Called when the session begins. Spawns off a player and filler session
## so that they can do whatever prep work they need to do, identifies
## this session as a scheduler, and checks the database for things
## that should be played.
##
sub _start {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];

  # Hang out a shingle
  $kernel->alias_set('Scheduler');

  # Set up our Player and our Filler
  $heap->{player_session} = $self->{player}->spawn();
  $heap->{filler_session} = $self->{filler}->spawn();

  # Start the time ticker
  $kernel->delay('time_tick', Video::PlaybackMachine::Config->config()->time_tick() );

  # Check the database for things that need playing
  $kernel->yield('update');

}

##
## time_tick()
##
## Updates the process table entry with the current time (according to the schedule)
##
sub time_tick
{
	my $time = $_[OBJECT]->real_to_schedule(time());
	$0 = "playback_machine: " . scalar localtime($time) . "($time)";
	$_[KERNEL]->delay('time_tick', Video::PlaybackMachine::Config->config()->time_tick());
}

##
## query_next_scheduled()
##
## Designed to be called and return the next item on the schedule.
## Although this is a POE event handler, it's useful only when called
## with the call() command.
##
sub query_next_scheduled {
  return $_[OBJECT]->get_next_entry(undef,$_[ARG0]);
}

##
## update()
##
## POE state.
##
## Called whenever there's a change to the schedule
## and we need to make sure that the Scheduler's state
## matches what's in the database. Does NOT interrupt
## a running movie.
##
sub update {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];

  # Clear all schedule alarms
  $kernel->alarm_set('play_scheduled');
  $kernel->alarm_set('warning_scheduled');

  # If we're not playing
  if ($self->get_mode() != PLAY_MODE) {

    # If there's something supposed to be playing
    if ( my $entry = $self->should_be_playing() ) {

      $self->{'logger'}->debug("Time to play $entry");

      # Play it
      $kernel->yield('play_scheduled', $entry->get_listing(), $self->get_seek($entry));
      return;

    } # End if supposed to be playing

    # Otherwise, fill gap until next scheduled item
    else {
      $kernel->yield('wait_for_scheduled');
    }

  } # End if we're not playing

  # Set alarm to play next scheduled item
  $kernel->delay('schedule_next', 5);
}


##
## finished()
##
## POE state.
##
## Called whenever playback is finished. It checks to see if there is anything
## waiting for immediate play (i.e. was double-scheduled earlier) and plays it.
## Otherwise, sends us to fill mode.
##
## Until we enter fill or play mode, this method puts us into idle mode.
##
sub finished {
  my ($self, $kernel, $request, $response) = @_[OBJECT, KERNEL, ARG0, ARG1];

  my $now = time();

  # If we've been running longer than the restart interval, restart the system
  my $config = Video::PlaybackMachine::Config->config();
  if ($config->restart_interval() > 0) {
  	if ( ($now - $^T) > $config->restart_interval() ) {
    		$self->{'logger'}->info("Shutting down for restart");
    		exit(0);
  	}
  }

  # We're in idle mode now
  $self->{mode} = IDLE_MODE;

  # Log the item that finished playing
  $kernel->post('Logger', 'log_played_movie', $request->[0], $request->[1], time(), $response->[0]);

  # If there's something waiting to be played
  my $waiting_movie;
  if ( $waiting_movie = shift @{ $self->{waitlist} } ) {

    # If there's time enough to play it
    if ( $self->time_skip( $waiting_movie, $now ) <= $self->{skip_tolerance} ) {

      # Play it, skipping as necessary
      $kernel->yield('play_scheduled', $waiting_movie, $self->time_skip( $waiting_movie ) );

    } # End if time enough

    # Otherwise we didn't have time to play it
    else {

      # Log that we had to skip something
      $kernel->post('Logger', 'log_skipped_movie', $waiting_movie);

      # Schedule the next movie
      $kernel->yield('schedule_next');

      # Wait for the next movie
      $kernel->yield('wait_for_scheduled');

    } # End no time

  }# End if something waiting

  # Otherwise, nothing scheduled to play right now
  else {

    # If there's something else scheduled
    if ( defined $self->get_next_entry($now) ) {

      # If there's enough time to start filling
      if ( $self->get_time_to_next($now) > $self->{minimum_fill} ) {

	# Fill until next scheduled entry
	$kernel->yield('wait_for_scheduled');

      } # End if enough time

      # Otherwise, go into idle mode till next
      else {

	$self->{'logger'}->debug("Not filling: " . $self->get_time_to_next($now) . " too short for fill (minimum $self->{'minimum_fill'})\n");

	$self->{mode} = IDLE_MODE;

      }

    } # End if something else scheduled

    # Otherwise, nothing scheduled; shut down.
    else {

      $kernel->yield('shutdown');

    }

  } # End nothing right now

}

sub warning_scheduled {
  my ($self, $kernel) = @_[OBJECT, KERNEL];

  # If we're in fill mode
  if ( $self->get_mode() == FILL_MODE ) {

    # Send a warning message to the Filler
    $kernel->post('Filler', 'warning', $self->get_time_to_next());

  } # End if we're in fill mode

  # Otherwise, do nothing; we do not interrupt scheduled content.

}

sub play_scheduled {
  my ($self, $kernel, $movie, $seek) = @_[OBJECT, KERNEL, ARG0, ARG1];

  # If we're playing something scheduled
  if ( ( $self->get_mode() == PLAY_MODE ) && ($self->{player}->get_status() == PLAYER_STATUS_PLAY) ) {

    # Add the currently-scheduled item to the waiting list
    # This discards any existing $seek
    push(@{ $self->{waitlist} }, $movie);

    return;

  } # End if we're playing something scheduled

  # Otherwise, we're ready to play
  else {

    # Tell the Filler to stop filling
    $kernel->post('Filler', 'stop');

    # Mark that we're in play mode now
    $self->{'mode'} = PLAY_MODE;

    # Start playing the movie
    $movie->play($seek);

    # Schedule the next item from the schedule table
    $kernel->delay('schedule_next', 3);

  } # End otherwise


}

sub wait_for_scheduled {
  my ($self, $kernel) = @_[OBJECT, KERNEL];

  defined $self->get_time_to_next()
    or $self->{'logger'}->logdie("Called wait_for_scheduled with nothing to wait for; schedule time is " . scalar localtime($self->real_to_schedule()) );

  # If there's enough time before the next item to bother with fill
  if ( $self->get_time_to_next() > $self->{minimum_fill} ) {

    # Mark that we're in Fill mode
    $self->{mode} = FILL_MODE;

    # Tell our Filler to get to work
    $kernel->post('Filler', 'start_fill', $self->{schedule_view});

  } # End if enough time

  # Else not enough time
  else {

    # Go to Idle mode
    $self->{mode} = IDLE_MODE;

  }

}

sub schedule_next {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];

  # If there's something left in the schedule
  if ( my $entry = $self->get_next_entry() ) {

     # Set an alarm to play it
    my $alarm_offset = $self->{'schedule_view'}->schedule_to_real($entry->get_start_time());
    my $in_time = $alarm_offset - time();

    ($in_time >= 0) 
      or $self->{'logger'}->logdie("Attempt to schedule '", $entry->get_title(), "' in the past ($in_time) at ", scalar  localtime $alarm_offset);

    $self->{'logger'}->info("scheduling: ", $entry->get_title(), " at ", scalar localtime($alarm_offset), " in ", duration($in_time));
    $kernel->alarm( 'play_scheduled', $alarm_offset, $entry->get_listing(), 0 );

  } # End if there's something left

}

sub shutdown {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];

  # If we're supposed to quit
  if ($self->{terminate_on_finish}) {

    # Pull in the shingle
    $kernel->alias_remove('Scheduler');

    # Terminate Watcher if defined
    $kernel->post($self->{'watcher_session'}, 'shutdown');

    # Terminate Player and Filler
    $kernel->post($heap->{player_session}, 'shutdown');
    $kernel->post($heap->{filler_session}, 'shutdown');

    # Stop watching for 'finished' events
    $kernel->state('finished');

    delete $heap->{$_} foreach keys %$heap;

    $kernel->alarm_remove_all();

    return;


  } # End if we're supposed to quit

  # Otherwise we're supposed to put up a standby screen
  else {

    # Put up the standby screen
    warn "Putting up standby screen unimplemented...";

  } # End otherwise

}


1;
