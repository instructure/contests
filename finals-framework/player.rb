require 'eventmachine'

module FinalsFramework
  class Player
    attr_reader :name
    attr_accessor :score

    def initialize(payload={})
      unless payload.is_a?(Hash) &&
             payload.has_key?('name') &&
             payload['name'].is_a?(String)
        @invalid = true
        return
      end

      @name = payload['name']
      @score = 0

      # used for evented "block until it's my turn". the game will push a token
      # on this queue when it's the player's turn, or will push a nil when the
      # game is completed
      @em_queue = EventMachine::Queue.new
    end

    def valid?
      !@invalid
    end

    def disqualified?
      @score == 'disqualified'
    end

    def signal_turn(token)
      @em_queue.push(token)
    end

    def wait_for_turn
      @em_queue.pop{ |token| yield token }
    end

    def as_json(for_player=nil)
      { :name  => @name,
        :score => @score }
    end

    def to_json(for_player=nil)
      as_json(for_player).to_json
    end
  end
end
