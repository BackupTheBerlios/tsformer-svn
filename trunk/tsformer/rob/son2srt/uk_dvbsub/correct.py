#!/usr/bin/python
# -*- coding: iso8859-1 -*-

import re

# son2srt correction filter
#
# Robin Neatherway <robthebob at gmail com>
# Public Domain.
#
# For UK DVB subtitles and gocr 0.40.
#
def correct(text):
    # remove lines with only one character
    text = re.sub(r"^.\n", "", text)
    text = re.sub(r"\n.\n", "\n", text)

    # '' -> "
    text = text.replace("''", '"')

    # ?. -> ?
    text = text.replace("?.", "?")
    
    # !. -> !
    text = text.replace("!.", "!")

    # l -> I
    #text = text.replace(" l ", " I " )

    # lower case 'c' -> upper case 'C'
    # if followed by upper case
    #text = re.sub(r"c([A-Z])", r"C\1", text)
    # any end of sentence followed by a 'c'
    #text = re.sub(r"([^\.]\.\s+)c", r"\1C", text)
    # first letter in the subtitle
    #text = re.sub(r"^c", r"C", text)

    return text

