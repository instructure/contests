#!ruby

require_relative 'territory/server'
use Rack::CommonLogger

# Override Lint middleware to handle async callback (-1 http response)
module Rack
  class Lint
    def call(env = nil)
      @app.call(env)
    end
  end
end

run Territory::Server.new
