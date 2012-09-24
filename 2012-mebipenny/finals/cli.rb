require 'rubygems'
require 'net/http'
require 'json'

$host = 'localhost'
$port = 3000
$turn_token = nil

def post(url, body, turn_token=nil)
  request = Net::HTTP::Post.new(url)
  request.body = body.to_json
  request['X-Turn-Token'] = $turn_token if $turn_token

  response = Net::HTTP.start($host, $port) { |http| http.request(request) }
  unless response.kind_of?(Net::HTTPSuccess)
    p response
    puts response.read_body if response.read_body && !response.read_body.empty?
    exit
  end

  if response.read_body && !response.read_body.empty?
    data = JSON.parse(response.read_body)
    (data['players'] || []).each do |player|
      if player['hand'].is_a?(Array)
        puts "#{player['name']}'s hand:"
        player['hand'].each do |tile|
          puts "  (#{tile['row']}, #{tile['col']})"
        end
      else
        puts "#{player['name']}'s hand: #{player['hand']} tiles"
      end
    end

    if data['claims'] && !data['claims'].empty?
      puts "claims:"
      data['claims'].each do |claim|
        puts "  (#{claim['tile']['row']}, #{claim['tile']['col']}) ==> #{claim['owner']}"
      end
    end

    puts "draw left: #{data['draw_size']}"
  end

  $turn_token = response['X-Turn-Token']
  response
end

print "Game URL? "
gameroot = gets.chomp
if gameroot.empty?
  response = post "/", :rows => 5, :cols => 5
  gameroot = response['Location']
  puts "Created game at #{gameroot}"
end

print "Name? "
post "#{gameroot}/players", :name => gets.chomp

while $turn_token
  print "Your turn! Move [row col favor]? "
  row, col, favor = gets.split
  if row == 'PASS'
    move = 'PASS'
  else
    move = {:tile => {:row => row.to_i, :col => col.to_i}}
    move[:favor] = favor if favor
  end
  post("#{gameroot}/moves", move)
end

puts "Game Over!"
