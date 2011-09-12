#!/usr/bin/env python

import random
levels = 250
caves_per_level = 33
capacity_range = (1, 500)

print caves_per_level * (levels + 1) + 2
print (caves_per_level * 2 - 1) * levels + (caves_per_level * 2)

for cave in xrange(caves_per_level):
  print 1, cave + 2, random.randint(*capacity_range)
for level in xrange(levels):
  for cave in xrange(caves_per_level):
    cave_id = level * caves_per_level + cave + 2
    if cave != 0:
      print cave_id, cave_id + caves_per_level - 1, \
          random.randint(*capacity_range)
    print cave_id, cave_id + caves_per_level, random.randint(*capacity_range)

for cave in xrange(caves_per_level):
  cave_id = levels * caves_per_level + cave + 2
  print cave_id, (levels + 1) * caves_per_level + 2, \
      random.randint(*capacity_range)
