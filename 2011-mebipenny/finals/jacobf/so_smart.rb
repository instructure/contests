require 'pp'

class So_smart
  class Coord
    class << self
      def [](row, col)
        @coords ||= {}
        @coords[hash_key_raw(row, col)] ||= self.new(row, col)
      end

      def hash_key(coord)
        hash_key_raw(coord.row, coord.col)
      end

      def hash_key_raw(row, col)
        [row, col].inspect
      end

      def from_server(data)
        self[data['row'], data['col']]
      end

      protected :new
    end

    attr_reader :row, :col

    def initialize(row, col)
      @row, @col = row, col
    end

    def hash_key
      self.class.hash_key(self)
    end

    def ==(other)
      other.row == @row && other.col == @col
    end

    def sort_key
      [@row, @col]
    end

    def east
      self.class[@row, @col + 1]
    end

    def west
      self.class[@row, @col - 1]
    end

    def northwest
      self.class[@row - 1, @col - (@row % 2)]
    end

    def northeast
      self.class[@row - 1, @col - (@row % 2) + 1]
    end

    def southwest
      self.class[@row + 1, @col - (@row % 2)]
    end

    def southeast
      self.class[@row + 1, @col - (@row % 2) + 1]
    end

    def neighbors
      [ west, northwest, northeast, east, southeast, southwest ]
    end

    def to_server
      {:row => @row, :col => @col}
    end

    def inspect
      to_server.inspect
    end
  end

  class Line
    class << self
      def [](coord1, coord2)
        @lines ||= {}
        @lines[hash_key_raw(coord1, coord2)] ||= self.new(coord1, coord2)
      end

      def hash_key(line)
        hash_key_raw(line.coord1, line.coord2)
      end

      def hash_key_raw(coord1, coord2)
        [coord1, coord2].sort_by{ |c| c.sort_key }.inspect
      end

      def from_server(data)
        self[*data['endpoints'].map{ |coord| Coord.from_server(coord) }]
      end

      protected :new
    end

    attr_reader :coord1, :coord2

    def initialize(coord1, coord2)
      @coord1, @coord2 = [coord1, coord2].sort_by{ |c| c.sort_key }
    end

    def hash_key
      self.class.hash_key(self)
    end

    def hexes
      case @coord2
      when @coord1.east      then [ Hex[@coord1.northeast], Hex[@coord1.southeast] ]
      when @coord1.southwest then [ Hex[@coord1.west],      Hex[@coord2.east] ]
      when @coord1.southeast then [ Hex[@coord1.east],      Hex[@coord2.west] ]
      else                        []
      end
    end

    def to_server
      [@coord1.to_server, @coord2.to_server]
    end

    def inspect
      to_server.inspect
    end
  end

  class Hex
    class << self
      def [](coord)
        @hexes ||= {}
        @hexes[hash_key_raw(coord)] ||= self.new(coord)
      end

      def hash_key(hex)
        hash_key_raw(hex.center)
      end

      def hash_key_raw(coord)
        coord.hash_key
      end

      def from_server(data)
        self[Coord.from_server(data['center'])]
      end

      protected :new
    end

    attr_reader :center
    attr_accessor :possible, :edges_placed

    def initialize(center)
      @center = center
      @possible = true
      @edges_placed = 0
    end

    def hash_key
      self.class.hash_key(self)
    end

    def inspect
      {:center => @center,
       :possible => @possible,
       :edges_placed => @edges_placed}.inspect
    end
  end

  def shift_for_row(i)
    -(i % 2)
  end

  def cols_for_row(i)
    @cols - 1 - shift_for_row(i)
  end

  def reset_game(game)
    @lines = {}
    @rows = game['rows']
    @cols = game['cols']
    @rows.times do |i|
      cols_for_row(i).times do |j|
        c1 = Coord[i, j]
        [ c1.east, c1.southeast, c1.southwest ].each do |c2|
          next unless valid_coordinate?(c2)
          line = Line[c1, c2]
          @lines[line.hash_key] = line
          line.hexes.each do |hex|
            hex.possible = false unless hex.center.neighbors.all?{ |c| valid_coordinate?(c) }
          end
        end
      end
    end
    update_game(game)
  end

  def update_game(delta)
    delta['lines'].each do |line|
      line = Line.from_server(line)
      remove_line(line)
      line.hexes.each do |hex|
        if valid_coordinate?(hex.center)
          hex.edges_placed += 1
        end
      end
    end

    delta['hexagons'].each do |hex|
      hex = Hex.from_server(hex)
      hex.center.neighbors.each do |coord|
        if valid_coordinate?(coord)
          line = Line[hex.center, coord]
          remove_line(line)
          Hex[coord].possible = false
        end
      end
    end
  end

  def remove_line(line)
    @lines.delete(line.hash_key)
  end

  def valid_coordinate?(coord)
    coord.row >= 0 && coord.row < @rows &&
    coord.col >= 0 && coord.col < @cols - 1 + (coord.row % 2)
  end

  def get_next_move
    ranked_lines = @lines.values.map{ |line| [line, rank(line)] }
    best_rank = ranked_lines.map{ |line,rank| rank }.max
    candidates = ranked_lines.select{ |line,rank| rank == best_rank }
    line = candidates.map{ |line,rank| line }.sort_by{ rand }.first
    line.to_server
  end

  RANKS = {
    # we love double hex completion!
    [5,   5  ] => 27,
    # ch-ch-ch-chain!
    [5,   4  ] => 26,
    [4,   5  ] => 26,
    # any other hexes to complete?
    [5,   3  ] => 25,
    [3,   5  ] => 25,
    [5,   1  ] => 24,
    [1,   5  ] => 24,
    [5,   nil] => 23,
    [nil, 5  ] => 23,
    [5,   0  ] => 22,
    [0,   5  ] => 22,
    [5,   2  ] => 21,
    [2,   5  ] => 21,
    # ok, try to place an edge that's either even or irrelevant on both hexes
    [3,   3  ] => 20,
    [3,   1  ] => 19,
    [1,   3  ] => 19,
    [3,   nil] => 18,
    [nil, 3  ] => 18,
    [1,   1  ] => 17,
    [1,   nil] => 16,
    [nil, 1  ] => 16,
    [nil, nil] => 15,
    # dang, we have to place an odd edge on one of the hexes. prefer that the
    # other be even if possible, and avoid giving them a completion
    [3,   0  ] => 14,
    [0,   3  ] => 14,
    [3,   2  ] => 13,
    [2,   3  ] => 13,
    [1,   0  ] => 12,
    [0,   1  ] => 12,
    [1,   2  ] => 11,
    [2,   1  ] => 11,
    # can't make the other even? well hopefully at least irrelevant
    [nil, 0  ] => 10,
    [0,   nil] => 10,
    [nil, 2  ] =>  9,
    [2,   nil] =>  9,
    # seriously, we have to place an odd edge on both hexes? sadface
    [0,   0  ] =>  8,
    [0,   2  ] =>  7,
    [2,   0  ] =>  7,
    [2,   2  ] =>  6,
    # shoot, gonna have to give them a completion.
    [3,   4  ] =>  5,
    [4,   3  ] =>  5,
    [1,   4  ] =>  4,
    [4,   1  ] =>  4,
    [nil, 4  ] =>  3,
    [4,   nil] =>  3,
    [0,   4  ] =>  2,
    [4,   0  ] =>  2,
    [2,   4  ] =>  1,
    [4,   2  ] =>  1,
    # whaaaaaaat... don't do this unless it's the only move!
    [4,   4  ] =>  0
    # no 6s in the above enumeration since we shouldn't be considering edges on
    # hexes that are completed
  }

  def rank(line)
    values = line.hexes.map{ |hex| hex.possible ? hex.edges_placed : nil }
    RANKS[values]
  end
end
