#!/usr/bin/python

import sys

def add(x, y): return x + y
def sub(x, y): return x - y
def mult(x, y): return x * y
OPERATIONS = [add, sub, mult]
REPRESENTATIONS = {add: '+', sub: '-', mult: '*'}

def new_counter(counter, item):
  if counter is None: counter = 0
  if type(item) == type(add): return counter - 1
  else: return counter + 1

def valid_perms(lst, counter=None):
  if counter is not None and counter <= 0: return
  if len(lst) == 1:
    if new_counter(counter, lst[0]) != 1: return
    yield lst
  else:
    for i in xrange(len(lst)):
      for perm in valid_perms(lst[:i]+lst[i+1:], new_counter(counter, lst[i])):
        yield [lst[i]] + perm

def all_combos(lst, n):
  if n == 0: yield []
  else:
    for i in xrange(len(lst)):
      for combo in all_combos(lst, n - 1):
        yield [lst[i]] + combo

def uniq(generator):
  seen_things=set([])
  for thing in generator:
    if tuple(thing) not in seen_things:
      seen_things.add(tuple(thing))
      yield thing

def valid_postfix_stacks(nums):
  for op_combo in uniq(all_combos(OPERATIONS, len(nums) - 1)):
    for perm in uniq(valid_perms(nums + op_combo)):
      yield perm

def compute(stack):
  s = []
  for item in stack:
    if type(item) != type(add):
      s.append(item)
    else:
      s.append(item(*reversed([s.pop(), s.pop()])))
  assert len(s) == 1
  return s[0]

def infix(stack):
  s = []
  for item in stack:
    if type(item) != type(add):
      s.append(str(item))
    else:
      s.append('(' + ' '.join(reversed([s.pop(), REPRESENTATIONS[item], s.pop()])) + ')')
  assert len(s) == 1
  return s[0]

def solve(nums, answer):
  for postfix_stack in uniq(valid_postfix_stacks(nums)):
    try: val = compute(postfix_stack)
    except ZeroDivisionError, e: continue
    if val == answer:
      print "Y" #, infix(postfix_stack), "=", val
      return
  print "N"

def main(argv):
  for _ in xrange(int(sys.stdin.readline().strip())):
    numbers = map(int, sys.stdin.readline().strip().split())
    target = numbers.pop()
    solve(numbers, target)

if __name__ == "__main__":
  sys.exit(main(sys.argv))
