package Video::PlaybackMachine::ScheduleTable::DB;

####
#### Video::PlaybackMachine::ScheduleTable::DB
####
#### This module is used to access the ScheduleTable.
####

use strict;
use DBI;
use Carp;
use Date::Manip;
use Log::Log4perl;

use Video::PlaybackMachine::Movie;
use Video::PlaybackMachine::AVFile;
use Video::PlaybackMachine::ScheduleEntry;
use Video::PlaybackMachine::Config;
use Video::PlaybackMachine::DB;

############################## Class Constants #####################################

our $Database_Name = Video::PlaybackMachine::Config->config->database();

############################## Class Methods #######################################

##
## new()
##
## Creates a new ScheduleTable::DB object.
##
sub new
{
  my $type = shift;
  my (%in) = @_;
  my $self = {
	      schedule_name => $in{'schedule_name'},
	      dbh           => undef,
	      logger        => Log::Log4perl->get_logger('Video.PlaybackMachine.DB'),
	     };
  bless $self, $type;
}

############################## Object Methods ######################################

sub getDbh { return Video::PlaybackMachine::DB->db(); }

##
## get_entries_after()
##
## Arguments:
##    TIME: scalar -- UNIX raw time
##    NUM_ENTRIES: int -- number of entries afterwards
##
## Returns all entries which start after a given time. In scalar context,
## returns the first entry after the given time. Returns undef if nothing left.
##
sub get_entries_after
{
  my $self = shift;
  my ($time, $num_entries) = @_;

  defined $num_entries
    or $num_entries = 1;

  # Get next content_schedule entry
  
  my $sth = $self->getDbh()->prepare(
q/
  	SELECT title, start_time
	FROM schedule_times_raw
	WHERE start_time > ? AND schedule = ?
        ORDER BY start_time
	LIMIT ?
 /
	  );
  $sth->execute(
		$time,
		$self->{'schedule_name'},
		$num_entries
	       )
    or $self->{'logger'}->logdie($DBI::errstr);
  
  my @entries = ();

  while (my ( $title, $start_time, $description ) = $sth->fetchrow_array()) {
    push(@entries, $self->_entry_for( $title, $start_time, $description ));
  }

  if (wantarray) {
    return @entries;
  }
  else {
    return $entries[0] if $num_entries == 1;
    return \@entries;
  }
}

##
## get_fill()
##
## Arguments:
##   TIME: int -- Max number of seconds (exclusive) for fill
##
## Returns a list of all shorts that are shorter than
## the amount of time we have left, randomly ordered.
##
# TODO A bit goofy to fetch duration, then do nothing with it?
sub get_fills {
  my $self = shift;
  my ($time) = @_;

    my $sth = $self->getDbh()->prepare(<<EOF);
       SELECT title, duration
       FROM fills
       WHERE duration < ?
       ORDER BY random()
EOF
  $sth->execute("$time seconds")
    	  or die $DBI::errstr;

  my @avfiles = ();
  my ($title, $duration);
  while ( ($title, $duration) = $sth->fetchrow_array() ) {
    push(@avfiles, $self->_avfiles_for($title));
  }
  return @avfiles;
}

##
## Returns the length of the shortest fillmovie.
##
sub get_min_fill {
  my $self = shift;

  my $sth = $self->getDbh()->prepare(<<EOF);
  SELECT min(date_part('epoch', avfile_duration(title)))
      FROM fill_shorts
EOF
      $sth->execute()
    	  or die $DBI::errstr;

  my ($min_time) = $sth->fetchrow_array()
      or return;

  return $min_time;
}

##
## Returns the length of the longest fillmovie.
##
sub get_max_fill {
  my $self = shift;

  my $sth = $self->getDbh()->prepare(<<EOF);
  SELECT max(date_part('epoch', avfile_duration(title)))
     FROM fill_shorts
EOF

  $sth->execute()
    or die $DBI::errstr;

  my ($max_time) = $sth->fetchrow_array()
    or return;

  return $max_time;

}

