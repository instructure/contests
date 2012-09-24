module FinalsFramework
  class Game
    class Snapshot
      attr_reader :player_scores, :state

      def initialize(game)
        @player_scores = {}
        game.players.each{ |p| @player_scores[p] = p.score }
        @state = game.state
      end
    end
  end
end
