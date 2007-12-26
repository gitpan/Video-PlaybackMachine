# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################


# TODO: Only gives 3 OKs, which might be OK because it won't go into wait mode if there's nothing scheduled after.

use Test::More tests => 3;
BEGIN { use_ok('Video::PlaybackMachine::Filler') };

use strict;

use lib qw(t/lib lib);

use Test::MockObject;

use Video::PlaybackMachine::MockScheduleTable;
use Video::PlaybackMachine::FillSegment;
use Video::PlaybackMachine::ScheduleView;
use Video::PlaybackMachine::TimeLayout::FixedTimeLayout;
use POE;
use POE::Session;

#########################

# Initialize the log file
my $conf = q(
log4perl.logger.Video		= ERROR, Screen1
log4perl.appender.Screen1	= Log::Log4perl::Appender::Screen
log4perl.appender.Screen1.layout = Log::Log4perl::Layout::SimpleLayout
);
Log::Log4perl::init(\$conf);


# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

MAIN: {
  my $now = time();

  # Create a couple of segments with mock producers
  my $two_seg = make_segment(2, 0, 1);
  my $seven_seg = make_segment(7, 1, 0);

  # Spawn the Filler with appropriate segments
  my $filler = Video::PlaybackMachine::Filler->new( segments => [ $two_seg, $seven_seg] );
  $filler->spawn();

  my $view = make_view($now);

  # Spin up a mock session to check on play_still calls
  # Here it's playing both Player and Scheduler
  POE::Session->create(
		       inline_states => {
					 _start => sub {
					   $two_seg->get_producer()->clear();
					   $seven_seg->get_producer()->clear();

					   $_[KERNEL]->alias_set('Player');
					   $_[KERNEL]->alias_set('Scheduler');
					   $_[KERNEL]->post('Filler', 'start_fill', $view);
					   $_[KERNEL]->delay('check', 1);
					 },
					 check => sub {
					   ok( $two_seg->get_producer()->called('start'), 'Two start' );
					   ok( ! $seven_seg->get_producer()->called('start'), 'Seven start' );
					   $_[KERNEL]->post('Filler', 'still_ready', 'test', 2);
					 },
					 play_still => sub {
					   is($_[ARG0], 'test', 'play_still arg');
					   ok_time($now + 1, 'play_still');
					 },
					 wait_for_scheduled => sub {
					   ok_time($now+3, 'wait_for_scheduled');
					 }
					}
		       );

  POE::Kernel->run();

}

sub ok_time {
  my ($exp_time, $name) = @_;

  my $time_diff = abs(time() - $exp_time);

  ok($time_diff < 2, "$name call: $time_diff");

}

sub make_view {
  my ($now) = @_;
  # Create a ScheduleView with some programming starting in 5 seconds
  my $sched_table = Video::PlaybackMachine::MockScheduleTable->new($now);
  $sched_table->add(5, 5, 1);
  my $sched_view = Video::PlaybackMachine::ScheduleView->new($sched_table, 0);
  return $sched_view;
}

sub make_segment {
  my ($seconds, $order, $priority) = @_;

  my $producer = Test::MockObject->new();
  $producer->set_true('start');
  $producer->set_true('is_available');
  $producer->mock('get_next', sub { $_[0] + 1 });
  $producer->set_always('get_time_layout',
			Video::PlaybackMachine::TimeLayout::FixedTimeLayout->new($seconds));
  return Video::PlaybackMachine::FillSegment->new(
						  name => "$seconds seconds",
						  sequence_order => $order,
						  priority_order => $priority,
						  producer => $producer
						  );

}
