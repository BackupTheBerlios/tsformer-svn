#!/usr/bin/env perl
##
### dvb transport stream converter
##

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
use Mediator::DVB2VOB;

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
    print "USAGE:\t\$0 -i input\ file[.m2t|.ts] [-o \"output filename\"]\n";

    print "If the input file is already demuxed with projectx,\n";
    print "the demuxed files will be used.\n";

    print "Adjust projectx to use the proper DVB subpages.\n";
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
    # print info
    info() if $verbose;

    # create an object to manipulate the file
    my $converter = new Mediator::DVB2VOB() or die "Cannot create an instance";
    my $inFx; # input file (absolute) with the suffix
    my $inf;  # input file basename
    my $tmpf; # temporary file basename (.* hog up hard drive space)
    my $tmpd; # the directory for $tmpf
    my $tmpF; # "$tmpd/$tmpf"

    # first check if our dependencies are satisfied, error handling done there
    $converter->check_dependencies;

    # unless is_demuxed($inF) demux($inF, $tmpd) or die "demuxing";
    # 
# 	if [ -e "${DEMUXED}.sup" ]; then # subtitles found
# 		eval_gettext $"Seems you've already demuxed the input to ${BASEDIR}" if $verbose;

    # convert_subtitles($tmpF) if subtitles_exist($inf) or die "subtitle conversion";
# 	else
# 		status_warn
# 		eval_gettext $"Subtitles not found" if $verbose;
# 	fi

    # multiplex($tmpF) or die "multiplexing $tmpF";

#     print "Output written to $outF" if $verbose;
#   system('ls $outF -lsh');

    # cleanup;

}

1;