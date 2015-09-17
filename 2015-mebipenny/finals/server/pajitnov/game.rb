require 'gameworks'
require_relative 'location'
require_relative 'move'
require_relative 'player'
require_relative 'game_snapshot'
require_relative 'piece'

module Pajitnov
  class Game < Gameworks::Game
    attr_reader :rows, :cols
    attr_reader :seats, :initial_garbage
    attr_reader :current_piece, :next_piece
    attr_accessor :turns_left

    def self.random(opts={})
      rows = rand(10) + 20
      cols = rand(12) + 8
      new({ 'rows' => rows, 'cols' => cols }.merge(opts))
    end

    def initialize(payload={})
      # sanity check payload
      unless payload.is_a?(Hash)
        @invalid = true
        return
      end

      # validate rows
      rows = payload['rows'] || 20
      unless rows.is_a?(Fixnum) and rows >= 1
        @invalid = true
        return
      end

      # validate cols
      cols = payload['cols'] || 10
      unless cols.is_a?(Fixnum) and cols >= 1
        @invalid = true
        return
      end

      # validate seats
      seats = payload['seats'] || 2
      unless seats.is_a?(Fixnum) and seats >= 1 and seats <= 4
        @invalid = true
        return
      end

      # validate initial_garbage
      initial_garbage = payload['initial_garbage'] || 0
      unless initial_garbage.is_a?(Fixnum) and initial_garbage >= 0 and initial_garbage <= rows
        @invalid = true
        return
      end

      # validate turns
      turns = payload['turns'] || nil
      unless turns.nil? or (turns.is_a?(Fixnum) and turns >= 1)
        @invalid = true
        return
      end

      super

      @rows = rows
      @cols = cols
      @seats = seats
      @turns_left = turns
      @initial_garbage = initial_garbage
      @current_piece = Piece.random
      @next_piece = Piece.random
      @disqualifieds = []

      update_observers
    end

    def valid?
      !@invalid
    end

    def full?
      @players.size >= @seats
    end

    def init_game
      super
      @moves = {}
    end

    def active_players
      @players.reject(&:disqualified?)
    end

    def player_class
      Pajitnov::Player
    end

    def add_player(payload={})
      super(payload.merge(
        'rows' => @rows,
        'cols' => @cols,
        'initial_garbage' => @initial_garbage,
      ))
    end

    def snapshot_class
      Pajitnov::Game::Snapshot
    end

    def player_changed?(player, snapshot, for_player=nil)
      super ||
      snapshot.player_board_hashes[player] != player.board.hash
    end

    def delta(snapshot, for_player=nil)
      super.merge(
        id: self.id,
        current_piece: @current_piece,
        next_piece: @next_piece
      )
    end

    def as_json(for_player=nil)
      super.merge(
        id: self.id,
        rows: @rows,
        cols: @cols,
        current_piece: @current_piece,
        next_piece: @next_piece,
        disqualified: @disqualifieds
      )
    end

    def location_value?(value)
      value.is_a?(Hash) and
      value.has_key?('row') and
      value.has_key?('col') and
      value['row'].is_a?(Fixnum) and
      value['col'].is_a?(Fixnum)
    end

    def build_move(payload, player)
      # validate input
      return false, "invalid move data (not a Hash)" unless payload.is_a?(Hash)
      return false, "invalid move data (no locations)" unless payload.has_key?('locations')

      locations = payload['locations']
      return false, "invalid locations (not an Array)" unless locations.is_a?(Array)
      return false, "invalid locations (size != 4)" unless locations.size == 4
      return false, "invalid locations (non-location values)" unless locations.all?{ |l| location_value?(l) }
      locations = locations.map{ |l| Pajitnov::Location.new(l['row'], l['col']) }

      Pajitnov::Move.new(@current_piece, locations)
    end

    def move_legal?(move, player)
      return false, "invalid move: player already moved this turn" if @moves[player]
      return false, "invalid move: player disqualified" if player.disqualified?
      return false, "invalid move: bad shape" unless move.valid_shape?
      return false, "invalid move: bad placement" unless player.valid_placement?(move)
      return false, "invalid move: drop obstructed" unless player.valid_drop?(move)
      return true
    end

    def disqualify(player)
      # DANGER: no super call.  This is a temporary hack until the game
      # framework supports the concept of a "round"
      @disqualifieds << player.id
      player.disqualify!
      update_observers
      if @players.select { |p| !p.disqualified? }.size < 2
        end_game
      elsif !waiting_on_moves?
        process_round
      end
      # else do nothing; waiting for other players
    end

    def record_move(move, player)
      @moves[player] = move
    end

    def move_recorded?(player)
      !@moves[player].nil?
    end

    def waiting_on_moves?
      active_players.any?{ |p| !move_recorded?(p) }
    end

    def process_move(move, player)
      record_move(move, player)
      process_round unless waiting_on_moves?
      return true
    end

    def process_round
      process_moves
      @turns_left -= 1 if @turns_left
      if @turns_left == 0 or (players.size > 1 and active_players.size < 2)
        # not solitaire, and no competition left, game over
        end_game
      else
        end_round
      end
    end

    def process_moves
      # add moves to players' boards, and note garbage handed out. but don't
      # add garbage yet, let all players' moves take effect first
      garbage = {}
      @moves.each do |player, move|
        cleared = player.add_move(move)
        if cleared > 1
          active_players.each do |p|
            next if p == player
            garbage[p] ||= 0
            garbage[p] += cleared == 4 ? cleared : cleared - 1
          end
        end
      end

      # add garbage to each player that got some, now that they've made
      # their move
      garbage.each do |player, amount|
        player.add_garbage(amount)
      end
    end

    def end_round
      @current_piece = @next_piece
      @next_piece = Piece.random
      @moves.clear
      signal_turns
    end
  end
end
