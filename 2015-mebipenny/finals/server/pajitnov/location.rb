module Pajitnov
  class Location
    attr_reader :row, :col

    def initialize(row, col)
      @row, @col = row, col
    end

    def as_json
      {
        row: @row,
        col: @col
      }
    end
  end
end
