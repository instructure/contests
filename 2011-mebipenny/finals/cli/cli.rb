require 'rubygems'
require 'net/http'
require 'json'

print "Name? "
name = gets.chomp

host = 'localhost'
port = 3000
gameid = ARGV.first

request = Net::HTTP::Post.new("/#{gameid}/players")
request.body = {:name => name}.to_json
response = Net::HTTP.start(host, port) { |http| http.request(request) }
p response
puts response.read_body

unless response.kind_of?(Net::HTTPSuccess)
  puts "FAIL"
  exit
end

while turn_token = response['X-Turn-Token']
  print "Your turn! Move? "
  r1, c1, r2, c2 = gets.split.map{ |x| x.to_i }

  request = Net::HTTP::Post.new("/#{gameid}/moves")
  request.body = [{:row => r1, :col => c1}, {:row => r2, :col => c2}].to_json
  request['X-Turn-Token'] = turn_token
  response = Net::HTTP.start(host, port) { |http| http.request(request) }
  p response
  puts response.read_body

  unless response.kind_of?(Net::HTTPSuccess)
    puts "FAIL"
    exit
  end
end

puts "Game Over!"
