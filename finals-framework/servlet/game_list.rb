require 'finals-framework/servlet/base'

module FinalsFramework
  module Servlet
    class GameList < FinalsFramework::Servlet::Base
      def POST(request)
        game = @server.game_class.new(request[:payload])
        if game.valid?
          @server.game_registry.add(game)
          [201, {'Location' => "/#{game.id}"}, []]
        else
          return [403, {}, ["invalid game data"]]
        end
      end

      def GET(request)
        [200, {}, [@server.game_registry.to_json]]
      end
    end
  end
end
