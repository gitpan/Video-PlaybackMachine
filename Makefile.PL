use 5.008;
use ExtUtils::MakeMaker;
WriteMakefile
  (
   NAME		=> 'Video::PlaybackMachine',
   VERSION_FROM	=> 'lib/Video/PlaybackMachine.pm',
   PREREQ_PM		=> {
			    'POE' => 0,
			    'Time::Duration' => 0,
			    'Test::MockObject' => 0,
			    'Video::Xine' => 0,
			    'X11::FullScreen' => 0,
			    'Image::Imlib2' => 0,
			    'Log::Log4perl' => 0,
			    'AppConfig' => 0
			   },
   EXE_FILES => [ 'bin/playback_machine.pl',
		  'bin/add_fill.pl',
		  'bin/add_movie.pl'
		],
   ABSTRACT_FROM => 'lib/Video/PlaybackMachine.pm',
   AUTHOR     => 'Stephen Nelson <stephen@cpan.org>'
  );
