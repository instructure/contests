require 'finals-framework/servlet/base'

module FinalsFramework
  module Servlet
    class GameView < FinalsFramework::Servlet::Base
      def GET(request)
        game_id = request[:path].split('/')[1]
        game = @server.game_registry.instance(game_id)
        return [404, {}, ["no such game"]] unless game

        snapshot = nil
        if request[:tokens][:observer]
          snapshot = game.snapshot_for_observer(request[:tokens][:observer])
        end

        if snapshot
          [ 200, { 'Content-Type' => 'application/json' }, [game.delta(snapshot).to_json] ]
        else
          [ 200, { 'Content-Type' => 'application/json' }, [game.to_json] ]
        end
      end
    end
  end
end
