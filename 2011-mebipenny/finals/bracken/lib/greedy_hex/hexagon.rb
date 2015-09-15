module GreedyHex
class Hexagon
  attr_accessor :center, :valid

  def initialize(center, adj_coords)
    @center = center
    @lines = []
    @adj_coords = adj_coords
    @valid = @adj_coords.length == 6
  end
  
  def add_line(line)
    @lines << line
    complete?
  end
  
  def hash
    @center.hash
  end
  
  def length
    @lines.length
  end
    
  def complete?
    length == 6
  end
  
  def inner_lines
    @adj_coords.map{|c|Line.new(@center, c)}
  end
  
  def get_needed_line
    @adj_coords.each_with_index do |ac, i|
      line = Line.new(ac, @adj_coords[(i+1)%6])
      return line unless @lines.member?(line)
    end
  end

  # find the two hexagons centers that this line could be a part of
  def self.find_hexagon_coords(line)
    first = line.first
    last = line.last
    case line.type
      when :even_flat
        [Coord.new(first.row - 1, last.col), Coord.new(first.row + 1, last.col)]
      when :odd_flat
        [Coord.new(first.row - 1, first.col), Coord.new(first.row + 1, first.col)]
      when :forward
        [Coord.new(last.row, last.col + 1), Coord.new(first.row, first.col - 1)]
      when :back
        [Coord.new(last.row, last.col - 1), Coord.new(first.row, first.col + 1)]
    end
  end
  
end
end
