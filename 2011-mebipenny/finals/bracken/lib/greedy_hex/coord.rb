module GreedyHex
class Coord
  attr_reader :row, :col

  def initialize(row, col)
    @row = row
    @col = col
  end

  include Comparable
  def <=>(other)
    if other.kind_of?(Coord)
      [@row, @col] <=> [other.row, other.col]
    else
      nil
    end
  end
  alias :eql? :==
  
  def hash
    [@row, @col].hash
  end
  
end
end
