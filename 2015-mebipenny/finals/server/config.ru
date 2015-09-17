#!ruby

require_relative 'pajitnov/server'

use Rack::CommonLogger

module Rack
  class Lint
    def call(env = nil)
      @app.call(env)
    end
  end
end

run Pajitnov::Server.new
