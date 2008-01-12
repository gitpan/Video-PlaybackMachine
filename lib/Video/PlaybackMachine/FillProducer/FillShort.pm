package Video::PlaybackMachine::FillProducer::FillShort;

####
#### Video::PlaybackMachine::FillProducer::FillShort
####
#### $Revision: 693 $
####

# TODO: extract DB code from ScheduleTable::DB
#
# TODO: Split fill producers from fill displayers (?)

use strict;
use warnings;
use Carp;
use POE;
use POSIX 'INT_MAX';

use base qw(
  Video::PlaybackMachine::FillProducer
  Video::PlaybackMachine::TimeLayout
);

use Video::PlaybackMachine::TimeLayout::FixedTimeLayout;
use Video::PlaybackMachine::AVFile;

########################### Class Constants #######################

############################ Class Methods ########################

sub new {
    my $type = shift;
    my ($st) = @_;
    my $self = {
        st   => $st,
        seen => {}
    };
    bless $self, $type;

}

sub get_time_layout {
    return $_[0];
}

sub start {
    my $self = shift;
    my ($time) = @_;

    my @fills = $self->{'st'}->get_fills($time)
      or return;
    foreach my $avfile (@fills) {
        my $file = $avfile->get_file();
        $self->{seen}{$file}++ and next;
        $poe_kernel->yield( 'short_ready', $file );
        return 1;
    }
    $self->{'seen'} = {};
    $self->start($time);
}

sub min_time {
    my $self = shift;

    unless ( defined $self->{'min_time'} ) {

        defined( $self->{'min_time'} = $self->{'st'}->get_min_fill() )
          or return INT_MAX;

    }

    return $self->{'min_time'};
}

sub preferred_time {
    my $self = shift;

    unless ( defined $self->{'preferred_time'} ) {
        defined( $self->{'preferred_time'} = $self->{'st'}->get_max_fill() )
          or return INT_MAX;
    }

    return $self->{'preferred_time'};
}

sub is_available {
    my $self = shift;

    return defined( $self->{'st'}->get_max_fill() );
}

sub get_next {
    return $_[1] + 1;

}

1;

__END__

=head1 NAME

Video::PlaybackMachine::FillProducer::FillShort -- Plays a randomly-chosen short from the fill contents database that fits into the time available.

=head1 DESCRIPTION

Plays a randomly-chosen short from the fill contents database that
fits into the time available.

In a slightly scurvy trick, FillShort also defines its own time
layout, which allows it to query the database whenever someone asks
it.

=head1 METHODS

=head2 Class Methods

=head3 new()

Arguments:

   TABLE -- ScheduleTable::DB

Creates a new FillShort which uses the DBI connection given.

=head3 get_time_layout()

Returns:

   Video::PlaybackMachine::FillShort

In a scurvy trick, we're our own time layout object. That way, the
time layout can query the database for minimum and preferred times.


=head3 start()

Arguments:

  TIME: int -- time in seconds that we're to fill

=head3 min_time()

Returns the minimum amount of time this filler can run, i.e. the
shortest short. Caches its values to minimize database calls.

If there is no filler at all, returns C<INT_MAX>.


=head3 preferred_time()

Returns the length of the longest fillmovie. (Sorry, it just got
too strange referring to the "longest short.") Possibly this
behavior is a bug in the architecture, but it's the only sane
deterministic value. Better behavior would be to return the length
of the movie which we will play next, but there's a random factor
there.


=head3 is_available()

Returns true if there are shorts available to play.


=head3 get_next()

Returns the sequence number of the next short to play

=cut

