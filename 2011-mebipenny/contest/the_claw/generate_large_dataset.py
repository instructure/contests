#!/usr/bin/env python

import random
point_range = (40000,42500)
x_range = (-100000, 100000)
y_range = (-100000, 100000)

chickens = random.randint(*point_range)
goats = random.randint(*point_range)
ids = range(chickens+goats)
random.shuffle(ids)

print chickens, goats

for _ in xrange(chickens+goats):
  print ids.pop(), random.randint(*x_range), random.randint(*y_range)
