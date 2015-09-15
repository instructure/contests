module GreedyHex
class Line
  attr_reader :first, :last

  def initialize(a, b)
    coordinates = [a, b].sort
    @first = coordinates.first
    @last = coordinates.last
  end

  include Comparable
  def <=>(other)
    if other.kind_of?(Line)
      [@first, @last] <=> [other.first, other.last]
    else
      nil
    end
  end
  alias :eql? :==
  
  def hash
    [@first.hash, @last.hash].hash
  end
  
  def to_whatever
    [{:row => @first.row, :col => @first.col}, {:row => @last.row, :col => @last.col}]
  end
  
  def type
    if @first.row == @last.row
      @first.row % 2 == 0 ? :even_flat : :odd_flat
    elsif @first.row % 2 == 0
      @first.col == @last.col ? :forward : :back
    else
      @first.col == @last.col ? :back : :forward
    end
  end
  
end
end
