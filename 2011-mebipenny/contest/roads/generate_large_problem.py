#!/usr/bin/env python

import random
countries = 1#random.randint(1, 50)
print countries
for _ in xrange(countries):
  cities = random.randint(100,110)
  roads = random.randint(500,600)
  roads_done = {}
  print random.randint(0,1000)
  print cities
  print roads
  for _ in xrange(roads):
    road_path = None
    while not road_path:
      source = random.randint(1, cities)
      dest = random.randint(1, cities)
      if roads_done.has_key((source, dest)): continue
      road_path = (source, dest)
      roads_done[road_path] = True
    print road_path[0], road_path[1], random.randint(0,100), random.randint(0,100)
