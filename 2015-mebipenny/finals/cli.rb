require 'rubygems'
require 'net/http'
require 'json'

$host = 'pajitnov.inseng.net'
$port = 443
$turn_token = nil

def print_game(data)
  puts "New Current Piece: #{data['current_piece']}"
  puts "New Next Piece: #{data['next_piece']}"
  puts

  (data['players'] || []).each do |player|
    puts "#{player['name']}'s new board:"
    player['board'].reverse.each do |row|
      puts row.map{ |val| val || '.' }.join('')
    end
    puts player['board'].first.size.times.map{ '-' }.join('')
    puts "Lines: #{player['lines']} -- Score: #{player['score']}"
    puts
  end
end

def post(url, body, turn_token=nil)
  request = Net::HTTP::Post.new(url)
  request.body = body.to_json
  request['X-Turn-Token'] = $turn_token if $turn_token

  response = Net::HTTP.start($host, $port, read_timeout: 300, use_ssl: true) { |http| http.request(request) }
  unless response.kind_of?(Net::HTTPSuccess)
    p response
    puts response.read_body if response.read_body && !response.read_body.empty?
    exit
  end

  if response.read_body && !response.read_body.empty?
    data = JSON.parse(response.read_body)
    print_game(data)
  end

  $turn_token = response['X-Turn-Token']
  response
end

print "Game URL? "
gameroot = gets.chomp
if gameroot.empty?
  response = post "/", seats: 1
  gameroot = response['Location']
  puts "Created game at #{gameroot}"
end

print "Name? "
post "#{gameroot}/players", name: gets.chomp

while $turn_token
  print "Your turn! Move [row col row col row col row col]? "
  row1, col1, row2, col2, row3, col3, row4, col4 = gets.split
  move = {locations: [
    {row: row1.to_i, col: col1.to_i},
    {row: row2.to_i, col: col2.to_i},
    {row: row3.to_i, col: col3.to_i},
    {row: row4.to_i, col: col4.to_i},
  ]}
  post("#{gameroot}/moves", move)
end

puts "Game Over!"
