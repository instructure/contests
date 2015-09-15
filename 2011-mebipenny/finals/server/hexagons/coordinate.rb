module Hexagons
  class Coordinate
    attr_reader :row, :col

    def initialize(row, col)
      @row = row
      @col = col
    end

    include Comparable
    def <=>(other)
      if other.kind_of?(Coordinate)
        [@row, @col] <=> [other.row, other.col]
      else
        nil
      end
    end
    alias :eql? :==

    def hash
      as_json.hash
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
