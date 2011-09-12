#!/usr/bin/env python

import random

size_range = (300, 400)
mine_probability = 25
width = random.randint(*size_range)
height = random.randint(*size_range)
mines = []
for y in xrange(height):
  for x in xrange(width):
    if random.randint(0,100) <= mine_probability:
      mines.append((x,y))
print width, height, len(mines)
for x, y in mines:
  print x, y
