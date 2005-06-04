use strict;

use Video::PlaybackMachine::ContentManager qw(get_missing);

MAIN: {
  my @missing = get_missing()
    or do {
      print "OK\n";
      exit(0);
      };

  foreach my $missed (@missing) {
    my ($title, $file) = @$missed;
    print STDERR "Title '$title' is missing file '$file'\n";
  }
  exit(1);
}
