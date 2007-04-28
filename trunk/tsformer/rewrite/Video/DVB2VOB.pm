package Mediator::DVB2VOB;
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

use strict;
require Exporter;


### TODO ##############
# usage: -i tai ei mitään: toiminta sama
# -o voi ottaa hakemiston, tiedostonimen tai molemmat
# if WORKDIR etc is not defined by cli or here, default to $BASEDIR
# if -o defines directory, use that as WORKDIR
# -v | --verbose 	= verbose
# --subdelay 		= delay (in ms) for subtitles (pass to pxsup2dast)
# tcmplex: *** -alkuiset > stdout ; INFO > stderr
# jos inputin päätettä ei määritellä, pitäisi silti siirtää/poistaa!
# dvdxmlauth: vain pelkkä create menus mahdollisuus!


sub new {
    my $class = shift;

    my $self = {};

#     my $parser = XML::LibXML->new();
#     my $tree = $parser->parse_string($input);
#     $root = $tree->getDocumentElement;

    bless $self, $class;
}

sub check_dependencies {
    my %dependencies = ( 
        'projectx' => "0.90.3.00", 
        'tcmplex-panteltje' => '',
        'dvdauthor' => '',
        'dirname' => '',
        'pxsup2dast' => '',
        'iconv' => '',
    );

    # if the deps don't match, return 0 (error)
    unless ( check_programs(\%dependencies) ) { return 0; }
    else { return 1; }

    # check for all needed programs
    sub check_programs(%) {

        my $ref = shift;
        my %dependencies = %$ref;

        foreach my $dep ( keys %dependencies ) {

            unless ( system( "which $dep &>/dev/null" ) == 0 ) {

                if ( $dep eq 'pxsup2dast' ) { 
print "pxsup2dast can be found at http://www.guru-group.fi/~too/sw/m2vmp2cut/pxsup2dast.c\n";
                };

                die "Cannot continue without $dep -- died";
            }
        }
        return 1;
    }
}

sub preprocess {}

# demux()
# deduces if the input file has already been demuxed, or demuxes it with projectX.
sub demux {	
#         if [ -e "${BASEDIR}/${INPUT_FILENAME}.m2v" ]; then # the file has been demuxed 
# 		DEMUXED="${BASEDIR}/${INPUT_FILENAME}";
# 		status_ok
# 		eval_gettext $"Seems you've already demuxed the input to " ; echo "${BASEDIR}"
# 
# 	elif [[ -e "${WORKDIR}"/"${INPUT_FILENAME}.m2v" ]]; then 
# 		DEMUXED="${WORKDIR}"/"${INPUT_FILENAME}";
# 		echo -ne "\t[${tcGREEN}OK${tSTD}]\t" 
# 		eval_gettext $"Seems you've already demuxed the input to " ; echo "${WORKDIR}"
# 
# 	else ### DEMUX TO .M2V  .MP2  .SUP ###################
# 
# 		status_ok
# 		eval_gettext $"Demuxing input to " ; echo "${WORKDIR}"
# 
# 		$(java-config -J) -Xms32m -Xmx512m -cp $(java-config -p projectx,jakarta-oro-2.0,commons-net) \
# net.sourceforge.dvb.projectx.common.Start -ini "${LIBDIR}/X.ini" -out "${WORKDIR}" -name "${OUTPUT}" "${INPUT}";
# 		DEMUXED="${WORKDIR}"/"${INPUT_FILENAME}";
# 	fi
}

sub convert_subtitles {}

sub mux_av {}

sub mux_subtitles {}

sub clean {}



1;