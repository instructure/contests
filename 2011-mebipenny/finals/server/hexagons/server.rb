require 'gameworks'
require_relative 'game'

module Hexagons
  class Server < Gameworks::Server
    def game_class
      Hexagons::Game
    end
  end
end
