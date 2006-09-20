#!/usr/bin/python
# -*- coding: iso8859-1 -*-

"""
son2srt 1.1
-----------
Niko Mikkilä <mikkila at cs helsinki fi>
Public Domain

This script converts .son (DVDMaestro) bitmap subtitles to the text-based .srt
format. It can be used to process subtitle files generated with the ProjectX
DVB demuxing tool. With a good symbol database the number of errors can easily
be under 10 in a two-hour movie. However, corrupted subtitle images will cause
problems.

son2srt is currently not suitable for DVD subtitle conversion because subtitle
fonts are not universal. Building a symbol database for each disc would be a
tedious job without a good GUI (and frustrating even then). However, DVB
broadcasters (YLE in Finland) have only one font, which son2srt can handle
non-interactively with a complete symbol database.

Requires gocr 0.40 and the netpbm tools. See the source code for more details.

Usage: son2srt.py [-v] [-d path [-a] [-c]] [-s px] [-r px] [-u] -i sub.son -o sub.srt
Where:
        -d path     Set gocr to use a database instead of built-in recognition.
                    Path is the database directory. This allows one to use a
                    prebuilt database in a specific location or specify path
                    for a new database. Highly recommended!

        -a          Build a new database or add data to an existing one. The
                    user will be prompted for new symbols. This is not needed
                    for normal operation.

        -c          Correct usual mistakes made by gocr. These include
                    recognizing <!> as <l.>, <?> as <?.>, <"> as <''>, lines
                    with only one symbol and commas within words. Because the
                    filter rules depend on subtitle font and language, they
                    should be in file correct.py in the database directory.
                    Recommended.

        -s <px>     Space width. Autodetected by default. 9 works best for me
                    on YLE DVB subtitles, but it depends on the subtitle font.

        -r <px>     Minimum number of empty pixel rows between lines of text.
                    This prevents gocr from mixing symbols on different lines.
                    Default value 4, set to 0 to disable line splitting and
                    let gocr handle it.

        -i sub.son  The input SON file.

        -o sub.srt  Output SRT.

        -u          Convert UK DVB colours to white on black text.

        -v          Print status and data to standard output.

        -h, --help  Show this information.

Example: python son2srt.py -d yle_dvbsub -c -s 9 -r 4 -i sub.son -o sub.srt

"""


"""
Notes:

Gocr seems to work poorly on subtitles by default, but this can be fixed by
building a custom symbol database. Create a complete database for the subtitle
font with -d and -a parameters.  Gocr will prompt for new symbols, so just
answer the questions patiently. After the database is (mostly) complete, you
can use it for other tasks non-interactively by omitting the -a parameter.
Gocr may be slow with a large database, but it recognizes most characters and
even italic fonts very well.

In sans-serif fonts "l" and "I" are usually almost exacly the same, in which
case you'll be best off using "l" if gocr asks for the "I" symbol first.
The letters can be mostly corrected later with a simple filter.

Recent CVS version (July 2005) of gocr finds better matches for some symbols
than version 0.40, but it doesn't seem to care about the -s parameter at all.
Hopefully it will be fixed in version 0.41.

"""

#### CONFIGURATION ############################################################

#_GOCR_ = "/home/rn114/jocr/bin/gocr"
_GOCR_ = "gocr"
_db_ = False
_dbdir_ = "./db/"
_builddb_ = False
_space_width_ = 0

_CORRECTION_MODULE_ = "correct"

# Should we run the gocr output through a correction filter?
# The filter rules should be in file _CORRECTION_MODULE_ in the database
# directory. Function correct(text) will be called from that file.
_correction_ = False
_correct_ = None

# Default directory for the bmp files.
# This will be set to the same path as the .son file.
_sondir_ = "./"

# Clean up the inverted bitmap files that were fed to gocr.
_REMOVE_PBMS_ = False

# Split lines before feeding them to the OCR engine. This variable specifies
# the minimum number of empty pixel rows between the text lines.
_split_rows_ = 4

# Tried to calibrate space recognition with a sample line for gocr CVS version.
# Doesn't work since each line is recognized separately.
# _calibration_ = False
# _CALIBRATION_IMAGE_ = "calib.pbm"

