require 'gameworks'
require_relative 'game'

module Territory
  class Server < Gameworks::Server
    def game_class
      Territory::Game
    end
  end
end
