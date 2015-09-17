require 'gameworks'
require_relative 'game'

module Pajitnov
  class Server < Gameworks::Server
    def game_class
      Pajitnov::Game
    end

    def process_request(request={})
      case request[:path]
        when %r{^/health-check$}
          [ 200, {}, [] ]
        else
          super(request)
      end
    end
  end
end
