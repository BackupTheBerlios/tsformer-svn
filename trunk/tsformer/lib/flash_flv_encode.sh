#!/bin/bash
#
# Flash FLVencode.sh

. bash.functions
. global_variables

use_cygwin=0
twopass_encoding=1 # on by default

main() {
	parse_arguments "${@}"

	echo "Processing input file $input_file..."
	echo

	# use captive interface
	[ $iscaptive -eq 1 ] && go_captive

	determine_codec

	encode
}

function encode() {
	# create tmp file
	if [ $twopass_encoding -eq 1 ]; then
		[ ! "$passlogfile" ] && local passlogfile="$(mktemp /tmp/flv.XXXXXX)"
	fi

	# reminder: for cygwin to work properly (bash 3.2.9), $nullfile and
	# $passlogfile are defined earlier. 

	# do 1st pass..
	if [ $skip_1stpass -eq 0 ]; then
	#nice -n $encoder_niceness \
	ffmpeg -i "$input_file" \
		-s $video_resolution \
		-vcodec $video_codec \
		-aspect $video_aspect \
		-b $video_bitrate \
		-ab $audio_bitrate \
		-ar $audio_samplingrate \
		-ac $audio_channels \
		-f $output_format \
		-passlogfile $passlogfile \
		-pass 1 -y "$nullfile"
	fi
	if [ $? -eq 0 ]; then
		status_ok "Pass 1 successful"
	else
		status_err "Pass 1 unsuccessful!"
	fi

	# 2nd pass
	#nice -n $encoder_niceness \
	ffmpeg -i "$input_file" \
		-s $video_resolution \
		-vcodec $video_codec \
		-aspect $video_aspect \
		-b $video_bitrate \
		-ab $audio_bitrate \
		-ar $audio_samplingrate \
		-ac $audio_channels \
		-passlogfile $passlogfile \
		-pass 2 -y $output_file

	if [ $? -eq 0 ]; then
		status_ok "Pass 2 successful"
	else
		status_err "Pass 2 unsuccessful!"
	fi

	rm ${passlogfile}* "${nullfile}" -f
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
	echo "(3) HDV 16:9"
	echo -n "Select [2]: "
	read video_aspect_select
	case $video_aspect_select in
		'1')
			video_resolution='320x240' # -video_aspect 4:3
			;;
		'2')
			video_resolution='352x288' # -video_aspect 16:9
			;;
		'3')
			video_resolution='512x288' # -video_aspect HDV 16:9
			;;
	esac

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
	echo "  --niceness  set nice value"
	echo "  --captive   use captive interface; ask parameters"
	echo "  --cygwin [path\\to\\ffmpeg.exe]   use ffmpeg.exe"
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
					if [ $2 ]; then
						if [ "$(grep -E '\/|\\$' <<< ${2})" ]; then
							# the final letter is '/',
							# = the user has given a path
							if [ "$input_file" ]; then
								output_file="${2}$(basename ${input_file})"
							else
								output_file="${2}$(date +%F)"
							fi

						else
							output_file="${2}"
						fi
						shift 2
					else
						missing_arg "$1"
					fi
					;;

				'-i'|'--input')
					if [ $2 ]; then
						input_file="${2}"
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

				'--passlogfile')
					shift 1
					;;

				'--cygwin')
					use_cygwin=1
					shift 1
					;;

				*)
					input_file="${1}"
					shift 1
					;;

			esac
		done

		[ $use_cygwin -eq 1 ] && init_cygwin_env
		check_parameters

	else
		PRINT_Help
	fi
}

function init_cygwin_env() {
	# user may define the ffmpeg path..
	if [ "$(grep ffmpeg <<< $2)" ]; then
		function ffmpeg() { 
			${2} "${@}"
		}
		shift 1

	# or it may be pre-defined
	elif [ "$cygwin_ffmpeg_path" ]; then
		function ffmpeg() {
			"${cygwin_ffmpeg_path}"  "${@}"
		}

	# but it not, use plain exe file
	else
		function ffmpeg() {
			./ffmpeg.exe "${@}"
		}
	fi

	tmp_path="/tmp/"

	nullfile="tmpfile-CYGWIN"
#	nullfile="$(cygpath -au "${tmp_path}tmpfile-CYGWIN")"

	passlogfile="passlog-$(date +%F)"
#	passlogfile="$(cygpath -au "${tmp_path}passlog-$(date +%F)")"


	if [ $(grep -E '[A-Z0-9]{1}:' <<< ${input_file}) ]; then
		# user has given the input in the form of standard Windows notation
		input_file="$(cygpath -aw "${input_file}")"
	fi

	if [ $(grep -E '[A-Z0-9]{1}:' <<< ${output_file}) ]; then
		# user has given the input in the form of standard Windows notation
		output_file="$(cygpath -am "${output_file}")"
	fi
}


function check_parameters() {
	# input/output files
	if [ ! "$input_file" ]; then
		echo "No input file specified!"
		exit 1
	elif [ ! "$output_file" ]; then
		output_file=$(sed "s/\.[a-zA-Z0-9]\+$/-$(date +%F).${output_format}/" <<< $input_file) 
	fi

	# aspect ratio
	case $video_resolution in
		'320x240')
			video_aspect="4:3"
			;;
		'352x288')
			video_aspect="16:9"
			;;
		'512x288')
			video_aspect="16:9"
			;;
		*)
			video_aspect="16:9"
			;;
	esac

	[ ! "$skip_1stpass" ] && skip_1stpass=0
	[ ! "$nullfile" ] &&  nullfile="/dev/null"
}

status_ok() {
	echo -e "  [${tcGREEN}OK${tSTD}]\t${@}"
}

status_warn() {
	echo -e "  [${tBOLD}${tcYELLOW}!!${tSTD}]\t${@}" 
}

status_err() {
	echo -e "  [${tBOLD}${tcRED}!!${tSTD}]\t${@}" 
}

errmsg () {
        echo -e "${tcRED}${@}${tSTD}"
}

main "${@}"
exit 0