##
## Returns TIME formatted in a Postgres-readable
## timestamp format.
##
sub db_format_time {
  my $self = shift;
  my ($time) = @_;

  # Shim for time zone issue
  my $corr_time = $time;

  my $pd_time = ParseDateString("epoch $corr_time");
  return UnixDate($pd_time, '%m-%d-%Y %T');

}

##
## Returns the database's idea of the current schedule time.
##
sub db_schedule_time {
  my $self = shift;
  my ($offset) = @_;

  defined $offset or $offset = 0;

  my $sth = $self->getDbh()->prepare('select now() - interval ?');
  $sth->execute("$offset secs") or return;
  my ($formatted_sched_time) = $sth->fetchrow_array()
    or return;
  return $formatted_sched_time;

}

##
## Returns offset in seconds between the database's idea of time
## and TIME. Returns undef if the time wasn't readable.
##
sub get_offset {
  my $self = shift;
  my ($date) = @_;

  my $sth = $self->getDbh()->prepare('select EXTRACT(EPOCH FROM CURRENT_TIMESTAMP - TIMESTAMPTZ ?)');
  $sth->execute($date)
    or return;
  my ($offset) = $sth->fetchrow_array()
    or return;
  return $offset;
}

##
## Returns the offset to the first schedule entry.
##
sub get_offset_to_first {
  my $self = shift;

  my $sth = $self->getDbh()->prepare('SELECT EXTRACT( EPOCH from CURRENT_TIMESTAMP - start_time ) FROM schedule_times ORDER BY start_time LIMIT 1');
  $sth->execute()
    or return;
  my ($offset) = $sth->fetchrow_array()
    or return;
  return $offset;
}

##
## Returns a list of av files for a given title.
##
sub _avfiles_for {
  my $self = shift;
  my ($title) = @_;
  
  # Get file entries for next content_schedule entry
  my $sth = $self->getDbh()->prepare(<<EOF);
SELECT
    file,
    date_part('epoch', duration) 
 FROM av_file_component
 WHERE title = ? ORDER BY sequence_no
EOF
  $sth->execute($title);
  my @av_files = ();
  while ( my ( $file, $duration ) = $sth->fetchrow_array() ) {
      push(
	   @av_files,
	   Video::PlaybackMachine::AVFile->new( $file, $duration ) 
	  );
    }

  return @av_files;
}

sub _entry_for {
  my $self = shift;
  my ( $title, $start_time, $description ) = @_;
  
  my @av_files = $self->_avfiles_for($title);
  
  # Create the schedule entry
  my $movie = Video::PlaybackMachine::Movie->new(
						 title       => $title,
						 description => $description,
						 av_files    => \@av_files
						);

  return Video::PlaybackMachine::ScheduleEntry->new( int($start_time), $movie );
}

##
## get_entry_during()
##
## Arguments:
##    TIME: scalar -- UNIX raw time
##
## Returns the schedule entry in which TIME takes place.
## Returns an empty list / undef if there is no scheduled program taking place
## at the given time.
##
sub get_entry_during
{
	my $self = shift;
	my ($time) = @_;

	  # Get next content_schedule entry
	  my $sth = $self->getDbh()->prepare(
		qq{
  	SELECT title, start_time, description
	FROM schedule_times_raw
	WHERE ? BETWEEN start_time AND stop_time
	AND schedule = ?
	LIMIT 1
  }
	  );
	$sth->execute($time, $self->{'schedule_name'});

	my ( $title, $start_time, $description ) = $sth->fetchrow_array()
	  or return;
	  
	 return $self->_entry_for($title, $start_time, $description); 

}

sub get_schedule_name {
  return $_[0]->{'schedule_name'};
}

sub finished {
  my $self = shift;
  $self->{'logger'}->debug('Disconnecting from database');
  $self->getDbh()->disconnect();
}

1;
