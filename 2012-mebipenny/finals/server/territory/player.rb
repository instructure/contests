require 'gameworks'

module Territory
  class Player < Gameworks::Player
    attr_reader :hand, :id
    attr_accessor :passed

    def initialize(payload={})
      super
      return if @invalid
      @hand = []
      @id = SecureRandom.uuid.to_s.split('-').first
      @passed = false
    end

    def as_json(for_player=nil)
      super.merge(
        :id => @id,
        :hand => for_player == self ?
          @hand.map{ |tile| tile.as_json } :
          @hand.size
      )
    end

    def to_json(for_player=nil)
      as_json(for_player).to_json
    end
  end
end