# Whether or not processing a UK broadcast containing different colours
# within a single image that should be flattened to greys for optimal OCR.
# Green, turquoise and yellow foreground text, along with white text on a
# red background are all converted to white text on a black background.
_uk_colours_ = False

##############################################################################


import sys
import getopt
import os
import re
import commands
import colorsys
import pdb
import shutil

# Handles one .son line
def convertline(line):
    # parse .son times and the bmp file name
    pattern = re.compile(r"^(\d+)\s+(\d{2}):(\d{2}):(\d{2}):(\d{2})\s+(\d{2}):(\d{2}):(\d{2}):(\d{2})\s+(.+)$")
    match = pattern.search(line)
    if match:
        start = match.group(2) + ":" + match.group(3) + ":" + match.group(4) + \
            "," + match.group(5) + "0"
        end = match.group(6) + ":" + match.group(7) + ":" + match.group(8) + \
            "," + match.group(9) + "0"
        bmpfile = _sondir_ + match.group(10)
        
        if (_uk_colours_):
            text = ""
            findcolours = re.compile(r"^  00([\da-f]{2})  00([\da-f]{2})  00([\da-f]{2})")
            ret = os.system("bmptoppm \"" + bmpfile + "\" 2> /dev/null | " + \
                "ppmchange \#000060 \#000000 \#1f1f1f \#000000 > \"" + bmpfile + ".ppm\"")
            ret, height = commands.getstatusoutput("pamfile \"" + bmpfile + ".ppm\"")
            if (ret != 0):
                print "\nError checking subpicture dimensions. Make sure you have netpbm tools installed.\n"
                sys.exit(0)
            height = int(height.split("\t")[1].split(" ")[4])
            factor = 0
            for x in range(30,40,2):
                if (height % x == 0):
                    height /= x
                    factor = x
                    break
            if (height > 10):
                height = 1
            for i in range(height):
                if (factor):
                    ret = os.system("pnmcut -left 0 -right -1 -top " + str(i*factor) + \
                        " -bottom " + str((i+1)*factor-1) + " \"" + bmpfile + ".ppm\"" + \
                        " 2> /dev/null > \"" + bmpfile + ".line.ppm\"")
                    if (ret != 0):
                        print "\nError cutting ppm image. Make sure you have netpbm tools installed.\n"
                        sys.exit(0)
                    words = splitwords(bmpfile + ".line.ppm")
                else:
                    pdb.set_trace()
                    words = [ (0, -1) ]
                    shutil.copyfile(bmpfile + ".ppm", bmpfile + ".line.ppm" )
                for word in words:
                    ret = os.system("pnmcut -left " + str(word[0]) + " -right " + str(word[1]) + \
                        " -top 0 -bottom -1 \"" + bmpfile + ".line.ppm\" 2> /dev/null | pnminvert | ppmdist | " + \
                        "pgmtopbm -threshold -value 0.5 > \"" + bmpfile + str(word[0]) + ".words.pbm\"")
                    if (ret != 0):
                        print "\nError cutting ppm image. Make sure you have netpbm tools installed.\n"
                        sys.exit(0)
                    text = text + ocr(bmpfile + str(word[0]) + ".words.pbm")
                    os.remove(bmpfile + str(word[0]) + ".words.pbm")
                os.remove(bmpfile + ".line.ppm")
            os.remove(bmpfile + ".ppm")
            if _correction_ and (_correct_ != None):
                text = _correct_(text)
            return start + " --> " + end + "\n" + text
        else:
        	# invert the text colors
        	ret = os.system("bmptoppm \"" + bmpfile + "\" 2> /dev/null | " + \
            	"pnminvert | ppmtopgm | pgmtopbm -threshold  -value 0.5  > \"" + \
            	bmpfile + ".pbm\"")
        if ret != 0:
            print "\nError converting bmp to pbm. Make sure you have netpbm tools installed.\n"
            sys.exit(0)

        # separate lines of text
        if (_split_rows_ > 0):
        	splits = splitrows(bmpfile + ".pbm")
        text = ""
        if (_split_rows_ > 0) and (len(splits) > 0):
            y1 = 0
            for i in range(len(splits)+1):
                if i == len(splits):
                    y2 = -1
                else:
                    y2 = splits[i]
                ret = os.system("pnmcut -left 0 -right -1 -top " + str(y1) + \
                    " -bottom " + str(y2 - 1) + " \"" + bmpfile + ".pbm\"" + \
                    " 2> /dev/null > \"" + bmpfile + ".line.pbm\"")
                if ret != 0:
                    print "\nError cutting pbm image. Make sure you have netpbm tools installed.\n"
                    sys.exit(0)
                #if i > 0:
                #    text += "\n"
                text = text + ocr(bmpfile + ".line.pbm")
                os.remove(bmpfile + ".line.pbm")
                y1 = y2
        else:
            text = ocr(bmpfile + ".pbm")

        if _REMOVE_PBMS_:
            os.remove(bmpfile + ".pbm")

        # run the correction filter if needed
        if _correction_ and (_correct_ != None):
            text = _correct_(text)

        return start + " --> " + end + "\n" + text
    else:
        return None


