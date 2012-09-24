class Solver
  def self.solve(capacity, guards)
    self.new(capacity, guards).solve
  end

  def initialize(capacity, guards)
    @capacity, @guards = capacity, guards.sort
    @cache = {}
  end

  def solve
    solve_step(@capacity, @guards.size)
  end

  # returns the guard weights that sum to goal, selecting only from the lightest
  # idx guards. prefers biggest subset, and heaviest guards. returns nil if
  # there's no solution
  def solve_step(goal, idx)
    # cache the result
    @cache[idx] ||= {}
    unless @cache[idx].has_key?(goal)
      @cache[idx][goal] =
        if goal.zero?
          # if we met goal, return the tail as the solution
          []
        elsif goal < 0 || idx == 0
          # exceeded goal, or can't reach goal. branch failed
          nil
        else
          # next guard to consider (idx is 1-based)
          head = @guards[idx-1]

          # try with...
          solution1 = solve_step(goal - head, idx - 1)
          solution1 = [head, *solution1] if solution1

          # ...and without
          solution2 = solve_step(goal, idx - 1)

          # prefer bigger solution, but solution1 if they're the same size.
          if solution1 && solution2
            solution2.size > solution1.size ? solution2 : solution1
          else
            solution1 || solution2
          end
        end
    end
    @cache[idx][goal]
  end
end

# process a line of input, formulating it as a solve instance.
def process(line)
  # parse the input line
  capacity, empress, *guards = line.split.map(&:to_i)

  # bail immediately if the empress herself is over the goal
  return "NO SOLUTION" if empress > capacity

  # run the solver for the capacity after the princess
  solution = Solver.solve(capacity - empress, guards)
  return "NO SOLUTION" unless solution

  # format solution for output
  return solution.join(" ")
end

# loop over input
while line = $stdin.gets
  puts process(line)
end
