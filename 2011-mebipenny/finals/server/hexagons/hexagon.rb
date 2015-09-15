module Hexagons
  class Hexagon
    attr_reader :center, :owner

    def initialize(center, owner)
      @center = center
      @owner = owner
    end

    def as_json
      { :center => @center.as_json,
        :owner  => @owner.as_json }
    end

    def to_json
      as_json.to_json
    end
  end
end
