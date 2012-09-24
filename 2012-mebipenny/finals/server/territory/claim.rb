module Territory
  class Claim
    attr_reader :tile
    attr_accessor :owner

    def initialize(tile, owner)
      @tile = tile
      @owner = owner
    end

    def as_json
      {
        :tile => @tile.as_json,
        :owner => @owner && @owner.id
      }
    end

    def to_json
      as_json.to_json
    end
  end
end
