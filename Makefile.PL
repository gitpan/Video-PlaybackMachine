
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Perl extension for creating a television station",
  "AUTHOR" => "Stephen Nelson <stephenenelson\@mac.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Video-PlaybackMachine",
  "EXE_FILES" => [
    "bin/add_fill.pl",
    "bin/add_movie.pl",
    "bin/check_titles.pl",
    "bin/fix_durations.pl",
    "bin/playback_machine.pl",
    "bin/show_missing.pl"
  ],
  "LICENSE" => "perl",
  "NAME" => "Video::PlaybackMachine",
  "PREREQ_PM" => {
    "AppConfig" => 0,
    "DBD::Pg" => 0,
    "DBI" => 0,
    "Date::Manip" => 0,
    "Image::Imlib2" => 0,
    "Log::Log4perl" => 0,
    "POE" => 0,
    "Test::MockObject" => 0,
    "Time::Duration" => 0,
    "Video::Xine" => "0.14",
    "X11::FullScreen" => 0
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "0.07",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



