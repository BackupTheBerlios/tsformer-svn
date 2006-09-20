#!/bin/bash
#
# VDR recording to MPEG4 AVC + Ogg Vorbis + SRT converter
#
# Niko Mikkilä <mikkila at cs helsinki fi>
# Public Domain
#
# Usage: ./vdr-x264.sh part1.vdr part2.vdr ...
#
# The resulting .mkv (and .srt) files will be named after the first
# file and written to its directory.
# The process can be customized by modifying the parameters below.
#
# This script requires the following tools (versions I've used in parentheses):
# - Project X (0.82 or later)		: for VDR demuxing
# - mencoder (CVS 2005-07 or later with x264 support)	: for video encoding
# - mplayer (1.0pre* or CVS)		: for audio decoding
# - oggenc (1.0 or later)		: for audio encoding
# - mkvmerge (1.4.2 or later)		: for muxing
# - son2srt				: for subtitles
#


LAUNCHDIR=`dirname $0`

# This directory will be used for demuxing and encoding, so it should
# be empty to avoid conflicts.
WORKDIR="/tmp/vdr-x264"
#WORKDIR="$LAUNCHDIR/work"

NICE_LEVEL=15


######### Subtitles ###########

SON2SRT="$LAUNCHDIR/son2srt.py"
OCR_DATABASE="$LAUNCHDIR/yle_dvbsub"

########### Demux #############

PROJECTX="$LAUNCHDIR/../ProjectX-0.82.1-noyield/ProjectX.jar"
PROJECTX_INI="$LAUNCHDIR/../ProjectX-0.82.1-noyield/X.ini"


########### Video #############

VBITRATE=800

# Deinterlace
#VF="-vf lavcdeint"

OPTIONS_PASS1="pass=1:bframes=5:b_adapt:weight_b:b_pyramid:bitrate=$VBITRATE:cabac:keyint=600:subq=1:me=1:frameref=1:log=1"

OPTIONS_PASS2="pass=2:bframes=5:b_adapt:weight_b:b_pyramid:bitrate=$VBITRATE:8x8dct:4x4mv:cabac:keyint=600:me=3:subq=6:frameref=4:log=1"

########### Audio #############

VORBISQ=0
VORBISOPTS="--resample 44100"

# Audio synchronization parameter for mkvmerge.
# One of these tools seems to cut 200-300 ms of audio from the beginning for me.
SYNC=300

###############################

if (($# < 1)); then
	echo ""
	echo "VDR recording to MPEG4 AVC + OGG VORBIS + SRT converter"
	echo ""
	echo "Usage: ./vdr-x264.sh part1.vdr part2.vdr"
	echo "Modify parameters within the script to suit your needs!"
	echo ""
	exit
fi

dirname=`dirname "$1"`
basename=`basename "$1" .vdr`
file="$WORKDIR/$basename"

mkdir -p "$WORKDIR"

echo ""
echo "Demuxing..."
echo ""
java -jar "$PROJECTX" -c "$PROJECTX_INI" -o "$WORKDIR" "$@"

video="$file.m2v"
audio="$file.mpa"
subs="$file.son"

echo ""
echo "Converting subtitles..."
echo ""
$SON2SRT -d "$OCR_DATABASE" -c -s 9 -i "$subs" -o "$dirname/$basename.srt"


echo ""
echo "Encoding video..."
echo ""

nice -n $NICE_LEVEL mencoder -noskip $VF -nosound -ovc x264 -x264encopts $OPTIONS_PASS1 -passlogfile "$file".log "$video" -o "$file".x264.avi

nice -n $NICE_LEVEL mencoder -noskip $VF -nosound -ovc x264 -x264encopts $OPTIONS_PASS2 -passlogfile "$file".log "$video" -o "$file".x264.avi

echo ""
echo "Encoding audio..."
echo ""

nice -n $NICE_LEVEL mplayer -ac a52,mad, -format s16le -vc dummy -vo null -ao pcm:file="$file".wav "$audio"

nice -n $NICE_LEVEL oggenc -q $VORBISQ $VORBISOPTS -o "$file".ogg "$file".wav && rm -f "$file".wav

# vorbisgain "$file".ogg

echo ""
echo "Merging to .mkv..."
echo ""

# Mux
nice -n $NICE_LEVEL mkvmerge -y 0:$SYNC -o "$dirname/$basename".mkv -A "$file".x264.avi "$file".ogg && rm -f "$file".x264.avi "$file".ogg

# We could insert the subtitle track into the Matroska file here, but editing
# it would be harder.

