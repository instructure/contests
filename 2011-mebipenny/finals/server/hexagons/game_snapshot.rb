require 'gameworks'

module Hexagons
  class Game < Gameworks::Game
    class Snapshot < Gameworks::Game::Snapshot
      attr_reader :lines, :hexagons

      def initialize(game)
        super
        @lines = game.lines.dup
        @hexagons = game.hexagons.dup
      end
    end
  end
end
