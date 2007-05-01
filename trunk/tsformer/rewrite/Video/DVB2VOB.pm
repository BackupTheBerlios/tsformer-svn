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

# deduces if the input file has already been demuxed
sub is_demuxed($) {
    my ($self, $input) = shift;

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

    return true;
#     else return false;
}

# demux()
# demuxes the input with projectX.
sub demux {	
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


# parameters
#  1  absolute subtitle filename
sub convert_subtitles {

#     status_ok
#     eval_gettext $"Subtitles found, processing" ; echo
# 
#     # use pxsup2dast to convert the .sup subtitles into a format
#     # that can be used by later processes
#     pxsup2dast "${DEMUXED}.sup" "${DEMUXED}.sup.IFO" &> ${LOGFILE}
#     iconv "${DEMUXED}.d/spumux.xml" -t UTF-8 > "${DEMUXED}.d/spumux-utf8.xml"
# 
#     local success=0
# 
#     # mux the subs into the vob
#     # spumux -v $VERBOSITY "${DEMUXED}.d/spumux-utf8.xml" < "${WORKDIR}/${OUTPUT}.vob" > "${FINALDIR}"/"${OUTPUT}.vob" 2&>${LOGFILE} && \
#     spumux -v $VERBOSITY "${DEMUXED}.d/spumux-utf8.xml" < "${WORKDIR}/${OUTPUT}.vob" > "${FINALDIR}"/"${OUTPUT}.vob" 2>> "${LOGFILE}" && success=1
# 
#     if [ $success -eq 1 ]; then
#             status_ok 
#             tail "${LOGFILE}" | grep added | grep -Eo '[0-9]+ subtitles [a-zA-Z0-9, ]+skipped'
# 
#     fi

}

sub mux_av {
# 	cd ${WORKDIR}
# 	status_ok
# 	eval_gettext $"Muxing input to " ; echo "${WORKDIR}/${OUTPUT}.vob"
# 	tcmplex-panteltje -i "${DEMUXED}.m2v" -p "${DEMUXED}.mp2" \
# 		-m d -d $VERBOSITY -o "${WORKDIR}/${OUTPUT}.vob" 2>&1 | grep '^\*'  &> ${LOGFILE}

}

sub mux_subtitles {}

sub clean {
#         # cleanup for subtitles
#         rm "${WORKDIR}/${OUTPUT}.vob" -f 
#         rm "${DEMUXED}.m2v" -f
#         rm "${DEMUXED}.mp2" -f 
#         mv "${DEMUXED}.sup" "${DEMUXED}.sup.IFO" "${DEMUXED}.d/" ${LOGDIR}
#         mv "${DEMUXED}_log.txt" "${LOGDIR}"


#     if mv "${WORKDIR}/${OUTPUT}.vob" "${FINALDIR}" ; then
# 
#             status_ok 
#             eval_gettext $"Output can be found at " ; echo "$FINALDIR/$OUTPUT.vob" 
#             rm "${DEMUXED}.m2v" -f
#             rm "${DEMUXED}.mp2" -f 
#             mv "${DEMUXED}_log.txt" "${LOGDIR}"
#     fi

# 	# TODO: other things here too...
# 	if [ "$move" == 1 ]; then
# 		mv "${INPUT}" ${TRASH} && \
# 		echo -ne "  [${tcGREEN}!!${tSTD}]\t" && \
# 		eval_gettext $"Input file moved to " ; echo ${TRASH}
# 	elif [ "$delete" == 1 ]; then
# 		rm -f "${INPUT}" && \
# 		echo -ne "  [${tcGREEN}OK${tSTD}]\t" && \
# 		eval_gettext $"Input file removed" ; echo
# 	fi
# 
}



1;