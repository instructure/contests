import sys
import math

class Fraction:
  def __init__(self, num, denom):
  	if (num > 0 and denom % num == 0):
  		# Reduce the fraction
  		denom /= num
  		num = 1

  	self.num = num
  	self.denom = denom

  def subtract(self, other_num, other_denom):
    common_denom = self.denom * other_denom
    
    converted_num = self.num * common_denom / self.denom
    converted_other_num = other_num * common_denom / other_denom

    return Fraction(converted_num - converted_other_num, common_denom)

  def largest_contained_egyptian(self):
  	 if self.num == 0:
  	 	return Fraction(0, self.denom)
  	 if self.num == 1:
  	 	return Fraction(1, self.denom)

  	 next_denom = int(math.ceil((0.0 + self.denom) / self.num))
  	 next_fraction = Fraction(1, next_denom)

  	 return next_fraction


  def __str__(self):
  	return "%d/%d" % (self.num, self.denom)

def main(num, denom):
  goal = Fraction(num, denom)
  curr_denom = goal.largest_contained_egyptian().denom
  final_denoms = []

  while goal.num != 0:
    remainder = goal.subtract(1, curr_denom)
    if remainder.num >= 0:
      final_denoms.append(curr_denom)
      goal = remainder

    if False:
    # simple version
      curr_denom += 1;
    else:
      # advanced version: intelligently jump to the next available denominator
      next_fraction = goal.largest_contained_egyptian()
      curr_denom = next_fraction.denom

      if goal.subtract(next_fraction.num, next_fraction.denom).num < 0:
  	      print "*** rounding error ***"
  	      final_denoms.append(0)
  	      goal.num = 0

  components = ["%d" % x for x in final_denoms]
  print "%s" % ' '.join(components)


if __name__ == "__main__":
    while True:
        data = sys.stdin.readline()
        if not data:
            break
        n, d = data.split(' ')
        n = int(n)
        d = int(d)
        main(n, d)
