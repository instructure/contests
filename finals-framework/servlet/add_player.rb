require 'finals-framework/servlet/base'

module FinalsFramework
  module Servlet
    class AddPlayer < FinalsFramework::Servlet::Base
      def POST(request)
        game_id = request[:path].split('/')[1]
        game = @server.game_registry.instance(game_id)
        return [404, {}, ["no such game"]] unless game

        if game.state == 'initiating'
          if player = game.add_player(request[:payload])
            player.wait_for_turn do |turn_token|
              request[:async_cb].call [ 200, {
                'Content-Type' => 'application/json',
                'X-Turn-Token' => turn_token
              }, [game.to_json(player)] ]
            end
            [-1, {}, []]
          else
            [403, {}, ["invalid player data"]]
          end
        else
          [410, {}, ["game already started"]]
        end
      end
    end
  end
end
