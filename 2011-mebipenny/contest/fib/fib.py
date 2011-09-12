#!/usr/bin/env python

import sys, re

def int_stream(datastream):
  whitespace = re.compile(r'\s+')
  for line in datastream:
    chunks = whitespace.split(line)
    for chunk in chunks:
      if not chunk: continue
      yield int(chunk)

def fib_count(a, b):
  count = 0
  counted_1_already = False
  x, y = 0, 1
  while True:
    if x >= a and x <= b:
      if x == 1:
        if not counted_1_already:
          count += 1
          counted_1_already = True
      else:
        count += 1
    elif x > b: break
    x, y = y, x + y
  return count

def main(argv):
  ints = int_stream(sys.stdin)
  for _ in xrange(ints.next()):
    print fib_count(ints.next(), ints.next())

main(sys.argv)
