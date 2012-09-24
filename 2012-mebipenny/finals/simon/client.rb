require 'net/http'
require 'rubygems'
require 'json'

@host = "localhost"
@port = "3456"
@name = "Simon #{(rand() * 1000).round}"
@debug = true

def log_response(where, res)
  puts "--- #{where} ---"
  puts "Response: #{res.code}"
  puts "Token: #{res["X-Turn-Token"]}"
  puts res.body
  puts "--- -------- ---"
end

def get(path)
  req = Net::HTTP::Get.new(path)
  Net::HTTP.new(@host, @port).start { |http| http.request(req) }
end

def post(path, json, headers = nil)
  json = json.to_json if json.is_a?(Hash)
  req = Net::HTTP::Post.new(path, initheader = {'Content-Type' =>'application/json'})
  headers.each { |k,v| req.add_field(k,v) } if !headers.nil?
  req.body = json
  Net::HTTP.new(@host, @port).start { |http| http.request(req) }
end

# returns <game_path>
def create_game(rows, cols)
  response = post("/", { :rows => rows, :cols => cols })
  response['Location']
end

# returns <game_path>
def match_game
  response = get("/match")
  response['Location']
end

# returns [game, token]
def join_game(game_path)
  response = post("#{game_path}/players", { :name => @name })
  log_response("join", response) if @debug
  [JSON.parse(response.body), response['X-Turn-Token']] if response.code.to_i == 200
end

# returns game
def view_game(game_path)
  response = get(game_path)
  JSON.parse(response.body)
end

# returns [<game_delta>, token]
def make_move(game_path, move, token)
  response = post("#{game_path}/moves", move, { "X-Turn-Token" => token })
  log_response("move", response) if @debug
  [JSON.parse(response.body), response['X-Turn-Token']] if response.code.to_i == 200
end

# returns game
def update_game(game, game_delta)
  game['draw_size'] = game_delta['draw_size']
  game['state'] = game_delta['state']
  (game_delta['players'] || []).each do |player|
    game['players'].delete_if { |p| p['id'] == player['id'] }
    game['players'] << player
  end
  (game_delta['claims'] || []).each do |claim|
    game['claims'].delete_if { |c| c['tile'] == claim['tile'] }
    game['claims'] << claim
  end
  game
end

# returns <new_move>
def choose_move(game)
  me = game['players'].detect { |p| p['name'] == @name }
  { :tile => me['hand'].sample }
end

game_path = ARGV[0]
game_path ||= create_game(10,10) if ARGV[0] == 'create'
game_path ||= match_game
puts game_path if @debug || ARGV[0] == 'create'
puts "Joining Game as #{@name}" if @debug
game, token = join_game(game_path)
exit if token.nil?

puts "Entering Loop" if @debug
loop do
  puts "Choosing Move" if @debug
  move = choose_move(game)
  puts "Chose Move: #{move}" if @debug
  game_delta, token = make_move(game_path, move, token)
  break if token.nil?
  game = update_game(game, game_delta)
  puts "Current Game: #{game}" if @debug
  break if game['state'] == 'completed'
end