def ocr(file):
    # These don't seem to have much of an effect with a symbol database
    # ocrparam = 4 + 64
    ocrparam = 0
    if _db_:
        if not os.access(_dbdir_, os.F_OK):
            os.mkdir(_dbdir_)
        ocrparam += 2 + 256 + 8 + 16 + 32
        #ocrparam += 2
    if _builddb_:
        ocrparam += 128

    ret = os.system(_GOCR_ + " -m " + str(ocrparam) + " -s " + \
        str(_space_width_) + " -p \"" + _dbdir_ + "/\" -i \"" + \
        file + "\" -o \"" + file + ".txt\"")
    if ret != 0:
        print "\nError running OCR. Make sure you have gocr installed.\n"
        sys.exit(0)
    text = ""
    try:
        textfile = open(file + ".txt", "r")
        text = textfile.read()
        textfile.close()
        os.remove(file + ".txt")
    except:
        print "\nWarning: unable to read OCR results from " + file + ".txt\n"
    return text

def splitwords(ppmfile):
    splits = []
    data = ""
    try:
        f = open(ppmfile)
        if f.read(2) != "P6":
            f.close()
            return splits
        data = f.read() 
        f.close()
    except:
        print "Warning: unable to read file " + ppmfile
    p = re.compile(r"\n\s*(\d+)\s+(\d+)\s+(\d+)\s(.+)$")
    match = p.search(data)
    if not match:
        print "Warning: corrupted image"
        return splits
    width = 0
    height = 0
    maxval = 0
    try:
        width = int(match.group(1))
        height = int(match.group(2))
        maxval = int(match.group(3))
    except:
        print "Warning: corrupted image"
        return splits
    if (maxval > 255):
        print "Warning: colour depth greater than one byte"
        return splits
    image = match.group(4)
    for y in range(height):
        pos = y * width * 3
        row = image[pos:pos+width*3]
        currentcolour = -1
        lastcolour = -1
        colourindex = -1
        rowsplits = []
        for x in range(width):
            H,S,V = colorsys.rgb_to_hsv(float(ord(row[x*3]))/255,  
                                        float(ord(row[x*3+1]))/255,  
                                        float(ord(row[x*3+2]))/255)
            if (H==0 and S==0 and V==0): #background colour
                H = -1
                if (lastcolour != -1): #colour to background
                    rowsplits[colourindex] = (rowsplits[colourindex][0],x)
            elif (abs(H-currentcolour) > 0.02 and lastcolour == -1): #colour change (must be bg to fg)
                colourindex += 1
                rowsplits.append((x-1, 0))
                currentcolour = H
            elif (abs(H-currentcolour) > 0.02):
                print ("Warning: corrupted image (two non-background colours consecutively in image " +
                        ppmfile + ", on line " + str(y) + ", pixel " + str(x))
                return []
            lastcolour = H
        pos = 0
        rowpos = 0
        while (pos != -1 and len(rowsplits) != 0):
            if(pos == len(splits)):
                splits = splits + rowsplits[rowpos:]
                pos = -1
            elif(rowpos == len(rowsplits)):
                pos = -1
            else:
                if(rowsplits[rowpos][0] > splits[pos][1]):
                    pos += 1
                elif(rowsplits[rowpos][1] < splits[pos][0]):
                    splits.insert(pos, rowsplits[rowpos])
                else:
                    splits[pos] = min(splits[pos][0], rowsplits[rowpos][0]), \
                                  max(splits[pos][1], rowsplits[rowpos][1])
                    pos, rowpos = pos+1, rowpos+1
    return splits
    

