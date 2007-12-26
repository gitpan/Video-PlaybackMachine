package Video::PlaybackMachine::Config;

use strict;
use warnings;
use diagnostics;



=pod

=head1 NAME

Video::PlaybackMachine::Config

=head1 DESCRIPTION

Provides configuration values for Video::PlaybackMachine. This manual describes the configuration values available.

=head1 

=cut

use AppConfig qw(:expand :argcount);
our @ISA = qw(AppConfig);

use FindBin '$Bin';

use Log::Log4perl;

our @Config_Files = (
	"$Bin/../conf/playback_machine.conf",
	"/etc/playback_machine/playback_machine.conf"
);

BEGIN {

	my $config;

	sub config {
		my $type = shift;
		defined $config and return $config;

		$config = $type->new( GLOBAL => { EXPAND => EXPAND_ALL } );

		$config->define(
			'database',
			{
				DEFAULT => 'playback_machine',
				ARGS    => '=s'
			}
		);

		$config->define( 'schedule', { ARGS => '=s' } );

		$config->define( 'stills', { ARGS => '=s' } );

		$config->define( 'music', { ARGS => '=s' } );

		$config->define( 'fill', { ARGS => '=s@' } );
		
		$config->define( 'restart_interval', { ARGS => '=i', DEFAULT => 3 * 60 * 60 } );

		$config->define('logo=s');

		$config->define('start=s');

		$config->define(
			'offset',
			{
				ARGS    => '=i',
				DEFAULT => 0
			}
		);

		$config->define(
			'skip_tolerance',
			{
				ARGS    => '=i',
				DEFAULT => 15
			}
		);

		$config->define( 'max_slides=i', { DEFAULT => 5 } );

		$config->define( 'player_backend_class=s',
			{ DEFAULT => 'XineBackEnd' } );
			
		$config->define( 'player_verbose=i', { DEFAULT => 0 } );
		
		$config->define( 'stderr_log=s' );

		$config->define( 'log_config_file=s' );

		foreach my $config_file (@Config_Files) {
			-e $config_file or next;
			$config->file($config_file)
			  or die "Couldn't load config file '@Config_Files': $!; stopped";
		}
		
		$config->define( 'x_display=s', { DEFAULT => ':0.0' } );

		$config->getopt();

		return $config;
	}

}

BEGIN {

	my $backend;

	sub get_player_backend {
		my $self         = shift;
		my $backend_name = $self->player_backend_class();
		my $class = "Video::PlaybackMachine::PlayerBackEnd::$backend_name";
		eval "require $class";
		if ( length($@) ) {
			die "Unable to load backend '$backend_name': $!; stopped";
		}
		return $class->new( name => '$backend_name' );

	}

}

sub init_logging {
  my $type = shift;

  my $config = $type->config();

  Log::Log4perl::init_once( $config->log_config_file() );

}

sub _producer_table {
	my $self = shift;
	my ($table) = @_;

	return +{
		station_id => Video::PlaybackMachine::FillProducer::StillFrame->new(
			image => $self->logo(),
			time  => 6
		),

		slideshow => Video::PlaybackMachine::FillProducer::SlideShow->new(
			directory       => $self->get('stills'),
			music_directory => $self->get('music'),
			time            => 10,
		),

		up_next =>
		  Video::PlaybackMachine::FillProducer::UpNext->new( time => 6, ),

		# Next 5 programs
		next_sched => Video::PlaybackMachine::FillProducer::NextSchedule->new(
			time      => 8,
			font_size => 30,
		),

		# Short film segment
		shorts => Video::PlaybackMachine::FillProducer::FillShort->new($table)

	};

}

sub get_fill {
	my $self = shift;
	my ($table) = @_;

	my $pt = $self->_producer_table($table);

	my @fill_segs = ();
	my $order_idx = 1;
	foreach ( @{ $self->fill() } ) {
		my ( $name, $priority ) = split( /\t+/, $_, 2 );
		my $producer = $pt->{$name};
		unless ( defined $producer ) {
			my $logger =
			  Log::Log4perl->get_logger('Video.PlaybackMachine.Config');
			$logger->warn("No fill producer found named '$name'");
			next;
		}
		my $segment = Video::PlaybackMachine::FillSegment->new(
			name           => $name,
			sequence_order => $order_idx++,
			priority_order => $priority,
			producer       => $producer
		);
		push( @fill_segs, $segment );

	}

	my $filler = Video::PlaybackMachine::Filler->new( segments => \@fill_segs );

	return $filler;
}

1;
