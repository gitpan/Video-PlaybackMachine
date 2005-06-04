# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use lib qw(lib t/lib);

use strict;
use warnings;

use Test::More tests => 6;
BEGIN { use_ok('Video::PlaybackMachine::MockScheduleTable') };


use Video::PlaybackMachine::MockScheduleTable qw(mock_schedule_table);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $now = time();

my $mock = mock_schedule_table($now);

is($mock->get_entries_after($now+19)->get_start_time(), $now + 20);

is($mock->get_entries_after($now+22)->get_start_time(), $now + 25);

is($mock->get_entries_after($now+58)->get_start_time(), $now +  65);

is($mock->get_entry_during($now+5)->get_start_time(), $now, "entry_during() time check");

is($mock->get_entry_during($now+39), undef);

