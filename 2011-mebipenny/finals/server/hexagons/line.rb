module Hexagons
  class Line
    attr_reader :first, :last
    attr_accessor :owner

    def initialize(a, b)
      coordinates = [a, b].sort
      first = coordinates.first
      last = coordinates.last
      @first = first
      @last = last
      @owner = nil
    end

    include Comparable
    def <=>(other)
      if other.kind_of?(Hexagons::Line)
        [@first, @last] <=> [other.first, other.last]
      else
        nil
      end
    end

    def as_json
      {:endpoints => [@first.as_json, @last.as_json], :owner => @owner && @owner.as_json}
    end

    def to_json
      as_json.to_json
    end
  end
end
