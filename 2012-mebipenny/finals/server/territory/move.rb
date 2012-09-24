module Territory
  class Move
    PASS = 'PASS'

    attr_reader :tile, :favor

    def initialize(tile, favor)
      @tile = tile
      @favor = favor
    end
  end
end
