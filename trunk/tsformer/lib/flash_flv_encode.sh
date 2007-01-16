#!/bin/bash
#
# Flash FLVencode.sh

#input_file="boitekong.avi"     # source file
#output_file=MyVideo.flv          # target file

. bash.functions
. global_variables

main() {

	parse_arguments "${@}"
	check_parameters

	echo "Processing input file $input_file..."
	echo

	[ $iscaptive -eq 1 ] && go_captive

	determine_codec

	encode
}

function encode() {
	# remove redundant log file
	rm -f flv_pass.log 2>/dev/null

	# -video_aspect -määritys puuttuu
	nice -n $encoder_niceness \
	ffmpeg -i "$input_file" \
		-s $video_aspect \
		-vcodec null \
		-b $video_bitrate \
		-ab $audio_bitrate \
		-ar $audio_samplingrate \
		-ac $audio_channels \
		-pass 1 "/dev/null"

	nice -n $encoder_niceness \
	ffmpeg -i "$input_file" \
		-s $video_aspect \
		-vcodec $video_codec \
		-b $video_bitrate \
		-ab $audio_bitrate \
		-ar $audio_samplingrate \
		-ac $audio_channels \
		-pass 2 $output_file
}

function determine_codec() {
	case $output_format in
		'flv'|'flash')
			video_codec="flv"
			;;
		*)
			echo "unable to determine codec for $output_format!"
			exit 1
			;;
	esac
}

function go_captive() {
	echo "Aspect ratio?"
	echo "(1) 4:3"
	echo "(2) 16:9"
	echo -n "Select [2]: "
	read video_aspect
	set -x
	if [ "$video_aspect" = "1" ]; then
	  video_resolution='320x240' # -video_aspect 4:3
	else
	  video_resolution='352x288' # -video_aspect 16:9
	fi
	set +x
	exit 0
	echo -n "Video bitrate? [$video_bitrate]: "
	read vbr_in
	if [ "$vbr_in" != "" ]; then
	  video_bitrate=$vbr_in
	fi

	echo -n "Audio bitrate? [$audio_bitrate]: "
	read abr_in
	if [ "$abr_in" != "" ]; then
	  audio_bitrate=$abr_in
	fi
}

function PRINT_Help() {
	echo "Usage: flash_flv_encode.sh inputfile"
	echo
	echo " general options"
	echo "  -i          input file"
	echo "  -o          output file"
	echo "  --format    output file format"
	echo " audio options"
	echo "  -abr        audio bitrate [default: 128]" 
	echo "  -asr        audio sampling rate [default: 44100]"
	echo "  -ac         audio channels [default: 2]"
	echo " video options"
	echo "  -vbr        video bitrate [default: 500]"
	echo "  -res        video resolution [default: ?x?]"
	echo " miscellaneous"
	echo "  --verbose"
	echo "  --captive   use captive interface; ask parameters"
	echo "  --cygwin [path\\to\\ffmpeg.exe]   use ffmpeg.exe"
	echo
}

####### Paudio_samplingrateSE THE COMMAND LINE audio_samplingrateGUMENTS
function parse_arguments() {
	if [ "$#" -gt 0 ]; then
		while [ "$#" -gt 0 ]; do
			case "$1" in
				'--help'|'-help'|'--usage'|'-usage'|'-h'|'')
					PRINT_Help
					exit 0
					;;

				'-o'|'--output')
					if [ $2 ]; then
						output_filename="${2}"
						shift 2
					else
						missing_arg "$1"
					fi
					;;

				'-i'|'--input')
					if [ $2 ]; then
						input_filename="${2}"
						shift 2
					else
						missing_arg "$1"
					fi
					;;

				'--format')
					if [ $2 ]; then
						output_format="${2}"
						shift 2
					else
						missing_arg "$1"
					fi
					;;

				'-abr')
					if [ $2 ]; then
						audio_bitrate="${2}"
						shift 2
					else
						missing_arg "$1"
					fi
					;;

				'-asr')
					if [ $2 ]; then
						audio_samplingrate="${2}"
						shift 2
					else
						missing_arg "$1"
					fi
					;;

				'-ac')
					if [ $2 ]; then
						audio_channels="${2}"
						shift 2
					else
						missing_arg "$1"
					fi
					;;

				'-vbr')
					if [ $2 ]; then
						video_bitrate="${2}"
						shift 2
					else
						missing_arg "$1"
					fi
					;;

				'-res'|'--resolution')
					if [ $2 ]; then
						video_resolution="${2}"
						shift 2
					else
						missing_arg "$1"
					fi
					;;

				'--niceness')
					if [ $2 ]; then
						encoder_niceness="${2}"
						shift 2
					else
						missing_arg "$1"
					fi
					;;

				'-v'|'--verbose')
					isverbose=1
					shift 1
					;;

				'--captive')
					iscaptive=1
					shift 1
					;;

				'--cygwin')
					# user may define the ffmpeg path..
					if [ $(grep ffmpeg $2) ]; then
						function ffmpeg() { ${2} }
						shift 1

					# or it may be pre-defined
					elif [ "$cygwin_ffmpeg_path" ]; then
						function ffmpeg() { ${cygwin_ffmpeg_path} }

					# but it not, use plain exe file
					else
						function ffmpeg() { ffmpeg.exe }
					fi

					shift 1
					;;

				esac
		done
	else
		PRINT_Help
	fi
}

function check_parameters() {
	if [ ! "$input_file" ]; then
		echo "No input file specified!"
		exit 1
	elif [ ! "$output_file" ]; then
		output_file=$(sed "s/\.[a-zA-Z0-9]\+$/-${output_format}.${output_format}/" <<< $input_file) 
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

main "${@}"
exit 0
