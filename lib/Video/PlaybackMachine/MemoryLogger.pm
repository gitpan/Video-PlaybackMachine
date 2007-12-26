package Video::PlaybackMachine::MemoryLogger;

####
#### Video::PlaybackMachine::MemoryLogger
####
#### $Revision: 343 $
####
#### Logs memory consumed by the current process.
####

use strict;
use warnings;

use POE;
use POE::Session;
use Log::Log4perl;
use Proc::ProcessTable;

############################# Class Constants #############################

our $CHECK_INTERVAL = 30;

############################## Class Methods ##############################

##
## new()
##
##
sub new
{
	my $type = shift;
	my $self = {};
	$self->{'pt'} = Proc::ProcessTable->new();
	$self->{'logger'} = Log::Log4perl->get_logger('Video::PlaybackMachine::MemoryLogger');
	bless $self, $type;
}

############################# Object Methods ##############################

sub spawn
{
	my $self = shift;

	POE::Session->create( object_states => [ $self => [qw(_start update)] ] );
}

############################# Session Methods #############################

##
## _start()
##
## POE startup state.
##
## Called when the session begins.
sub _start
{
	$_[KERNEL]->yield('update');
}

##
## update()
##
## Checks memory and writes out the result to system log
##
sub update
{
	my ($kernel, $self) = @_[KERNEL, OBJECT];
	
	my $cp;
	foreach my $proc ( @{ $self->{'pt'}->table() } ) {
		if ($proc->pid() == $$) {
			$cp = $proc;
			last;
		}
	}
	
	$self->{'logger'}->debug("Memory for $$: " . $cp->rss() . " rss " . $cp->size() . " size");
	
	$kernel->delay('update', $CHECK_INTERVAL);
}

1;