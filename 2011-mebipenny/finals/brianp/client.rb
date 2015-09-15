name, host, port, gameid, ai = *ARGV

require 'net/http'
require 'json'

http = Net::HTTP.start(host, port)

preq = Net::HTTP::Post.new("/#{gameid}/players")
preq.body = {:name => name}.to_json
res = http.request(preq)
raise "couldn't join game: #{res.inspect}" unless res.code == '200'

require_relative ai
player = Object.const_get(ai.capitalize).new

game = JSON.parse(res.body)

while turn_token = res['X-Turn-Token']
  move = player.get_next_move(game)
  req = Net::HTTP::Post.new("/#{gameid}/moves")
  req.body = move.to_json
  puts move.to_json
  req['X-Turn-Token'] = turn_token
  res = http.request(req)
  raise "got bad response: #{res.inspect}" unless res.code == '200'
  new_game = JSON.parse(res.body)
  new_game.each do |k,v|
    if %w(lines hexagons).include?(k)
      game[k] += v
    else
      game[k] = v
    end
  end
end
