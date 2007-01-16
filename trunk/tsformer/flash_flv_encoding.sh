#!/bin/bash
#
# Flash FLVencode.sh
#
# Usage: flash_flv_encode.sh inputfile
#

#FILE="boitekong.avi"     # source file
#OUT=MyVideo.flv          # target file
                        

FILE=$1
OUT=`echo -n "$FILE" | sed 's/\.[a-zA-Z0-9]\+$/-flv.flv/'`
ABR=128 # audio bitrate
AR=44100 # audio sampling rate
AC=2 # audio channels
VBR=500 # video bitrate
RES='err'

echo "Processing input file $FILE..."
echo
echo "Aspect ratio?"
echo "(1) 4:3"
echo "(2) 16:9"
echo -n "Select [2]: "
read aspect
if [ "$aspect" = "1" ]; then
  RES='320x240'
else
  RES='352x288'
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

nice -n 19 \
#"/cygdrive/c/Program files/Avid/Avid liquid 7/Plugins/export/ffmpeg.exe" "$FILE" \
ffmpeg -i "$FILE" -s $aspect -vcodec flv -b $VBR -ab $ABR -ar $AR -ac $AC -pass 1 $OUT

nice -n 19 \
#"/cygdrive/c/Program files/Avid/Avid liquid 7/Plugins/export/ffmpeg.exe" "$FILE" \
ffmpeg -i "$FILE" -s $aspect -vcodec flv -b $VBR -ab $ABR -ar $AR -ac $AC -pass 2 $OUT
