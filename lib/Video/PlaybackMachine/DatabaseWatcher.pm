package Video::PlaybackMachine::DatabaseWatcher;

##
## Video::PlaybackMachine::DatabaseWatcher
##
## $Revision: 243 $
##
## Signals the Scheduler when the database has been updated.
##

use strict;
use warnings;
use diagnostics;


use IO::Handle;

use Log::Log4perl;

use POE;
use POE::Session;
use POE::Kernel;

######################## Class Constants ########################


######################## Class Methods ##########################

##
## new()
##
## Arguments: (hash)
##   dbh => DBI handle (DBD::Pg connection)
## 
sub new {
	my $type = shift;
	my %in = @_;
	my $self = {
		    dbh => $in{'dbh'},
		    table_name => $in{'table'},
		    session => $in{'session'},
		    event => $in{'event'},
		    logger => Log::Log4perl->get_logger('Video::PlaybackMachine::DatabaseWatcher')
		   };
	bless $self, $type;
}

###################### Session Methods ##########################

sub _start {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];

  # Watch for incoming messages from the database
  $self->{'dbh'}->do("LISTEN $self->{'table_name'}");
  my $fd = $self->{'dbh'}->func('getfd');
  my $fh = IO::Handle->new();
  $fh->fdopen($fd, 'r')
    or $self->{logger}->logdie("Couldn't open file descriptor '$fd': $!");
  $kernel->select_read($fh, 'changed');
  $heap->{'fh'} = $fh;
  $self->{'logger'}->debug("Watching table $self->{'table_name'}");
}

sub shutdown {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  my $fh = $heap->{'fh'} or return;
  $self->{'logger'}->debug("End watching table $self->{'table_name'}");
  $kernel->select_read($fh);
  delete $heap->{'fh'};
}

sub changed {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];

  $self->{'logger'}->debug("Caught change");
  
  my $ret = $self->{'dbh'}->func('pg_notifies')
    or return;
  $self->{'logger'}->debug("Caught change for table $ret");
  $ret->[0] eq $self->{'table_name'} or return;
  $kernel->post($self->{'session'},
  				$self->{'event'});
  
}


###################### Object Methods ###########################

sub spawn {
  my $self = shift;

  POE::Session->create(
		       object_states => [
					 $self => [ qw(_start changed shutdown) ]
					]
		      );
}


1;
