#!/usr/bin/perl
#	Requires:
#       - mplayer/mencoder
#       - streamtype_mpg (dvb-mpegtools) -- libdvb
#       - oggenc
#       - projectx
#       - gpac/mpeg4ip for 264viamp4
#       - mkvtoolnix
#       - gocr 0.40 and netpbm for dvb subtitles
#
#   TODO:
#       - fix up cutlists for other cases
#       - don't demux subtitles unless requested

use strict;
use warnings;
use Getopt::Std;
use Getopt::Long;
use File::Basename;

my $scriptName = "$0";
my $versionMajor = 0;
my $versionMinor = 1;

my $son2srt = '~/son2srt';

my ( @cruft );

my ( $videoCodec, $videoQuality, $videoWidth, $videoHeight, $deinterlace );
my ( $audioCodec, $audioQuality, $verbose, $subtitles );
my ( $inputFile, $inputMode );
my ( $outputFile, $outFileName, $outFilePath, $outFileExt );
my ( $audioFile, $videoFile, $titleFile, $codec, $options1, $options2 );
my ( @phases );
our ( $opt_help, $opt_debug, $opt_mythcuts );


sub print_version {
    print("$scriptName: Version $versionMajor.$versionMinor\n");
}

sub usage {
    my $retval = shift @_;
    print_version();
    print("usage:
           --help           This.
           --video-codec    Video codec (default=lavc, others=xvid,x264)
           --video-quality  Video stream bitrate (default=1000)
           --video-height   Video stream height (default=input size)
           --video-width    Video stream width  (default=input size)
           --deinterlace    Deinterlace video stream
           --audio-codec    Audio codec (default=ogg, others=mp3,aac)
           --audio-quality  Audio stream quality (default=3, range 1-9)
           --mode           Input file mode (default=autodetect, 
                                              others=mpegts,dvd)
           --output         Output file name (default=output.mkv, 
                                               others=*.mp4,*.ogm,*.avi)
           --verbose        Be more verbose
           --subtitles      Extract DVB subtitles
           --mythcuts       Use MythTV created cutlists to remove
                            unwanted material. NB only works with a cut area
                            at beginning and end currently (of at least one
                            frame)
           --only           Perform only the phases specified in a comma
                            separated list: setup,demux,encaudio,encvideo,
                            enctitles,mux,delete
           
");
    exit $retval;
}
           
sub cmdSanity {
    # Check phases
    unless( @phases ) {
        @phases = ( 'setup', 'demux', 'encvideo', 'encaudio', 
                'enctitles', 'mux', 'delete' );
    } else {
        @phases = split( /,/, join( ',', @phases ) );
    }
    # Input file
    $inputFile = $ARGV[0];
    -e $inputFile or die "Target file does not exist";
    unless( $inputMode ) {
        if( $inputFile =~ m/(^dvd|vob$)/ ) {
            $inputMode = 'dvd';
        } else {
            ( $inputMode ) = 
                ( (grep( /MUX/, `midentify \"$inputFile\"` ))[0] =~ m/=(\w*)/);
        }
    }
    vprint( "Input mode: $inputMode" );
    # Output file
    unless( $outputFile ) { $outputFile = 'output.mkv'; }
    vprint( "Output file: $outputFile" );
    ($outFileName, 
     $outFilePath, 
     $outFileExt) = fileparse("$outputFile", ('.mkv', '.mp4', '.avi', '.ogm'));
    unless( $outFileExt ) { die "Unrecognised container format"; }
    vprint( "Output container: $outFileExt" );
    if( $outFileExt eq '.mp4' ) {
        unless( $audioCodec eq 'aac' && $videoCodec ne 'xvid' ) {
            die "Incompatible format/container mix"; }
    } elsif( $outFileExt eq '.avi' ) {
        unless( $audioCodec eq 'mp3' && $videoCodec ne 'x264' ) {
            die "Incompatible format/container mix"; }
    }
    # Check video options
    unless( $videoCodec ) { $videoCodec = 'lavc'; }
    unless( $videoQuality ) { $videoQuality = 1000; }
    # Check audio options
    unless( $audioCodec ) { $audioCodec = 'ogg'; }
    unless( $audioCodec =~ /ogg|mp3|aac/ ) { die "Invalid audio format"; }
    unless( $audioQuality ) { $audioQuality = 3; }
    unless( $audioQuality > 0 and $audioQuality < 10 ) {
        die "audioQuality out of range (0..10)";
    }
}

GetOptions(
    'help',
    'video-codec=s'     => \$videoCodec,
    'video-quality=i'   => \$videoQuality,
    'video-width=i'     => \$videoWidth,
    'video-height=i'    => \$videoHeight,
    'deinterlace'       => \$deinterlace,
    'audio-codec=s'     => \$audioCodec,
    'audio-quality=i'   => \$audioQuality,
    'subtitles'         => \$subtitles,
    'mode=s'            => \$inputMode,
    'output=s'          => \$outputFile,
    'verbose'           => \$verbose,
    'only=s'            => \@phases,
    'mythcuts',
    'debug'
) or usage(1);

if( $opt_help ) { usage(1); }

vprint( "ARGS: $#ARGV" );
unless( $#ARGV == 0 ) { die "Please specify one input file\n"; }


cmdSanity();

# Set up audio
# check compatibility of containers

$audioFile = "temp.$audioCodec";
vprint("Audio codec: $audioCodec; quality: $audioQuality");

# Maybe audio filters (i.e. normalize for dvds)

# Set up video
$videoFile = 'temp.avi';
## filters
vprint ("Building filter path");
my $filters = '-vf ';
if( $deinterlace ) {
    $filters .= 'pp=lb/de,';
}
if( $videoWidth and $videoHeight ) {
    $filters .= "scale=$videoWidth:$videoHeight,";
}
$filters .= 'harddup';
vprint("Filters: $filters");

## find aspect ratio
my $aspect;
if( $inputMode eq 'mpegts' ) {
    chomp($aspect = `streamtype_mpg \"$inputFile\" 2>&1 | grep ASPECT | \ 
                        cut -d' ' -f 2 | sed -e "s/:/\\//"`);
} else {
    $aspect = 
        ( split( /=/, (grep( /ASPECT/, `midentify \"$inputFile\"` ))[0] ) )[1];
}
if( substr( $aspect, 0, 1 ) eq '0' ) {
    warn "Aspect ratio not determined, using 16:9";
    $aspect = "16/9";
}
vprint("Aspect ratio: $aspect");

## codec & options
vprint("Finding codec options");
if( $videoCodec eq 'x264' ) {
    $codec = 'x264 -x264encopts';
    $options1 = 'pass=1:subq=1:frameref=1:bitrate=' . $videoQuality;
    $options2 = 'pass=2:subq=6:frameref=6:4x4mv:me=3:bitrate=' . $videoQuality;
} elsif( $videoCodec eq 'lavc' ) {
    $codec = 'lavc -lavcopts';
    $options1 = 'vcodec=mpeg4:trell:v4mv:mbd=2:vpass=1:vbitrate='.$videoQuality;
    $options2 = 'vcodec=mpeg4:trell:v4mv:mbd=2:vpass=2:vbitrate='.$videoQuality;
} elsif( $videoCodec eq 'xvid' ) {
    warn( "Untested encoding method" );
    $codec = 'xvidenc -xvidencopts';
    $options1 = 'pass=1:turbo:bitrate=' . $videoQuality;
    $options2 = 'pass=2:bitrate=' . $videoQuality;
} else {
    die( "Unrecognised encoding mode" );
}
vprint("Codec string: $codec, $options1, $options2");

if( $#phases == 1 and $phases[0] eq 'setup' ) {
    exit( 0 );
}

# Present video/audio
my $videoIn;
my $audioIn;
my $titleIn;
if( grep( $_ eq 'demux', @phases ) ) { vprint("Demuxing"); }
if( $inputMode eq 'lavf' ) {
    warn "lavf not handled yet";
    $videoIn = "\"$inputFile\"";
    $audioIn = "\"$inputFile\"";
} elsif( $inputMode eq 'mpegts' or $inputMode eq 'mpegps' ) {
    (my $name, my $path, my $ext) = fileparse($inputFile, ".mpg");
    if( grep( $_ eq 'demux', @phases ) ) {
        my %pids = getTsPids($inputFile);
        open(INI, "> X.ini") || die("Cannot Open File");
        print INI "SubtitlePanel.SubtitleExportFormat=SON\n" .
                  "SubtitlePanel.SubtitleExportFormat_2=null\n";
        my $cutCmd = '';
        if( $opt_mythcuts ) {
            print INI "CollectionPanel.CutMode=2\n";
            my @cuts = `mythcommflag --getcutlist -f \"$inputFile\" | grep Cut | \
                    cut -d \" \" -f 2 | sed -e 's:-:\\n:g' | sed -e 's:,:\\n:g'  \
                    2> /dev/null`;
            print @cuts;
            if( $? >> 8 ) {
                print "Failed to find file in MythTV database\n";
            } else {
                #system( "head cutlist.txt -n $((`wc -l cutlist.txt | " .
                #        "cut -d' ' -f 1`-1)) | tail -n $((`wc -l cutlist.txt" .
                #        " | cut -d' ' -f 1`-2)) > cutlist.txt" );
                open(CUT, "> cutlist.txt") || die("Cannot Open File");
                print CUT join( "\n", @cuts[1..$#cuts-1] );
                close(CUT);
                $cutCmd = "-cut cutlist.txt";
                push( @cruft, 'cutlist.txt' );
            }
        }
        close(INI);
        my $ret = system("projectx \"$path$name.mpg\" -log -ini X.ini -out . " . 
            "$cutCmd -demux -id $pids{audio},$pids{video},$pids{title} " . 
            "&> /dev/null");
        unlink("X.ini");
        if ($ret != 0) {
            warn("Failed to call ProjectX: $ret\n");
            warn("File: \"$path$name.mpg\"\n");
            exit(-1);
        }
    }
    push( @cruft, glob("*.bmp") );
    push( @cruft, ( "${name}_log.txt", "$name.spf" ) );
    push( @cruft, ( "$name.son" ) );
    push( @cruft, ( "$name.m2v", "$name.mp2" ) );
    $videoIn = "\"$name.m2v\"";
    $audioIn = "\"$name.mp2\"";
    $titleIn = "\"$name.son\"";
} elsif( $inputMode eq 'dvd' ) {
    die "dvd not handled yet";
}


# Encode subtitles
$titleFile = '';
if( grep( $_ eq 'enctitles', @phases ) ) {
    if( $subtitles ) {
        vprint( "Encoding subtitles" );
        system( "python $son2srt/son2srt.py -d $son2srt/uk_dvbsub/ -c -r 0 -s 10 -u " .
                    "-i $titleIn -o temp.srt" );
        vprint( "Encoding done" );
        $titleFile = 'temp.srt';
        push( @cruft, 'temp.srt' );
    }
}

# Encode audio
if( grep( $_ eq 'encaudio', @phases ) ) {
    vprint("Encoding audio");
    system("mkfifo audiopipe");
    if( $audioCodec eq 'ogg' ) {
        system("oggenc --quiet -q $audioQuality -o$audioFile audiopipe &");
    } elsif( $audioCodec eq 'mp3' ) {
        system("lame --quiet -V $audioQuality audiopipe $audioFile &");
    } elsif( $audioCodec eq 'aac' ) {
        $audioQuality = (10 - $audioQuality) * 50;
        warn "Quality calculation shonky for aac";
        system("faac -q $audioQuality -o $audioFile audiopipe &> /dev/null &");
    }
    system("mplayer $audioIn -hardframedrop -alang en -vc null -vo null " . 
                "-ao pcm:fast:file=audiopipe -af resample=44100 &> /dev/null");
    unlink("audiopipe");
}

# Encode video
if( grep( $_ eq 'encvideo', @phases ) ) {
    vprint("Encoding vidio");
    system( "mencoder $videoIn $filters -ovc $codec $options1 -nosound " . 
                    "-o /dev/null &> /dev/null && " .  
            "mencoder $videoIn $filters -ovc $codec $options2 -nosound " .
                    "-o $videoFile &> /dev/null" );
}



# Mux back in
if( grep( $_ eq 'mux', @phases ) ) {
    vprint("Muxing streams");
    if( $outFileExt eq '.mkv' ) {
        if( $videoCodec eq 'x264' ) {
            system( "avi2raw $videoFile $videoFile.264" );
            system( "MP4Box -fps 25 -add $videoFile.264 $videoFile.mp4" );
            if( system( "mkvmerge -o \"$outputFile\" --aspect-ratio 1:$aspect " .
                            "$videoFile.mp4 $audioFile $titleFile" ) == 2 ) {
                                die "Error muxing";
            }
            push( @cruft, ( "$videoFile.264", "$videoFile.mp4" ) );
        } else {
            if( system( "mkvmerge -o \"$outputFile\" --aspect-ratio 0:$aspect " .
                            "$videoFile $audioFile $titleFile" ) == 2 ) {
                                die "Error muxing";
            }
        }
    } elsif( $outFileExt eq '.mp4' ) {
        system( "avi2raw $videoFile $videoFile.264" );
        system( "MP4Box -fps 25 -add $videoFile.264 $audioFile \"$outputFile\"" );
    } elsif( $outFileExt eq '.ogm' ) {
        if( system( "ogmmerge -o \"$outputFile\" $videoFile $audioFile $titleFile" ) != 0 ) {
            die "Error while muxing";
        }
    } elsif( $outFileExt eq '.avi' ) {
        die( "AVI muxer not implemented" );
    }
}

# Clean up
if( grep( $_ eq 'delete', @phases ) ) {
    vprint( "Deleting" );
    unlink("$audioFile");
    unlink("$videoFile");
    unlink @cruft;
    unlink("divx2pass.log");
}

#################
#   getTsPids   #
#################
sub getTsPids {
    my $file = shift(@_);
    my %pids;
    my $VIDEO_STREAM = "0x10000002";
    my $AUDIO_STREAM = "0x50";
    my $TITLE_STREAM = "0x3000001";
    my @streams = `mplayer -v "$file" -novideo -nosound -frames 0 2>&1 | \
                            grep PARSE_PMT | grep -v "ffffffff" | sort -u`;
    foreach (@streams) {
        m/pid=(0x[\dabcdef]*) \((\d*)\), type=(0x\d*),/;
        if($3 eq $VIDEO_STREAM) {$pids{'video'} = $2;}
        if($3 eq $TITLE_STREAM) {$pids{'title'} = $2;}  
        if($3 eq $AUDIO_STREAM and (not defined($pids{'audio'}) or 
                 $2 < $pids{'audio'})) {$pids{'audio'} = $2;}
    }
    
    return %pids;
}

#####################
#   DVB encode      #
#####################

sub dvbenc
{
    system( "mencoder $inputFile $filters -ovc $codec $options1 -nosound -o /dev/null && " .  
            "mencoder $inputFile $filters -ovc $codec $options2 -nosound -o $outputFile" );
}

#####################
#   DVD encode      #
#####################

sub dvdenc
{
    my $tmpdir = "shutup";
    print "Encoding DVD.\n";
    print "Dumping video...\n";
    system( "mencoder -idx $inputFile -ovc copy -nosound -o $tmpdir/temp.avi &> /dev/null" );

    (my $hours, my $minutes, my $seconds ) = split( /:/, `avinfo $tmpdir/temp.avi | grep video | cut -d' ' -f 3`);
    
    my %Options = { s => 5 };
    my $length      = ((($hours * 60) + $minutes) * 60) + $seconds;
    my $lengthfac   = $length/($Options{'s'}+1);

    print "Video length: " . $length / 60 . " minutes\n";

    print "Rebuilding AVI index...\n";
    system( "mplayer $tmpdir/temp.avi -forceidx -ss 0:$length -novideo &> /dev/null" );

    print "CROPPING BROKEN\n";
    print "Cutting crop slices...\n";
    my @croplist;
    for(my $x=0; $x<$Options{'s'}; $x++) {
        my $seek = ($x+1)*$lengthfac;
        print $seek . "\n";
        print( "mencoder $tmpdir/temp.avi -forceidx -ss 0:$seek -endpos 0:01 -ovc copy -nosound -o $tmpdir/temp$seek.avi &> /dev/null\n" );
        system( "mencoder $tmpdir/temp.avi -forceidx -ss 0:$seek -endpos 0:01 -ovc copy -nosound -o $tmpdir/temp$seek.avi &> /dev/null" );
        $croplist[$x] = `mplayer -vf cropdetect -vo null $tmpdir/temp$seek.avi  | grep "crop area" | sed '2,\$d'`;
        print $croplist[$x];
        system( "rm $tmpdir/temp$seek.avi" );
    }

    my @tmplist;
    for(my $i=0; $i<$Options{'s'}; $i++) {
        $croplist[$i] =~ m/=(-?\d*):(-?\d*):(-?\d*):(-?\d*)/;
        print "$1 $2 $3 $4\n";
        push( @{$tmplist[0]}, $1 );
        push( @{$tmplist[1]}, $2 );
        push( @{$tmplist[2]}, $3 );
        push( @{$tmplist[3]}, $4 );
    }

    my $cropvar = (sort { $a <=> $b } @{$tmplist[0]})[$Options{'s'}/2+1] . ":" . (sort { $a <=> $b } @{$tmplist[1]})[$Options{'s'}/2+1] . ":" . (sort { $a <=> $b } @{$tmplist[2]})[$Options{'s'}/2+1] . ":" . (sort { $a <=> $b } @{$tmplist[3]})[$Options{'s'}/2+1];
    print "Crop dimensions: $cropvar\n";

    print "AUDIO RIPPING BROKEN!!\n";
    print "Grabbing audio...\n";
    system( "mkfifo $tmpdir/audiopipe" );
    system( "oggenc --quiet -q$audioCodec -o$tmpdir/audio.ogg $tmpdir/audiopipe &" );
    system( "mplayer $inputFile -hardframedrop -alang en -vc dummy -vo null -ao pcm -af volume=10db,resample=44100 -ao pcm:file=$tmpdir/audiopipe &> /dev/null" );
    system( "rm -f $tmpdir/audiopipe");
    print "Audio obtained.\n";

    print "Beginning first video pass...";
#   Requires either to be scaled to the right aspect (more portable)
#   or force-avi-aspect (mplayer only)
    system( "mencoder $tmpdir/temp.avi -vf pp=lb,scale=$videoWidth:$videoHeight,harddup -ovc lavc -lavcopts vcodec=mpeg4:trell:v4mv:mbd=2:vbitrate=$videoQuality:vpass=1:turbo -nosound -o /dev/null" ); 
    print "Beginning second video pass...";
    system( "mencoder $tmpdir/temp.avi -vf pp=lb,scale=$videoWidth:$videoHeight,harddup -ovc lavc -lavcopts vcodec=mpeg4:trell:v4mv:mbd=2:vbitrate=$videoQuality:vpass=2 -nosound -o $tmpdir/video.avi" );
    print "Merging A/V data...";
    system( "ogmmerge -o $outputFile $tmpdir/video.avi $tmpdir/audio.ogg");


#system( "rm $tmpdir/temp.avi $tmpdir/video.avi $tmpdir/audio.ogg -f" );@
    print "Rip complete.\n"
}

#####################
#   generic encode  #
#####################

sub videnc
{

}


sub vprint {
    return unless (defined($verbose));
    print join("\n", @_), "\n";
}

