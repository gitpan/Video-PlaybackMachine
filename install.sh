#!/bin/bash

perl Makefile.PL
make install
cp bin/playback_machine.pl /usr/bin
chmod a+x /usr/bin/playback_machine.pl
cp bin/add_movie.pl /usr/bin
chmod a+x /usr/bin/add_movie.pl
