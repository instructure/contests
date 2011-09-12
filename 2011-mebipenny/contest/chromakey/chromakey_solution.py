#!/usr/bin/env python

import sys

width = int(sys.stdin.readline().strip())
height = int(sys.stdin.readline().strip())

image1 = [map(int, sys.stdin.readline().strip().split()) for _ in xrange(width*height)]
image2 = [sys.stdin.readline().strip() for _ in xrange(width*height)]

for pixel1, pixel2 in zip(image1, image2):
  if pixel1[1] > pixel1[0] + pixel1[2]:
    print pixel2
  else:
    print " ".join(map(str, pixel1))
