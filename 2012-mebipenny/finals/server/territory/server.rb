require 'finals-framework/server'
require 'territory/game'

module Territory
  class Server < FinalsFramework::Server
    def game_class
      Territory::Game
    end
  end
end
