require 'set'

NORTH = "north"
SOUTH = "south"
EAST = "east"
WEST = "west"
ORIENTATIONS = [NORTH, SOUTH, EAST, WEST]

MOVE = "move"
LEFT = "left"
RIGHT = "right"

start = STDIN.gets.chomp.split(",").map(&:to_i)
goal = STDIN.gets.chomp.split(",").map(&:to_i)
walls = Set.new
loop do
  break unless (line = STDIN.gets)
  line = line.chomp
  break if line.empty?

  walls << line.split(",").map(&:to_i)
end
xs = walls.map(&:first)
ys = walls.map(&:last)
xs.concat([start[0], goal[0]])
ys.concat([start[1], goal[1]])
mx = xs.sort.last + 1
my = ys.sort.last + 1

# Priority queue with array based heap.
#
# A priority queue is like a standard queue, except that each inserted
# elements is given a certain priority, based on the result of the
# comparison block given at instantiation time. Also, retrieving an element
# from the queue will always return the one with the highest priority
# (see #pop and #top).
#
# The default is to compare the elements in repect to their #<=> method.
# For example, Numeric elements with higher values will have higher
# priorities.
#
# Note that as of version 2.0 the internal queue is kept in the reverse order
# from how it was kept in previous version. If you had used #to_a in the
# past then be sure to adjust for the priorities to be ordered back-to-front
# instead of the oterh way around.
#
class PQueue

  #
  VERSION = "2.1.0"  #:erb: VERSION = "<%= version %>"

  #
  # Returns a new priority queue.
  #
  # If elements are given, build the priority queue with these initial
  # values. The elements object must respond to #to_a.
  #
  # If a block is given, it will be used to determine the priority between
  # the elements. The block must must take two arguments and return `1`, `0`,
  # or `-1` or `true`, `nil` or `false. It should return `0` or `nil` if the
  # two arguments are considered equal, return `1` or `true` if the first
  # argument is considered greater than the later, and `-1` or `false` if
  # the later is considred to be greater than the first.
  #
  # By default, the priority queue retrieves maximum elements first
  # using the #<=> method.
  #
  def initialize(elements=nil, &block) # :yields: a, b
    @que = []
    @cmp = block || lambda{ |a,b| a <=> b }
    replace(elements) if elements
  end

 protected

  #
  # The underlying heap.
  #
  attr_reader :que #:nodoc:

 public

  #
  # Priority comparison procedure.
  #
  attr_reader :cmp

  #
  # Returns the size of the queue.
  #
  def size
    @que.size
  end

  #
  # Alias of size.
  #
  alias length size

  #
  # Add an element in the priority queue.
  #
  def push(v)
    @que << v
    reheap(@que.size-1)
    self
  end

  #
  # Traditional alias for #push.
  #
  alias enq push

  #
  # Alias of #push.
  #
  alias :<< :push

  #
  # Get the element with the highest priority and remove it from
  # the queue.
  #
  # The highest priority is determined by the block given at instantiation
  # time.
  #
  # The deletion time is O(log n), with n is the size of the queue.
  #
  # Return nil if the queue is empty.
  #
  def pop
    return nil if empty?
    @que.pop
  end

  #
  # Traditional alias for #pop.
  #
  alias deq pop

  # Get the element with the lowest priority and remove it from
  # the queue.
  #
  # The lowest priority is determined by the block given at instantiation
  # time.
  #
  # The deletion time is O(log n), with n is the size of the queue.
  #
  # Return nil if the queue is empty.
  #
  def shift
    return nil if empty?
    @que.shift
  end

  #
  # Returns the element with the highest priority, but
  # does not remove it from the queue.
  #
  def top
    return nil if empty?
    return @que.last
  end

  #
  # Traditional alias for #top.
  #
  alias peek top

  #
  # Returns the element with the lowest priority, but
  # does not remove it from the queue.
  #
  def bottom
    return nil if empty?
    return @que.first
  end

  #
  # Add more than one element at the same time. See #push.
  #
  # The elements object must respond to #to_a, or be a PQueue itself.
  #
  def concat(elements)
    if empty?
      if elements.kind_of?(PQueue)
        initialize_copy(elements)
      else
        replace(elements)
      end
    else
      if elements.kind_of?(PQueue)
        @que.concat(elements.que)
        sort!
      else
        @que.concat(elements.to_a)
        sort!
      end
    end
    return self
  end

  #
  # Alias for #concat.
  #
  alias :merge! :concat

  #
  # Return top n-element as a sorted array.
  #
  def take(n=@size)
    a = []
    n.times{a.push(pop)}
    a
  end

  #
  # Returns true if there is no more elements left in the queue.
  #
  def empty?
    @que.empty?
  end

  #
  # Remove all elements from the priority queue.
  #
  def clear
    @que.clear
    self
  end

  #
  # Replace the content of the heap by the new elements.
  #
  # The elements object must respond to #to_a, or to be
  # a PQueue itself.
  #
  def replace(elements)
    if elements.kind_of?(PQueue)
      initialize_copy(elements)
    else
      @que.replace(elements.to_a)
      sort!
    end
    self
  end

  #
  # Return a sorted array, with highest priority first.
  #
  def to_a
    @que.dup
  end

  #
  # Return true if the given object is present in the queue.
  #
  def include?(element)
    @que.include?(element)
  end

  #
  # Push element onto queue while popping off and returning the next element.
  # This is qquivalent to successively calling #pop and #push(v).
  #
  def swap(v)
    r = pop
    push(v)
    r
  end

  #
  # Iterate over the ordered elements, destructively.
  #
  def each_pop #:yields: popped
    until empty?
      yield pop
    end
    nil
  end

  #
  # Pretty inspection string.
  #
  def inspect
    "<#{self.class}: size=#{size}, top=#{top || "nil"}>"
  end

  #
  # Return true if the queues contain equal elements.
  #
  def ==(other)
    size == other.size && to_a == other.to_a
  end

 private

  #
  #
  #
  def initialize_copy(other)
    @cmp  = other.cmp
    @que  = other.que.dup
    sort!
  end

  #
  # The element at index k will be repositioned to its proper place.
  #
  # This, of course, assumes the queue is already sorted.
  #
  def reheap(k)
    return self if size <= 1

    que = @que.dup

    v = que.delete_at(k)
    i = binary_index(que, v)

    que.insert(i, v)

    @que = que

    return self
  end

  #
  # Sort the queue in accorance to the given comparison procedure.
  #
  def sort!
    @que.sort! do |a,b|
      case @cmp.call(a,b)
      when  0, nil   then  0
      when  1, true  then  1
      when -1, false then -1
      else
        warn "bad comparison procedure in #{self.inspect}"
        0
      end
    end
    self
  end

  #
  # Alias of #sort!
  #
  alias heapify sort!

  #
  def binary_index(que, target)
    upper = que.size - 1
    lower = 0

    while(upper >= lower) do
      idx  = lower + (upper - lower) / 2
      comp = @cmp.call(target, que[idx])

      case comp
      when 0, nil
        return idx
      when 1, true
        lower = idx + 1
      when -1, false
        upper = idx - 1
      else
      end
    end
    lower
  end

