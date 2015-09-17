#!/usr/bin/env ruby

# super stupid bot; all it does is find the first valid play for any piece,
# without attempting to rotate it

require 'net/http'
require 'uri'
require 'json'

module Server
  HOST = 'pajitnov.inseng.net'
  PORT = 443

  class << self
    def http
      client = Net::HTTP.new(Server::HOST, Server::PORT)
      client.use_ssl = true if Server::PORT == 443
      client
    end

    def POST(path, params={}, headers={})
      request = Net::HTTP::Post.new(path)
      request.body = params.to_json if params and not params.empty?
      headers.each{ |key, value| request[key] = value } if headers and not headers.empty?
      response = http.request(request)
      response
    end
  end
end

class Location
  attr_accessor :row, :col

  def initialize(state, board)
    @board = board
    @topmost = @board.topmost
    @row = state['row']
    @col = state['col']
  end

  def above
    (@row+1..@topmost).map{ |row| Location.new({'row' => row, 'col' => @col}, @board) }
  end

  def below

  end

  def as_json
    {row: @row, col: @col}
  end

  def to_json
    as_json.to_json
  end
end

class Move
  attr_reader :locations, :support, :above

  def initialize(state, board)
    @rightmost = board.rightmost
    @topmost = board.topmost
    @locations = state['locations'].map{ |location| Location.new(location, board) }
    @support = @locations.group_by{ |l| l.col }.map{ |col,locs| Location.new({'row' => locs.map(&:row).min - 1, 'col' => col}, board) }
    @above = @support.map{ |l| (l.row+1..@topmost).map{ |row| Location.new({'row' => row, 'col' => l.col}, board) } }.flatten
  end

  def shift
    cols = @locations.map(&:col)
    rows = @locations.map(&:row)
    if cols.all?{ |c| c < @rightmost }
      @locations.each{ |l| l.col += 1 }
      @support.each{ |l| l.col += 1 }
      @above.each{ |l| l.col += 1 }
      true
    elsif rows.all?{ |r| r < @topmost }
      rewind = cols.min
      @locations.each{ |l| l.col -= rewind; l.row += 1 }
      @support.each{ |l| l.col -= rewind; l.row += 1 }
      @above.each{ |l| l.col -= rewind; l.row += 1 }
      @above.reject!{ |l| l.row > @topmost }
      true
    end
  end

  def self.dense(board, *locations)
    new({'locations' => locations.map{ |row,col| {'row' => row, 'col' => col}}}, board)
  end

  def self.mask_for(piece, board)
    case piece
    when 'I' then Move.dense(board, [0, 0], [1, 0], [2, 0], [3, 0])
    when 'J' then Move.dense(board, [0, 0], [0, 1], [1, 1], [2, 1])
    when 'L' then Move.dense(board, [0, 0], [0, 1], [1, 0], [2, 0])
    when 'S' then Move.dense(board, [0, 0], [0, 1], [1, 1], [1, 2])
    when 'Z' then Move.dense(board, [0, 0], [1, 0], [1, 1], [2, 1])
    when 'T' then Move.dense(board, [0, 0], [0, 1], [0, 2], [1, 1])
    when 'O' then Move.dense(board, [0, 0], [0, 1], [1, 0], [1, 1])
    end
  end

  def as_json
    {locations: @locations.map{ |l| l.as_json }}
  end

  def to_json
    as_json.to_json
  end
end

class Board
  attr_reader :topmost, :rightmost

  def update(state)
    @state = state
    @topmost = state.size - 1
    @rightmost = state[0].size - 1
  end

  def at(location)
    @state[location.row][location.col]
  end

  def valid?(move)
    move.support.any?{ |l| l.row < 0 or at(l) } and
    move.above.all?{ |l| not at(l) }
  end

  def next_valid_placement(piece)
    move = Move.mask_for(piece, self)
    loop do
      return move if valid?(move)
      break unless move.shift
    end
  end
end

class Player
  attr_reader :board

  def initialize
    @board = Board.new
  end

  def update(state)
    @board.update(state['board'])
    @id = state['id']
    @name = state['name']
    @disqualified = state['disqualified']
    @score = state['score']
    @lines = state['lines']
    @last_move = Move.new({'locations' => state['last_move']}, @board) if state['last_move']
  end
end

class Game
  attr_reader :current_piece

  def initialize
    @players = {}
  end

  def update(state)
    @state = state['state']
    @rows = state['rows']
    @cols = state['cols']
    @current_piece = state['current_piece']
    @next_piece = state['next_piece']
    state['players'].each do |player|
      id = player['id']
      @players[id] ||= Player.new
      @players[id].update(player)
    end
  end

  def player(id)
    @players[id]
  end

  def active?
    @state == 'in play'
  end
end

class Agent
  def initialize(name)
    @name = name
    @game = Game.new
  end

  def start_solo_game
    response = Server.POST('/', seats: 1, initial_garbage: 0)
    join_game(response['Location'])
  end

  def join_game(location)
    @location = location
    response = Server.POST(@location + '/players', name: @name)
    @turn_token = response['X-Turn-Token']
    @player_id = response['X-Player-Id']
    update_game(JSON.parse(response.body))
    @player = @game.player(@player_id)
    @board = @player.board
  end

  def update_game(game)
    @game.update(game)
  end

  def run
    while @game.active?
      move = @board.next_valid_placement(@game.current_piece)
      # no move = make intentionally invalid move, can't win
      move = move ? move.as_json : {}
      response = Server.POST(@location + '/moves', move, 'X-Turn-Token' => @turn_token)
      unless response.code == '200'
        puts response.body
        break
      end
      @turn_token = response['X-Turn-Token']
      update_game(JSON.parse(response.body))
    end
  end
end


agent = Agent.new('jacob bot')
if location = ARGV.first
  agent.join_game(location)
else
  agent.start_solo_game
end

agent.run
