#!/usr/bin/env python

import sys

HAND_VALUES = {
  "A": [1,11],
  "2": [2],
  "3": [3],
  "4": [4],
  "5": [5],
  "6": [6],
  "7": [7],
  "8": [8],
  "9": [9],
  "J": [10],
  "Q": [10],
  "K": [10]}

def all_hands(values):
  if not values: return [[]]
  rv = []
  for hand in all_hands(values[1:]):
    rv.append(hand)
    for value in values[0]:
      rv.append([value] + hand)
  return rv

def process_hand(hand):
  values = map(lambda x: HAND_VALUES[x], hand)
  possible_hands = all_hands(values)
  best_score = 0
  for hand in possible_hands:
    score = sum(hand)
    if score > 21: continue
    if score >= best_score: best_score = score
  print best_score

lines = int(sys.stdin.readline().strip())
for _ in xrange(lines):
  process_hand(list(sys.stdin.readline().strip()))
