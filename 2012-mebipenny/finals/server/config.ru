#!ruby

$LOAD_PATH << File.dirname(__FILE__)

require 'territory/server'
use Rack::CommonLogger
run Territory::Server.new
