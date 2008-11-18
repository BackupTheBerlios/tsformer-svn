#!/usr/bin/env python

import sys
import getopt

VERSION = '0.2.0'

def info():
  print "TS2VOB - transport stream to vob converter, with support for DVB subtitles."
  print "This is free software; version " + VERSION


def usage():
  print "usage:"


def main(argv):
  info()
  try:
    opts, args = getopt.getopt(argv, "hi:o:v",["help","input=","output=","verbose"])
  except getopt.GetoptError:
    usage()
    sys.exit(2)

  for opt, arg in opts:
    if opt in ("-h", "--help"):
      usage()
      sys.exit()

    elif opt in ("-i", "--input"):
      _input = arg

    elif opt in ("-o", "--output"):
      _output = arg

    elif opt in ("-v", "--verbose"):
      _verbose = 1

  source = "".join(args) # rest of the arguments
  #print source

  #print _input


if __name__ == "__main__":
  main(sys.argv[1:])