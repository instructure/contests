require 'rubygems'
require 'nestful'
require 'json'
require 'pp'

module GreedyHex
  def self.play(name, host="localhost", port=3000, game_id=nil)
    
    unless game_id
      http = Net::HTTP.start(host, port)
      req = Net::HTTP::Get.new("/match")
      res = http.request(req)
      raise "couldn't find match: #{res.inspect}" unless res.code == '201'
      game_id = res['Location']
      puts "Joining game #{game_id}"
    end

    #unless game_id
    #  res = Nestful.json_get("#{host}:#{port}/match")
    #  pp res
    #  game_id = res.response['Location'] 
    #end
    
    base = "#{host}:#{port}#{game_id}/%s"
    player_url = base % 'players'
    move_url = base % 'moves'
    puts base
    puts base

    body = Nestful.post(player_url, :format => :json, :params => {:name => name}, :headers => {})
    pp body

    unless body.response.kind_of?(Net::HTTPSuccess)
      puts "FAIL"
      exit
    end
    
    game = GreedyHex::Game.new(body["rows"], body["cols"])
    body['lines'].each do |line|
      points = line['endpoints']
      game.add_line_by_points(points.first['row'], points.first['col'], points.last['row'], points.last['col'])
    end

    while turn_token = body.response['X-Turn-Token']
      body = Nestful.post(move_url,
                          :format => :json,
                          :params => game.next_move,
                          :headers => {'X-Turn-Token' => turn_token})
      pp body

      unless body.response.kind_of?(Net::HTTPSuccess)
        puts "FAIL"
        exit
      end
      
      body['lines'].each do |line|
        points = line['endpoints']
        game.add_line_by_points(points.first['row'], points.first['col'], points.last['row'], points.last['col'])
      end
      
    end

    puts "Game Over!"
  end
end

require 'greedy_hex/coord'
require 'greedy_hex/hexagon'
require 'greedy_hex/line'
require 'greedy_hex/game'