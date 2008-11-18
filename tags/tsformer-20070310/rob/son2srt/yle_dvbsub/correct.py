#!/usr/bin/python
# -*- coding: iso8859-1 -*-

import re

# son2srt correction filter
#
# Niko Mikkilä <mikkila at cs helsinki fi>
# Public Domain.
#
# Corrects usual gocr errors caused mostly by italic fonts.
# This needs to be edited for custom symbol databases and different languages.
#
# For finnish YLE DVB subtitles and gocr 0.40.
#
def correct(text):
    # Move single comma in a line to the end of the next one.
    text = re.sub(r"(^|\n),\n(.+)\n", r"\1\2,\n", text)

    # remove lines with only one character
    text = re.sub(r"^.\n", "", text)
    text = re.sub(r"\n.\n", "\n", text)

    # b. -> ö within words
    text = re.sub(r"b[.](\s*[a-zåäö])", r"ö\1", text)
    # run twice
    text = re.sub(r"b[.](\s*[a-zåäö])", r"ö\1", text)

    # remove periods within words
    text = re.sub(r"([A-ZÅÄÖa-zåäö])[.]([a-zåäö])", r"\1\2", text)
    # run twice to handle cases like "a.a.a"
    text = re.sub(r"([A-ZÅÄÖa-zåäö])[.]([a-zåäö])", r"\1\2", text)

    # , -> ' within words
    text = re.sub(r"([A-ZÅÄÖa-zåäö])[,]([a-zåäö])", r"\1'\2", text)

    # ! -> l withing words
    text = re.sub(r"([A-ZÅÄÖa-zåäö])[!]([A-ZÅÄÖa-zåäö])", r"\1l\2", text)

    # ä. -> ä and ö. -> ö in some cases
    text = re.sub(r"([äö])\.([,!?]|\.\.\.|\.[^.!?]|\s+[a-zåäö])", r"\1\2", text)
    # run twice
    text = re.sub(r"([äö])\.([,!?]|\s+[a-zåäö])", r"\1\2", text)

    # ,. -> ?
    text = text.replace(",.", "?");

    # '' -> "
    text = text.replace("''", '"');

    # l. -> !
    text = re.sub(r"l\.(\s)", r'!\1', text)

    # .l -> !
    text = re.sub(r"\.l(\s)", r'!\1', text)

    # ?. -> ?
    text = text.replace("?.", "?");

    # ? " -> ?"
    text = re.sub(r"\? \"([ \n]|$)", r'?"\1', text)

    # ?l -> i
    text = text.replace("?l", "i");

    # l? -> i (some cases)
    text = re.sub(r"l[?]([a-zåäö])", r"i\1", text)

    # l -> ! in the end
    text = re.sub(r"l(\s*)$", r"!\1", text)

    # .. -> :
    text = re.sub(r"([^.])\.\.([^.?!])", r"\1:\2", text)

    # l -> I (some cases)
    text = re.sub(r"([A-ZÅÄÖ])ll([A-ZÅÄÖ])", r"\1II\2", text)
    text = re.sub(r"([A-ZÅÄÖ]{2})l", r"\1I", text)
    text = re.sub(r"l([A-ZÅÄÖ])", r"I\1", text)
    text = re.sub(r"(^|\s|[\"-])l([bcdfghjklmnpqrstvwxz])", r"\1I\2", text)
    text = re.sub(r"([A-ZÅÄÖ])l([A-ZÅÄÖ])", r"\1I\2", text)
    # run twice to handle cases like AlAlA
    text = re.sub(r"([A-ZÅÄÖ])l([A-ZÅÄÖ])", r"\1I\2", text)

    return text

