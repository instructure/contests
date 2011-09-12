#!/usr/bin/env python

import sys, re
from collections import defaultdict

def initialize(graph, source):
  d = {}
  p = {}
  for node in graph:
    d[node] = float('Inf')
    p[node] = None
  d[source] = 0
  return d, p

def relax(u, v, graph, d, p):
  if d[v] > d[u] + graph[u][v]:
    d[v]  = d[u] + graph[u][v]
    p[v] = u

def negative_cycle(graph, source):
  d, p = initialize(graph, source)
  for i in range(len(graph)-1):
    for u in graph:
      for v in graph[u]:
        relax(u, v, graph, d, p)
  for u in graph:
    for v in graph[u]:
      if d[v] > d[u] + graph[u][v]: return True
  return False

def int_stream(datastream):
  whitespace = re.compile(r'\s+')
  for line in datastream:
    chunks = whitespace.split(line)
    for chunk in chunks:
      if not chunk: continue
      yield int(chunk)

ints = int_stream(sys.stdin)
universes = ints.next()
for _ in xrange(universes):
  galaxies = ints.next()
  wormholes = ints.next()
  graph = {}
  for g in xrange(galaxies): graph[g+1] = {}
  for _ in xrange(wormholes):
    a, b, t = ints.next(), ints.next(), ints.next()
    graph[a][b] = t

  if negative_cycle(graph, 1):
    print "Y"
  else:
    print "N"
