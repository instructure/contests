module Territory
  class Tile
    attr_reader :row, :col

    def initialize(row, col)
      @row = row
      @col = col
    end

    def neighbor(direction)
      case direction
      when :east then self.class.new(@row, @col + 1)
      when :west then self.class.new(@row, @col - 1)
      when :north then self.class.new(@row - 1, @col)
      when :south then self.class.new(@row + 1, @col)
      else raise ArgumentError
      end
    end

    def ==(other)
      other.is_a?(Tile) &&
      other.row == @row &&
      other.col == @col
    end

    def as_json
      {
        :row => @row,
        :col => @col
      }
    end

    def to_json
      as_json.to_json
    end
  end
end
