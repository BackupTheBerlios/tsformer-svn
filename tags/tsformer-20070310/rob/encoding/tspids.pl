#!/usr/bin/perl
#
#	Requires:
#		- mplayer/mencoder
#		- streamtype_mpg (dvb-mpegtools) -- libdvb
#		- oggenc
#		- projectx
#		- gpac/mpeg4ip for 264viamp4
#		- mkvtoolnix


use strict;
use warnings;
use File::Basename;

my $ret;
my $HOME = "/home/rn114";
my $file = shift(@ARGV);
-e $file or die "Specified file does not exist";
(my $name, my $path, my $ext) = fileparse($file, "\.mpg");
$file = $path . $name;
my %pids = getTsPids("\"$file$ext\"");
chomp(my $aspect = `streamtype_mpg \"$file.mpg\" 2>&1 | grep ASPECT | cut -d' ' -f 2 | sed -e "s/:/\\//"`);

foreach (sort(keys(%pids))) { print "$_ => $pids{$_}\n"; }

print "Aspect: $aspect\n";

mpgdemux($file, %pids) || die("Demux stage failed, exiting\n");
mp2toogg($name);
mpgto264($name);

sub getTsPids {
	my $file = shift(@_);
	my %pids;
	my $VIDEO_STREAM = "0x10000002";
	my $AUDIO_STREAM = "0x50";
	my $TITLE_STREAM = "0x3000001";
	my @streams = `mplayer -v $file -novideo -nosound -frames 0 2>&1 | grep PARSE_PMT | sort | uniq`;
	
	foreach (@streams) {
		/pid=(0x[\dabcdef]*) \((\d*)\), type=(0x\d*),/;
		print "$1 $2 $3\n";
		if($3 eq $VIDEO_STREAM) {$pids{'video'} = $2;}
		if($3 eq $TITLE_STREAM) {$pids{'title'} = $2;}	
		if($3 eq $AUDIO_STREAM and (not defined($pids{'audio'}) or $2 < $pids{'audio'})) {$pids{'audio'} = $2;}
	}
	
	return %pids;
}

sub mpgdemux {
	my $file = shift(@_);
	my %pids = @_;
	my $ret;
	open(INI, "> X.ini") || die("Cannot Open File");
	print INI "SubtitlePanel.SubtitleExportFormat=SON\n" .
			  "SubtitlePanel.SubtitleExportFormat_2=null";
	close(INI);
	$ret = system("projectx \"$file.mpg\" -log -ini X.ini -out . -demux -id $pids{audio},$pids{video},$pids{title}");
	unlink("X.ini");
	if ($ret != 0) {
		warn("Failed to call ProjectX: $ret\n");
		return;
	}
	return $ret;
}

sub mp2toogg {
	my $file = shift(@_);
	my $ret;
	system("mkfifo audiopipe");
	system("oggenc --quiet -b 128 -o\"$file.ogg\" audiopipe &");
	system("mplayer \"$file.mp2\" -hardframedrop -alang en -vc dummy -vo null -ao pcm:fast:file=audiopipe -af resample=44100 &> /dev/null");
	system("rm -f audiopipe");

	return 1;
}

sub mpgtompeg4 {
	my $file = shift(@_);
	system("mencoder \"$file.m2v\" -vf scale=640:480,pp=lb/de,harddup -ovc lavc -lavcopts vcodec=mpeg4:vbitrate=1500:trell:v4mv:mbd=2:vpass=1:turbo -nosound -o /dev/null");
	system("mencoder \"$file.m2v\" -vf scale=640:480,pp=lb/de,harddup -ovc lavc -lavcopts vcodec=mpeg4:vbitrate=1500:trell:v4mv:mbd=2:vpass=2 -nosound -o \"$file.avi\"");
	system("mkvmerge -o \"$file.mkv\" --aspect-ratio 0:$aspect \"$file.avi\" \"$file.ogg\"");
	
	return 1;
}

sub mpgto264 {
	my $file = shift(@_);
	system("mencoder \"$file.m2v\" -vf scale=640:480,pp=lb/de,harddup -ovc x264 -x264encopts bitrate=1000:pass=1:subq=1:frameref=1 -nosound -o /dev/null");
	system("mencoder \"$file.m2v\" -vf scale=640:480,pp=lb/de,harddup -ovc x264 -x264encopts bitrate=1000:pass=2:subq=6:frameref=6:4x4mv:me=3 -nosound -o \"$file.avi\"");
	system("mkvmerge -o \"$file.mkv\" --aspect-ratio 0:16/9 \"$file.avi\" \"$file.ogg\" --engage allow_avc_in_vfw_mode");
	
	return 1;
}

sub mpgto264viamp4 {
	my $file = shift(@_);
	system("mencoder \"$file.m2v\" -vf scale=640:480,pp=lb/de,harddup -ovc x264 -x264encopts bitrate=1000:pass=1:subq=1:frameref=1 -nosound -o /dev/null");
	system("mencoder \"$file.m2v\" -vf scale=640:480,pp=lb/de,harddup -ovc x264 -x264encopts bitrate=1000:pass=2:subq=6:frameref=6:4x4mv:me=3 -nosound -o \"$file.avi\"");
	system("avi2raw \"$file.avi\" \"$file.264\"");
	system("MP4Box -fps 25 -add \"$file.264\" \"$file.mp4\"");
	system("mkvmerge -o \"$file.mkv\" --aspect-ratio 1:$aspect \"$file.mp4\" \"$file.ogg\"");

	return 1;
}
