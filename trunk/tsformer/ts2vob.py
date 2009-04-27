#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import getopt
import re

VERSION = '2.0.0_rc'


def info():
  print "TS2VOB - transport stream to vob converter, with support for DVB subtitles."
  print "This is free software; version " + VERSION
  print

def usage():
  print "Usage:"
  print '  ts2vob -i "input file.ts" -o "output filename"'
  print
  print "If the input file is already demuxed, as you might have cut it with the projectx GUI,"
  print "the script looks for the demuxed files in the same directory as the input file."
  print "If -o defines a directory, it will be used to store temporary files."
  print
  print "The subtitles have to be in .sup format. If they exist in the .ts, they will be merged into the .vob."
  print


class TsHandler:
  def __init__(self,input_file):
    self.input_file = input_file

    """ output mode (for tcmplex-panteltje)
                    1 = mpeg1 vbr, buffer 46kb (*** default XVCD).
                    b = mpeg1 vbr, buffer 224kb (experimental).
                    2 = mpeg2 vbr.
                    d = DVD.
                    s = SVCD.
                    v = VCD.
    """
    self.mode = 'd'

    # the location of X.ini
    self.Xini = '/'.join([os.getcwd(),'X.ini'])

    # get the suffix
    m = re.search(r'\.([^.]*)$', input_file)
    if m is None:
      self.suffix = None
      self.warn_msg('File suffix could not be detected')
    else:
      self.suffix = m.group(1)

    # is the input file relative or absolute
    m = re.search(r'^\/', input_file)
    if m is None:
      self.input_file = '/'.join([os.getcwd(), input_file])
    else:
      self.input_file = input_file

    # extract the filename without the suffix
    m = re.search(r'^(.*)\.%s' % self.suffix, os.path.basename(input_file))
    self.filename = m.group(1)

    # working directory
    self.workdir = os.path.dirname(self.input_file)

    # output directory = input file's
    self.output_dir = os.path.dirname(self.input_file)

    # temporary demux basename
    # -- follows projectX char replacements
    self.demux_basename = '/'.join([
      self.workdir,
      re.sub(r'\:', '_', self.filename)])

    # final output file
    self.output_file = '/'.join([
      self.output_dir,
      self.filename+'.vob'])

    self.trash = None
    self.logfile = None


  def info_msg(self,msg):
    print '  [OK] %s' % (msg)

  def warn_msg(self,msg):
    print '  [WW] %s' % (msg)

  def err_msg(self,msg):
    print '  [!!] %s' % (msg)


  def demux(self):
    """ Demux
        deduces if the input file has already been demuxed,
        or demuxes it with projectX
    """
    if os.path.exists(self.demux_basename+'.m2v'):
      self.info_msg('Input has already been demuxed')
      return None

    self.info_msg('Demuxing input to %s' % self.workdir)
    # DEMUX TO .M2V  .MP2  .SUP ###################

    #$(java-config -J) -Xms32m -Xmx512m -cp $(java-config -p projectx,jakarta-oro-2.0,commons-net) \
    #net.sourceforge.dvb.projectx.common.Start -ini "${LIBDIR}/X.ini" -out "${WORKDIR}" -name "${OUTPUT}" "${INPUT}";
    cmd = 'projectx -ini "%s" -out "%s" -name "%s" "%s"' % (
      self.Xini, self.workdir, self.filename, self.input_file)

    # check X.ini
    if not os.path.exists(self.Xini):
      self.err_msg('X.ini for ProjectX is not found in "%s"' % self.Xini)
      sys.exit(1)

    os.system(cmd)
    self.info_msg('Demuxed')
    return None


  def multiplex(self):
    """ Multiplex to VOB.

    Uses tcmplex-panteltje, which is a bit esoteric program, but when
    the initial bash version of this program was created in early 2006,
    this produced the best quality output (was in sync) of all programs
    I tried.

    """
    self.info_msg('Muxing input to "%s"' % self.output_file)

    #tcmplex-panteltje -i "${DEMUXED}.m2v" -p "${DEMUXED}.mp2" \
    #-m d -d $VERBOSITY -o "${WORKDIR}/${OUTPUT}.vob" 2>&1 | grep '^\*'  &> ${LOGFILE}
    cmd = 'tcmplex-panteltje -i "%s" -p "%s" -o "%s" -m %s -d %i' % (
      self.demux_basename+'.m2v',
      self.demux_basename+'.mp2',
      self.output_file,
      self.mode,
      1 # verbosity
    )
    os.system(cmd)
    return None


  def process_subtitles(self):
    """ Process subtitles, if they exist """
    None

  def clean(self):
    """ Cleanup """
    None

  def go(self):
    """ starts the process """
    self.info_msg('Input file: %s' % (self.input_file))

    self.demux()

    self.multiplex()

    self.process_subtitles()

    self.clean()


def check_dependencies():
  return True


def main(argv):
  info()
  try:
    opts, args = getopt.getopt(argv, "hi:o:v",["help","input=","output=","verbose"])
  except getopt.GetoptError:
    usage()
    sys.exit(2)

  _input = _output = None
  _verbose = 0

  for opt, arg in opts:
    if opt in ("-h", "--help"):
      usage()
      sys.exit(0)

    elif opt in ("-i", "--input"):
      _input = arg

    elif opt in ("-o", "--output"):
      _output = arg

    elif opt in ("-v", "--verbose"):
      _verbose = 1

  source = "".join(args) # rest of the arguments
  if _input is None:
    usage()
    sys.exit(1)

  handler = TsHandler(_input)
  handler.go()


if __name__ == "__main__":
  main(sys.argv[1:])