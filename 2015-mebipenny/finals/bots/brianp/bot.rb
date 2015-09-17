require 'faraday'
require 'faraday_middleware'
require 'forwardable'

NAME = "brianp-bot"

PIECES = {}
Dir['pieces/*.txt'].each do |fname|
  # reverse because the server uses bottom-row-first
  data = File.read(fname).chomp.split("\n").reverse
  piece = []
  data.each_with_index do |line, y|
    line.each_char.each_with_index do |i, x|
      if i != ' '
        piece << { row: y, col: x }
      end
    end
  end
  raise("bad piece: #{fname}") unless piece.size == 4

  ptype = File.basename(fname).split("_").first.upcase
  PIECES[ptype] ||= []
  PIECES[ptype] << piece.freeze
end

conn = Faraday.new(url: 'http://pajitnov.inseng.net') do |faraday|
  faraday.request :json
  # faraday.response :logger
  faraday.response :json, content_type: /\bjson$/
  faraday.adapter Faraday.default_adapter
end

if ARGV[0] && ARGV[0].length > 2
  game_id = ARGV[0]
else
  res = conn.post('/', { seats: (ARGV[0] || 1).to_i, initial_garbage: 5 })
  game_id = res['Location']
end
puts game_id

class Game
  extend Forwardable
  def_delegator :@data, :[]

  attr_reader :request, :data

  def initialize(request)
    @request = request
    @data = request.body
  end

  def find_move
    piece_name = self['current_piece']
    configs = PIECES[piece_name]
    raise("need #{piece_name}") unless configs

    valid_moves = possible_moves(board, configs).select { |move| valid_move?(board, move) }
    move = rank_moves(board, valid_moves).last
    puts "playing move with score #{score_move(board, move)}" if move
    move
  end

  def rank_moves(board, moves)
    moves.sort_by { rand }.sort_by do |move|
      score_move(board, move)
    end
  end

  def score_move(board, move)
    board = board.map(&:dup)
    move.each { |location| board[location[:row]][location[:col]] = 'X' }
    score = 0
    # we love making rows, even single rows
    score += 100 * board.count { |row| row.all? { |i| !i.nil? } }
    # prefer playing lower on the board
    score -= move.map { |location| location[:row] }.inject(:+)
    # we hate covering up blank spaces
    board.each_with_index { |row,y| row.each_with_index { |i,x| score -= 10 if !i && board[y+1] && board[y+1][x] } }
    score
  end

  def valid_move?(board, locations)
    locations.all? { |location|
      y = location[:row]
      x = location[:col]

      y >= 0 && y < rows &&
      x >= 0 && x < cols &&
      board[y][x].nil? &&
      board[y,rows].all? { |row| row[x].nil? }
    } && locations.any? { |location|
      y = location[:row]
      x = location[:col]

      # make sure there's a supported block
      board[y-1][x] || (y-1 < 0)
    }
  end

  def possible_moves(board, configs)
    configs.map do |config|
      (0..rows).map do |y|
        (0..cols).map do |x|
          config.map { |pos| pos = pos.dup; pos[:row] += y; pos[:col] += x; pos }
        end
      end
    end.flatten(2)
  end

  def rows
    20
  end

  def cols
    10
  end

  def board
    @board ||= player_info['board'].map { |row| row.freeze }.freeze
  end

  def last_move
    player_info['last_move']
  end

  def player_info
    self['players'].find { |p| p['id'] == player_id }
  end

  def player_id
    $player_id ||= request['X-Player-Id']
  end
end

def read_game(response)
  if response.status > 300
    raise("failure: #{response.inspect}")
  end
  Game.new(response)
end

def print_board(game)
  boards = game['players'].sort_by { |player| [player['id'] == game.player_id ? 0 : 1, player['id']] }.map do |player|
    board = player['board'].map { |line| line.map { |i| (i || '.') } }
    (player['last_move'] || []).each { |location| board[location['row']][location['col']].sub!(/.*/, "\e[31m\\0\e[0m") }
    board.reverse.map { |line| line.map { |i| i * 1 }.join }
  end
  game.rows.times do |i|
    boards.each { |b| print(b[i]); print("  ") }
    puts
  end
  puts("\e[32mscore: %6d  lines: %4d  state: %s\e[0m" %
    [game.player_info['score'], game.player_info['lines'], game['state']])
end

game = read_game(conn.post("#{game_id}/players", { name: NAME }))
print_board(game)

loop do
  start_time = Time.now
  locations = game.find_move
  game = read_game(conn.post("#{game_id}/moves",
    { locations: locations },
    'X-Turn-Token': game.request['X-Turn-Token']))
  puts "\033[23A"
  print_board(game)
end