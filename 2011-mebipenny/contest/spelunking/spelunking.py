#!/usr/bin/env python

import sys, re, random
from collections import defaultdict

INFINITY = float('inf')

class Graph(object):

    def __init__(self):
        self.edges = defaultdict(lambda: set())
        self.capacities = defaultdict(lambda: 0)

    def copy(self):
        new_g = Graph()
        new_g.edges = self.edges.copy()
        new_g.capacities = self.capacities.copy()
        return new_g

    def addEdge(self, vertex1, vertex2, capacity):
        self.edges[vertex1].add(vertex2)
        self.edges[vertex2].add(vertex1)
        self.capacities[(vertex1, vertex2)] = capacity

    def __str__(self):
        return str((self.edges, self.capacities))

    def findPath(self, s, t, flow):
        parent = defaultdict(lambda: -1)
        parent[s] = -2
        bottleneck = defaultdict(lambda: INFINITY)
        queue = []
        queue.append(s)
        while queue:
            u = queue.pop()
            for v in self.edges[u]:
                current_capacity = self.capacities[(u, v)] - flow[(u, v)]
                if current_capacity <= 0: continue
                if parent[v] != -1: continue
                parent[v] = u
                bottleneck[v] = min(bottleneck[u], current_capacity)
                if v != t:
                    queue.append(v)
                else:
                    path = [t]
                    while path[0] != s:
                        path = [parent[path[0]]] + path
                    return path, bottleneck[t]
        return None, None

    def maxFlow(self, s, t):
        flow = defaultdict(lambda: 0)
        while True:
            path, bottleneck = self.findPath(s, t, flow)
            if path is None: break
            assert bottleneck < INFINITY
            prev = s
            i = 1
            while i < len(path):
                flow[path[i-1], path[i]] += bottleneck
                flow[path[i], path[i-1]] -= bottleneck
                i += 1
        return sum(flow[(s,v)] for v in self.edges[s])

def int_stream(datastream):
    whitespace = re.compile(r'\s+')
    for line in datastream:
        chunks = whitespace.split(line)
        for chunk in chunks:
            if not chunk: continue
            yield int(chunk)

def random_int_stream(first, a, b):
    for thing in first: yield thing
    while True:
        yield random.randint(a, b)

def main(argv):
    ints = int_stream(sys.stdin)
    cave_count = ints.next()
    corridor_count = ints.next()
    g = Graph()
    for _ in xrange(corridor_count):
      a, b, c = ints.next(), ints.next(), ints.next()
      g.addEdge(a, b, c)
    print g.maxFlow(1, cave_count)
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
