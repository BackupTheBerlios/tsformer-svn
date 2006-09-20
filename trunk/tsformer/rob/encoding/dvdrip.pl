#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

# Options are:
#   switch		function		default value
#	-a			audio quality	3
#	-b			bitrate			1000
#	-x			width			640
#	-y			height			480
#	-s			crop slices		5
#	-t			tmp dir			/tmp/enc
#	-e			extra options	--
#	-o			output file		output.ogm
#	file		input file		--

my %Options;
getopt('abxyost', \%Options);

if( $#ARGV != 0 ) {
	print "Please specify one input file\n";
	exit;
}

unless( $Options{'a'} ) { $Options{'a'} = 3; }
unless( $Options{'b'} ) { $Options{'b'} = 1000; }
unless( $Options{'x'} ) { $Options{'x'} = 640; }
unless( $Options{'y'} ) { $Options{'y'} = 480; }
unless( $Options{'s'} ) { $Options{'s'} = 5; }
unless( $Options{'o'} ) { $Options{'o'} = 'output.ogm'; }
unless( $Options{'t'} ) { $Options{'t'} = '/tmp/enc'; }
my $tmpdir = $Options{'t'};
my $input = $ARGV[0];

if( $input =~ m/nuv$/ ) {
	# Deal with the .nuv
	nuvenc();
}
elsif( $input =~ m/(^dvd|vob$)/ ) {
	# Deal with the dvd
	dvdenc();
} 
else {
	# Generic video file
	videnc();
}

#####################
#	NUV encode		#
#####################

sub nuvenc
{
	print "Encoding NuppleVideo file.\n";
	my $aspect;
	# Call to nuvinfo for aspect
	if( `nuvinfo $input` =~ m/aspect: *((\d\.)?\d*)/ ) {
		$aspect = $1;
		print "Aspect from nuv: $aspect\n";
	}
	else {
		die "Nuv aspect ratio cannot be determined.";
	}
	system( "mencoder $input -sws 2 -vf scale=$Options{'x'}:$Options{'y'},pp=lb/de,harddup -force-avi-aspect $aspect -ovc lavc -lavcopts vcodec=mpeg4:vhq:vbitrate=$Options{'b'}:vpass=1:turbo -oac copy vbr=$Options{'a'} -o /dev/null" );
	system( "mencoder $input -sws 2 -vf scale=$Options{'x'}:$Options{'y'},pp=lb/de,harddup -force-avi-aspect $aspect -ovc lavc -lavcopts vcodec=mpeg4:vhq:vbitrate=$Options{'b'}:vpass=2 -oac mp3lame -lameopts vbr=$Options{'a'} -o $Options{'o'}" );
}

#####################
#	DVD encode		#
#####################

sub dvdenc
{
	print "Encoding DVD.\n";
	print "Dumping video...\n";
	system( "mencoder -idx $input -ovc copy -nosound -o $tmpdir/temp.avi &> /dev/null" );

	(my $hours, my $minutes, my $seconds ) = split( /:/, `avinfo $tmpdir/temp.avi | grep video | cut -d' ' -f 3`
	
	
	my $length		= ((($hours * 60) + $minutes) * 60) + $seconds;
	my $lengthfac	= $length/($Options{'s'}+1);

	print "Video length: " . $length / 60 . " minutes\n";

	print "Rebuilding AVI index...\n";
	system( "mplayer $tmpdir/temp.avi -forceidx -ss 0:$length -novideo &> /dev/null" );

	print "Cutting crop slices...\n";
	my @croplist;
	for(my $x=0; $x<$Options{'s'}; $x++) {
		my $seek = ($x+1)*$lengthfac;
		print $seek . "\n";
		system( "mencoder $tmpdir/temp.avi -forceidx -ss 0:$seek -endpos 0:01 -ovc copy -nosound -o $tmpdir/temp$seek.avi &> /dev/null" );
		$croplist[$x] = `mplayer -vf cropdetect -vo null $tmpdir/temp$seek.avi  | grep "crop area" | sed '2,\$d'`;
		print $croplist[$x];
		system( "rm $tmpdir/temp$seek.avi" );
	}

	my @tmplist;
	for(my $x=0; $x<$Options{'s'}; $x++) {
		$croplist[$x] =~ m/=(-?\d*):(-?\d*):(-?\d*):(-?\d*)/;
		print "$1 $2 $3 $4\n";
		push( @{$tmplist[0]}, $1 );
		push( @{$tmplist[1]}, $2 );
		push( @{$tmplist[2]}, $3 );
		push( @{$tmplist[3]}, $4 );
	}

	my $cropvar = (sort { $a <=> $b } @{$tmplist[0]})[3] . ":" . (sort { $a <=> $b } @{$tmplist[1]})[3] . ":" . (sort { $a <=> $b } @{$tmplist[2]})[3] . ":" . (sort { $a <=> $b } @{$tmplist[3]})[3];
	print "Crop dimensions: $cropvar\n";

	print "Grabbing audio...\n";
	system( "mkfifo $tmpdir/audiopipe" );
	system( "oggenc --quiet -q$Options{'a'} -o$tmpdir/audio.ogg $tmpdir/audiopipe &" );
	system( "mplayer $input -hardframedrop -alang en -vc dummy -vo null -ao pcm -af volume=10db,resample=44100 -aofile $tmpdir/audiopipe &> /dev/null" );
	system( "rm -f $tmpdir/audiopipe");
	print "Audio obtained.\n";

	print "Beginning first video pass...";
#	Requires either to be scaled to the right aspect (more portable)
#	or force-avi-aspect (mplayer only)
	system( "mencoder $tmpdir/temp.avi -vf crop=$cropvar,pp=lb,scale=$Options{'x'}:$Options{'y'},harddup -ovc lavc -lavcopts vcodec=mpeg4:trell:v4mv:mbd=2:vbitrate=$Options{'b'}:vpass=1:turbo -nosound -o /dev/null" ); 
	print "Beginning second video pass...";
	system( "mencoder $tmpdir/temp.avi -vf crop=$cropvar,pp=lb,scale=$Options{'x'}:$Options{'y'},harddup -ovc lavc -lavcopts vcodec=mpeg4:trell:v4mv:mbd=2:vbitrate=$Options{'b'}:vpass=2 -nosound -o $tmpdir/video.avi" );
	print "Merging A/V data...";
	system( "ogmmerge -o $Options{'o'} $tmpdir/video.avi $tmpdir/audio.ogg");


	system( "rm $tmpdir/temp.avi $tmpdir/video.avi $tmpdir/audio.ogg -f" );
	print "Rip complete.\n"
}

#####################
#	generic encode	#
#####################

sub videnc
{

}
