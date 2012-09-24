require 'finals-framework/servlet/base'

module FinalsFramework
  module Servlet
    class AddObserver < FinalsFramework::Servlet::Base
      AsyncResponse = [-1, {}, []].freeze

      class DeferrableBody
        include EventMachine::Deferrable

        def initialize(wrapper)
          @wrapper = wrapper || "%s"
        end

        def call(json_chunk)
          document = json_chunk.gsub("\n", ' ') + "\n"
          @body_callback.call(@wrapper % [document])
        end

        def each(&blk)
          @body_callback = blk
        end
      end

      def POST(request)
        game_id = request[:path].split('/')[1]
        game = @server.game_registry.instance(game_id)
        return [404, {}, ["no such game"]] unless game
        wrapper = (request[:payload] || {})['wrapper']
        body = DeferrableBody.new(wrapper)
        token = game.register_observer(body)

        # application/x-multi-json if a format i just made up,
        # which is a series of json documents separated by newlines
        # (there will be no newlines within the json document)
        request[:async_cb].call [200,
          {'Content-Type' => 'application/x-multi-json',
           'X-Observer-Token' => token}, body]
        body.call(game.to_json)
        AsyncResponse
      end
    end
  end
end
