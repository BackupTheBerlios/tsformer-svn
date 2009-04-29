#!/bin/bash
# Copyright (c) 2007 Mikael Lammentausta

# thanks to xxx for pxsup2dast.c 
#	 to AnMaster for general help and examples with bash scripting
# 	 to Rick Harris for the any2dvd script
#	 to the people who made projectx, tcmplex and dvdauthor
#
# You may contact the author at mikael.lammentausta(at)gmail.com

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


VERSION="1.0.0" # released 20070310


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


### SOURCE FUNCTIONS and PATHS ##########
source "lib/ts2vob.functions"
source "lib/bash.functions"
source /etc/dvb2vob.conf
source /usr/bin/gettext.sh



PRINT_ts2vob_Info


### PARSING THE ARGUMENTS ###########

ParseArgs "$@"


### CHECKING DEPENDENCIES ###########

CheckDeps;  

if [ "$DEPFAIL" -eq "1" ]; then 
	echo -n ${tcRED}
	eval_gettext $"CRITICAL DEPENDENCIES ARE MISSING, EMERGE ;-)"
	echo ${tSTD};
	exit 0;
fi



### DEBUG ###

echo -ne "  [${tcGREEN}OK${tSTD}]\t" && \
eval_gettext $"Input file: " ; echo ${INPUT}


### CHECK IF USER HAS DEMUXED SOURCE ALREADY  #######
demux


### MULTIPLEX TO VOB #######
multiplex


#### PROCESS SUBTITLES, if they exist... ##########
process_Subtitles 

### CLEAN ######
clean
