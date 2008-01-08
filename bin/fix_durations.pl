#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Time::Duration;

use FindBin '$Bin';
use lib "$Bin/../lib";

use Video::PlaybackMachine::ContentManager qw(fix_lengths);

MAIN: {
    fix_lengths();
}
