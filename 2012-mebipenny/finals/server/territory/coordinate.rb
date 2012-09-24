module Territory
  class Tile
    attr_reader :row, :col

    def initialize(row, col)
      @row = row
      @col = col
    end

    def as_json
      { :row => @row,
        :col => @col }
    end

    def to_json
      as_json.to_json
    end
  end
end