end # class PQueue

class PQ
  attr_reader :heap

  def initialize(heap, &cmp)
    @heap = heap
    @set = Set.new
    @cmp = cmp
  end

  def push(value)
    if !@set.include?(value)
      @heap << value
      @set << value
    end
    @heap.sort!{ |a,b| @cmp.call(a,b) ? 1 : -1 }
  end

  def pop
    v = @heap.shift
    @set.delete(v)
    v
  end

  def empty?
    @heap.empty?
  end
end

def manhattan(p1, p2)
  (p1[0] - p2[0]).abs + (p1[1] - p2[1]).abs
end

def simulate_move(position, orientation, mx, my, walls)
  x, y = position
  case orientation
  when NORTH
    y = (y - 1)
  when SOUTH
    y = (y + 1)
  when EAST
    x = (x + 1)
  when WEST
    x = (x - 1)
  end
  if x < 0 || y < 0 || x >= mx || y >= my || walls.include?([x,y])
    return position
  else
    return [x, y]
  end
end

def simulate_left(position, orientation)
  case orientation
  when NORTH then WEST
  when SOUTH then EAST
  when EAST then NORTH
  when WEST then SOUTH
  end
end

def simulate_right(position, orientation)
  case orientation
  when NORTH then EAST
  when SOUTH then WEST
  when EAST then SOUTH
  when WEST then NORTH
  end
end

init_states = ORIENTATIONS.map{|o| [start, o, [start]]}

score = -> (state) { state[2].size + manhattan(state[0], goal) }
queue = PQueue.new(init_states) { |a,b| score.(a) < score.(b) }
seen = {}
path = nil
until queue.empty?
  position, orientation, history, _ = queue.pop
  seen[[position, orientation]] = true
  if position == goal
    path = history
    break
  end
  [MOVE, LEFT, RIGHT].each do |action|
    case action
    when MOVE
      new_position = simulate_move(position, orientation, mx, my, walls)
      next if seen[[new_position, orientation]]
      queue.push [new_position, orientation, history + [new_position]]
    when LEFT
      new_orientation = simulate_left(position, orientation)
      next if seen[[position, new_orientation]]
      queue.push [position, new_orientation, history + [position]]
    when RIGHT
      new_orientation = simulate_right(position, orientation)
      next if seen[[position, new_orientation]]
      queue.push [position, new_orientation, history + [position]]
    end
  end
end

path.uniq.each do |x,y|
  puts "#{x},#{y}"
end

