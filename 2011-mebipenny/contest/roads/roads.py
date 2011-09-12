#!/usr/bin/env python

import itertools
from heapq import heappush, heappop, heapify

class priority_queue(object):
  def __init__(self, initial_things=[]):
    self.id_gen = itertools.count(1)
    self.pq = [[priority, next(self.id_gen), thing, True]
                for thing, priority in initial_things]
    self.thing_finder = {}
    for entry in self.pq: self.thing_finder[entry[2]] = entry
    heapify(self.pq)
  def add(self, thing, priority):
    old_entry = self.thing_finder.get(thing, [0, 0, 0, False])
    old_entry[3] = False
    entry = [priority, next(self.id_gen), thing, True]
    self.thing_finder[thing] = entry
    heappush(self.pq, entry)
  def pop(self):
    while self.pq:
      priority, id_, thing, valid = heappop(self.pq)
      if self.thing_finder.has_key(thing): del self.thing_finder[thing]
      if valid: return thing, priority
    return None, None
  def delete(self, thing):
    entry = self.thing_finder[thing]
    entry[3] = False
  def has(self, thing): return self.thing_finder.has_key(thing)
  def get(self, thing): return self.thing_finder[thing][0]

def modified_dijkstra(graph, source, target, initial_wallet):
  D, P, Q = {}, {}, priority_queue([((source, initial_wallet), 0)])
  while True:
    v, D[v] = Q.pop()
    if v is None: return -1
    if v[0] == target: return D[v]
    for w in graph[v[0]]:
      w = (w, v[1] - graph[v[0]][w][1])
      if w[1] < 0: continue
      dist = D[v] + graph[v[0]][w[0]][0]
      if w in D: assert dist >= D[w]
      elif not Q.has(w) or dist < Q.get(w):
        Q.add(w, dist)
        P[w] = v

import sys

countries = int(sys.stdin.readline().strip())
for _ in xrange(countries):
  initial_wallet = int(sys.stdin.readline().strip())
  city_count = int(sys.stdin.readline().strip())
  road_count = int(sys.stdin.readline().strip())
  source = 1
  target = city_count

  graph = dict((x, {}) for x in xrange(1, city_count + 1))
  for _ in xrange(road_count):
    a, b, dist, cost = map(int, sys.stdin.readline().strip().split())
    if a == b: continue
    graph[a][b] = (dist, cost)

  print modified_dijkstra(graph, source, target, initial_wallet)
