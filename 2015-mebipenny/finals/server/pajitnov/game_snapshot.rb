require 'gameworks'

module Pajitnov
  class Game < Gameworks::Game
    class Snapshot < Gameworks::Game::Snapshot
      attr_reader :player_board_hashes

      def initialize(game)
        super
        @player_board_hashes = {}
        game.players.each{ |p| @player_board_hashes[p] = p.board.hash }
      end
    end
  end
end
