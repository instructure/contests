#!/usr/bin/env python

def output(char):
  if ord('a') > ord(char.lower()) or ord('z') < ord(char.lower()): return ""
  return ("%x" % (ord(char[0].lower()) - ord('a') + 1)).upper()

import sys; print "".join(map(output, sys.stdin.read()))
