require 'finals-framework/servlet/base'

module FinalsFramework
  module Servlet
    class MatchMaker < FinalsFramework::Servlet::Base
      class Promise
        def initialize
          @em_queue = EventMachine::Queue.new
        end

        def demand
          @em_queue.pop{ |value| yield value }
        end

        def fulfill(value)
          @em_queue.push(value)
        end
      end

      class << self
        attr_accessor :server

        SEATS = 2

        # on the class because I want it persistent
        def request_game(&blk)
          promise = Promise.new
          promise.demand(&blk)
          queue.push(promise)
        end

        protected
        def queue
          unless @queue
            @queue = EventMachine::Queue.new
            find_match
          end
          @queue
        end

        def find_match
          match = []
          SEATS.times do
            queue.pop do |request|
              match << request
              if match.size == SEATS
                run_match(match)
                find_match
              end
            end
          end
        end

        def run_match(match)
          game = server.game_class.random('seats' => SEATS)
          server.game_registry.add(game)
          match.each{ |request| request.fulfill(game) }
        end
      end

      def GET(request)
        MatchMaker.server ||= @server
        MatchMaker.request_game do |game|
          request[:async_cb].call [201, {'Location' => "/#{game.id}"}, []]
        end
        [-1, {}, []]
      end
    end
  end
end