# Return a list of rows at which the given PBM image should be split
# to cut the subtitle lines to separate images.
def splitrows(pbmfile):
    splits = []
    data = ""
    try:
        f = open(pbmfile)
        if f.read(2) != "P4":
            f.close()
            return splits
        data = f.read() 
        f.close()
    except:
        print "Warning: unable to read file " + pbmfile
    p = re.compile(r"\n\s*(\d+)\s+(\d+)\s(.+)$")
    match = p.search(data)
    if not match:
        print "Warning: corrupted image"
        return splits
    width = 0
    height = 0
    try:
        width = int(match.group(1))
        height = int(match.group(2))
    except:
        print "Warning: corrupted image"
        return splits
    image = match.group(3)
    bytesperrow = width / 8
    lastbits = width % 8
    if lastbits > 0:
        bytesperrow += 1
    cleanrows = 0
    for y in range(height):
        pos = y * bytesperrow
        row = image[pos:pos+bytesperrow]
        clean = True
        for x in range(width / 8):
            if ord(row[x]) != 0:
                clean = False
                break
        # Check last bits
        if clean and (lastbits > 0):
            byte = ord(row[bytesperrow-1])
            for shift in range(lastbits):
                b = 128 >> shift
                if byte & b:
                    clean = False
                    break
        if clean:
            cleanrows += 1
        else:
            if cleanrows >= _split_rows_ and (y - (cleanrows / 2)) > 8 and ((height - y) - (cleanrows / 2)) > 8:
                # Split at the center of the clean area
                splits.append(y - (cleanrows / 2))
            cleanrows = 0
    return splits


def main():
    # parse command line options
    try:
        opts, args = getopt.getopt(sys.argv[1:], "hvd:acs:r:i:o:u", ["help"])
    except getopt.error, msg:
        print msg
        print "Parameter --help prints usage information."
        sys.exit(2)

    input = ""
    output = ""
    verbose = False

    global _db_
    global _dbdir_
    global _builddb_
    global _correction_
    global _correct_
    global _space_width_
    global _split_rows_
    global _uk_colours_

    # process options
    for o, a in opts:
        if o in ("-h", "--help"):
            print __doc__
            sys.exit(0)
        if o in ("-d"):
            _db_ = True
            _dbdir_ = a + "/"
        if o in ("-a"):
            _builddb_ = True
        if o in ("-c"):
            _correction_ = True
        if o in ("-s"):
            _space_width_ = a
        if o in ("-r"):
            _split_rows_ = int(a)
        if o in ("-i"):
            input = a
        if o in ("-o"):
            output = a
        if o in ("-u"):
        	_uk_colours_ = True
        if o in ("-v"):
            verbose = True

    if _correction_:
        if _db_:
            sys.path.append(_dbdir_)
            try:
                mod = __import__(_CORRECTION_MODULE_, globals(), locals(), \
                    ["correct"])
                _correct_ = getattr(mod, "correct")
            except:
                print "Error: Unable to load correction filter " + \
                    _dbdir_ + _CORRECTION_MODULE_ + ".py"
                sys.exit(2)
        else:
            print "Error: Unable to load correction filter because no symbol database was defined."
            sys.exit(2)

    global _sondir_
    _sondir_ = os.path.dirname(input) + "/"
    print os.path.dirname(input)
    
    if(_sondir_ == "/"):
        _sondir_ = "./"

    if (len(input) > 0) and (len(output) > 0):
        try:
            sonfile = open(input, "r")
            srtfile = open(output, "w")
            line = sonfile.readline()
            i = 1
            if verbose:
                print ""
                print "-------------------------------------------------------------------------------"
            while len(line) > 0:
                line = sonfile.readline()
                words = line.split()
                #if (len(words) > 1) and (words[0] == "Directory"):
                #    global _sondir_
                #    _sondir_ = words[1] + "/"
                text = convertline(line)
                if text:
                    if verbose:
                        print line
                        print str(i) + "\n" + text
                        print "-------------------------------------------------------------------------------"
                    srtfile.write(str(i) + "\n" + text + "\n")
                    i += 1
        except IOError, (errno, strerror):
            print "Error: " + strerror
            sys.exit(2)
    else:
        print "Failed to parse parameters. Try --help."


if __name__ == "__main__":
    main()

