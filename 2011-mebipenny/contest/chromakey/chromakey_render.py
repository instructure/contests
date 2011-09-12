#!/usr/bin/env python

import sys
from PIL import Image

width = int(sys.stdin.readline().strip())
height = int(sys.stdin.readline().strip())

image1 = [map(int, sys.stdin.readline().strip().split()) for _ in xrange(width*height)]
image2 = [map(int, sys.stdin.readline().strip().split()) for _ in xrange(width*height)]

im = Image.new("RGB", (width, height))
pix = im.load()

pixels = []
for pixel1, pixel2 in zip(image1, image2):
  if pixel1[1] > pixel1[0] + pixel1[2]: pixels.append(pixel2)
  else: pixels.append(pixel1)

for x in xrange(width):
  for y in xrange(height):
    pixel = tuple(pixels.pop(0))
    pix[x,y] = pixel
    print " ".join(map(str, pixel))

im.show()
