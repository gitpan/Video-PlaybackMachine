use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Video::PlaybackMachine',
    'VERSION_FROM'	=> 'lib/Video/PlaybackMachine.pm', # finds $VERSION
    'PREREQ_PM'		=> {
			    'POE' => 0,
			    'Time::Duration' => 0,
			    'Test::MockObject' => 0,
			    'Video::Xine' => 0,
			    'X11::FullScreen' => 0,
			    'Image::Imlib2' => 0,
			    'Log::Log4perl' => 0,
			    'AppConfig' => 0
			   }, # e.g., Module::Name => 1.1
    'ABSTRACT_FROM' => 'lib/Video/PlaybackMachine.pm', # retrieve abstract from module
    'AUTHOR'     => 'Stephen Nelson <stephen@cpan.org>',
);
