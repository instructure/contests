module GreedyHex
class GreedyHex::Game
  def initialize(rows, cols)
    @rows = rows
    @cols = cols
    @used_lines = {}
    @invalid_lines = {}
    @hexagons = {}
  end
  
  def next_move
    5.downto(1) do |i|
      next if i == 4
      if hex = @hexagons.values.find{|h| h.valid && h.length == i}
        return hex.get_needed_line.to_whatever
      end
    end
    while 1 do
      rc = random_coord
      neighborhood(rc).each do |nc|
        line = Line.new(rc,nc)
        return line.to_whatever if !@used_lines.has_key?(line) && !@invalid_lines.has_key?(line)
      end
    end
  end
  
  def add_line_by_points(row1, col1, row2, col2)
    add_line Line.new(Coord.new(row1, col1), Coord.new(row2, col2))
  end
  
  def add_line(line)
    @used_lines[line] = 1
    get_hexagons(line) do |hex|
      if hex.add_line(line)
        # the hex is completed
        hex.inner_lines.each do |invalid_line|
          @invalid_lines[invalid_line] = 1
          get_hexagons(invalid_line) do |invalid_hex|
            invalid_hex.valid = false
          end
        end
      end
    end
  end
  
  def get_hexagon(coord)
    @hexagons[coord] ||= Hexagon.new(coord, neighborhood(coord))
  end
  
  def get_hexagons(line)
    Hexagon.find_hexagon_coords(line).each do |coord|
      yield get_hexagon(coord)
    end
  end
  
  def coord_legal?(coord)
    boundary = @cols
    boundary -= 1 if (coord.row % 2).zero?
    coord.row >= 0 && coord.row < @rows &&
    coord.col >= 0 && coord.col < boundary
  end
  
  def random_coord
    coord = Coord.new(rand(@rows), rand(@cols))
    while !coord_legal?(coord)
      coord = Coord.new(rand(@rows), rand(@cols))
    end
    coord
  end
  
  def neighborhood(coord)
    # adjacent vertices on the board in CW order
    shift = (coord.row + 1) % 2
    [ Coord.new(coord.row, coord.col - 1),
      Coord.new(coord.row - 1, coord.col + shift - 1),
      Coord.new(coord.row - 1, coord.col + shift),
      Coord.new(coord.row, coord.col + 1),
      Coord.new(coord.row + 1, coord.col + shift),
      Coord.new(coord.row + 1, coord.col + shift - 1) ].
      select{ |c| coord_legal?(c) }
  end
  
end
end