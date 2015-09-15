host, port, name = *ARGV

require 'net/http'
require 'json'

http = Net::HTTP.start(host, port)

# request match
req = Net::HTTP::Get.new("/match")
res = http.request(req)
raise "couldn't find match: #{res.inspect}" unless res.code == '201'
game_path = res['Location']
puts "Joining game #{game_path}"

preq = Net::HTTP::Post.new("#{game_path}/players")
preq.body = {:name => name}.to_json
res = http.request(preq)
raise "couldn't join game: #{res.inspect}" unless res.code == '200'

require_relative 'so_smart'
player = So_smart.new
player.reset_game(JSON.parse(res.body))

while turn_token = res['X-Turn-Token']
  move = player.get_next_move
  req = Net::HTTP::Post.new("#{game_path}/moves")
  req.body = move.to_json
  puts req.body
  req['X-Turn-Token'] = turn_token
  res = http.request(req)
  raise "got bad response: #{res.inspect}" unless res.code == '200'
  player.update_game(JSON.parse(res.body))
end
