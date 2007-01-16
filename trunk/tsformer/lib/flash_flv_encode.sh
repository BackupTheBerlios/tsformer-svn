#!/bin/bash
#
# Flash FLVencode.sh

#FILE="boitekong.avi"     # source file
#OUT=MyVideo.flv          # target file

. ../bash.functions

FILE=$1
OUT=`echo -n "$FILE" | sed 's/\.[a-zA-Z0-9]\+$/-flv.flv/'`
ABR=128 # audio bitrate
AR=44100 # audio sampling rate
AC=2 # audio channels
VBR=500 # video bitrate
NICENESS=19
RES='err'

main() {

	parse_arguments

	echo "Processing input file $FILE..."
	echo
	echo "Aspect ratio?"
	echo "(1) 4:3"
	echo "(2) 16:9"
	echo -n "Select [2]: "
	read aspect
	if [ "$aspect" = "1" ]; then
	  RES='320x240' # -aspect 4:3
	else
	  RES='352x288' # -aspect 16:9
	fi
	echo -n "Video bitrate? [$VBR]: "
	read vbr_in
	if [ "$vbr_in" != "" ]; then
	  VBR=$vbr_in
	fi

	echo -n "Audio bitrate? [$ABR]: "
	read abr_in
	if [ "$abr_in" != "" ]; then
	  ABR=$abr_in
	fi

	rm -f flv_pass.log 2>/dev/null

	# onko "none"?
	# -aspect -määritys puuttuu
	nice -n 19 \
	ffmpeg -i "$FILE" -s $aspect -vcodec none -b $VBR -ab $ABR -ar $AR -ac $AC -pass 1 -y "/dev/null"
	#"/cygdrive/c/Program files/Avid/Avid liquid 7/Plugins/export/ffmpeg.exe" "$FILE" \

	nice -n 19 \
	ffmpeg -i "$FILE" -s $aspect -vcodec flv -b $VBR -ab $ABR -ar $AR -ac $AC -pass 2 $OUT
	#"/cygdrive/c/Program files/Avid/Avid liquid 7/Plugins/export/ffmpeg.exe" "$FILE" \
}



function PRINT_Help() {
	echo "Usage: flash_flv_encode.sh inputfile"
	echo
}

####### PARSE THE COMMAND LINE ARGUMENTS
function parse_arguments() {
	if [ "$#" -gt 0 ]; then
		while [ "$#" -gt 0 ]; do
			case "$1" in
				'--help'|'-help'|'--usage'|'-usage'|'-h'|'')
					PRINT_Help
					exit 0
					;;

				'-o'|'--output')
					# direct output to a named file
					if [ $2 ]; then
						usexml=1
						XMLFILE="${2}"
						shift 2
					else
						missing_arg "$1"
					fi
					;;

				'-i'|'--input')
					if [ $2 ]; then
						usexml=1
						XMLFILE="${2}"
						shift 2
					else
						missing_arg "$1"
					fi
					;;
	

FILE=$1
OUT=`echo -n "$FILE" | sed 's/\.[a-zA-Z0-9]\+$/-flv.flv/'`
ABR=128 # audio bitrate
AR=44100 # audio sampling rate
AC=2 # audio channels
VBR=500 # video bitrate
NICENESS=19
RES='err'


				'-v'|'--verbose')
					isverbose=1
					shift 1
					;;

				esac
		done
	else
		PRINT_Help
	fi
}

status_ok() {
	echo -ne "  [${tcGREEN}OK${tSTD}]\t" 
}

status_warn() {
	echo -ne "  [${tBOLD}${tcYELLOW}!!${tSTD}]\t" 
}

status_err() {
	echo -ne "  [${tBOLD}${tcRED}!!${tSTD}]\t" 
}

errmsg () {
        echo -e "${tcRED}$1${tSTD}"
}

main
exit 0





