require 'finals-framework/game_snapshot'

module Territory
  class Game < FinalsFramework::Game
    class Snapshot < FinalsFramework::Game::Snapshot
      attr_reader :claims, :player_hands

      def initialize(game)
        super
        @player_hands = {}
        game.players.each{ |p| @player_hands[p] = p.hand.map{ |tile| tile.as_json } }
        @claims = game.flat_claims.map{ |claim| claim.as_json }
      end
    end
  end
end
