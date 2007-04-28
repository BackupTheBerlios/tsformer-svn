#!/usr/bin/env perl
# Copyright (c) 2007 Mikael Lammentausta

# Permission is hereby granted, free of charge, to any person obtaining 
# a copy of this software and associated documentation files (the 
# "Software"), to deal in the Software without restriction, including 
# without limitation the rights to use, copy, modify, merge, publish, 
# distribute, sublicense, and/or sell copies of the Software, and to 
# permit persons to whom the Software is furnished to do so, subject 
# to the following conditions:

# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
# THE SOFTWARE.

my $VERSION = "0.10";

use strict;
use Getopt::Long;
use Video::DVB2VOB;

my ($opt_help, $verbose);

#############################################################
# COMMAND LINE OPTIONS
#############################################################
GetOptions(
	'help'             => \$opt_help,
	'verbose'          => \$verbose,
) or usage(1);

if( $opt_help ) { usage(1); }

#############################################################
# USAGE and INFO
#############################################################

sub usage {
    my $retval = shift;
    info();
    print "USAGE:\t\$ ts2vob -i input\ file.ts -o \"output filename\"\n";

	print "If the input\ file.ts is already demuxed, as you might have cut it with the projectx GUI,\n";
	print "the script looks for the demuxed files in the same directory as the input file.\n";
	print "If -o defines a directory, it will be used to store temporary files.\n\n";

	print "The subtitles have to be in .sup format. If they exist in the .ts, they will be merged into the .vob.\n";
    exit $retval;
}

sub info {
    print "$0 v" . $VERSION . 
        " - DVB transport stream to VOB converter, with subtitle support\n";
    print "Licensed under the MIT; see the source for copying conditions\n\n";
}


#############################################################
# MAIN
#############################################################
{
}