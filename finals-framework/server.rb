require 'json'
require 'finals-framework/game_registry'
require 'finals-framework/servlet/add_player'
require 'finals-framework/servlet/add_move'
require 'finals-framework/servlet/add_observer'
require 'finals-framework/servlet/game_view'
require 'finals-framework/servlet/game_list'
require 'finals-framework/servlet/match_maker'

module FinalsFramework
  class Server
    attr_reader :game_registry

    def initialize
      @game_registry = FinalsFramework::GameRegistry.new
    end

    def game_class
      raise NotImplemented
    end

    def call(env)
      tokens = {}
      env.each do |key,value|
        case key
        when "HTTP_X_TURN_TOKEN"
          tokens[:turn] = value
        when "HTTP_X_OBSERVER_TOKEN"
          tokens[:observer] = value
        end
      end
      body = env["rack.input"].read
      unless body.empty?
        payload = JSON.parse("[#{body}]").first
      end
      process_request(
        :method => env["REQUEST_METHOD"],
        :path => env["REQUEST_PATH"],
        :payload => payload,
        :tokens => tokens,
        :async_cb => env['async.callback'])
    end

    def process_request(request={})
      handler = case request[:path]
        when %r{^/$}                then FinalsFramework::Servlet::GameList
        when %r{^/match$}           then FinalsFramework::Servlet::MatchMaker
        when %r{^/[^/]+/?$}         then FinalsFramework::Servlet::GameView
        when %r{^/[^/]+/players$}   then FinalsFramework::Servlet::AddPlayer
        when %r{^/[^/]+/moves$}     then FinalsFramework::Servlet::AddMove
        when %r{^/[^/]+/observers$} then FinalsFramework::Servlet::AddObserver
      end

      if handler
        begin
          handler.process(self, request)
        rescue Exception => e
          puts e.inspect
          puts e.backtrace
          [ 500, {}, [] ]
        end
      else
        [ 404, {}, [] ]
      end
    end
  end
end
