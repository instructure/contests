require 'finals-framework/servlet/base'

module FinalsFramework
  module Servlet
    class AddMove < FinalsFramework::Servlet::Base
      def POST(request)
        game_id = request[:path].split('/')[1]
        game = @server.game_registry.instance(game_id)
        return [404, {}, ["no such game"]] unless game

        if game.state == 'in play'
          player = game.current_player(request[:tokens][:turn])
          if player
            snapshot = game.snapshot
            legal, error = game.add_move(request[:payload])
            if legal
              player.wait_for_turn do |turn_token|
                EventMachine.add_timer(game.delay_time) do
                  request[:async_cb].call [ 200, {
                    'Content-Type' => 'application/json',
                    'X-Turn-Token' => turn_token
                  }, [game.delta(snapshot, player).to_json] ]
                end
              end
              [-1, {}, []]
            else
              # invalid move!
              game.disqualify(player)
              [403, {}, ["invalid move: #{error}. disqualified!"]]
            end
          else
            # not your turn!
            [403, {}, ["invalid/missing turn token"]]
          end
        else
          if game.state == 'initiating'
            # not yet allowed
            [403, {}, ["game not yet started"]]
          else
            # no longer available
            [410, {}, ["game finished"]]
          end
        end
      end
    end
  end
end
