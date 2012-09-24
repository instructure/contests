require 'finals-framework/player'
require 'finals-framework/game_snapshot'
require 'finals-framework/fuse'
require 'finals-framework/ruby-uuid/uuid'

module FinalsFramework
  class Game
    TURN_TIME_LIMIT = 30
    DEFAULT_DELAY = 0.3

    attr_reader :players, :state, :id, :delay_time

    def initialize(payload={})
      @players = []
      @state = 'initiating'
      @delay_time = payload['delay_time'] || DEFAULT_DELAY
      @tokens = {}
      @observers = {}
      @id = generate_uuid.split('-').first
    end

    def register_observer(cb)
      token = generate_uuid
      @observers[token] = [self.snapshot, cb]
      token
    end

    def update_observers(end_game = false)
      @observers.each do |token, (_, cb)|
        snapshot = snapshot_for_observer(token)
        cb.call(delta(snapshot).to_json)
        cb.succeed if end_game
      end
    end

    def snapshot_for_observer(token)
      snapshot = nil
      if @observers.has_key?(token)
        snapshot, cb = @observers[token]
        @observers[token][0] = self.snapshot
      end
      snapshot
    end

    def player_changed?(player, snapshot, for_player=nil)
      player.score != snapshot.player_scores[player]
    end

    def delta(snapshot, for_player=nil)
      { :players => @players.select{ |p| player_changed?(p, snapshot, for_player) }.map{ |p| p.as_json(for_player) },
        :state   => @state }
    end

    def full?
      raise "not implemented"
    end

    def player_class
      FinalsFramework::Player
    end

    def add_player(payload={})
      return false if full?

      player = player_class.new(payload)
      return false unless player.valid?

      @players << player
      if full?
        # shuffle the players
        init_game
        @state = 'in play'
        start_next_turn
      end
      update_observers
      player
    end

    def init_game
      @players.shuffle!
    end

    def generate_uuid
      UUID.create_random.to_s
    end

    def start_next_turn
      while @players.first.disqualified?
        @players << @players.shift
      end
      @current_player = @players.first
      token = generate_uuid
      @tokens[@current_player] = token
      @fuse.abort if @fuse
      @fuse = FinalsFramework::Fuse.new(TURN_TIME_LIMIT) { disqualify(@current_player) }
      @current_player.signal_turn(token)
    end

    def continue_turn
      # leave @current_player alone
      token = generate_uuid
      @tokens[@current_player] = token
      @fuse.abort if @fuse
      @fuse = FinalsFramework::Fuse.new(TURN_TIME_LIMIT) { disqualify(@current_player) }
      @current_player.signal_turn(token)
    end

    def end_turn
      if @current_player
        raise unless @players.first == @current_player
        @players << @players.shift
      end
      start_next_turn
    end

    def current_player(token)
      return unless token == @tokens[@current_player]
      @current_player
    end

    def build_move(payload)
      raise "not implemented"
    end

    def add_move(payload)
      # add move
      move, error = build_move(payload)
      return false, error unless move
      legal, error = move_legal?(move)
      return false, error unless legal
      legal, error = process_move(move)
      return false, error unless legal
      update_observers
      return true
    end

    def move_legal?(move)
      raise "not implemented"
    end

    def disqualify(player)
      player.score = 'disqualified'
      update_observers
      if @players.select { |p| !p.disqualified? }.size < 2
        end_game
      else
        update_observers
        end_turn
      end
    end

    def end_game
      @state = 'completed'
      @fuse.abort if @fuse
      update_observers(true)
      @players.each{ |p| p.signal_turn(nil) }
    end

    def snapshot_class
      FinalsFramework::Snapshot
    end

    def snapshot
      snapshot_class.new(self)
    end

    def as_json(for_player=nil)
      { :players => @players.map{ |player| player.as_json(for_player) },
        :state   => @state }
    end

    def to_json(for_player=nil)
      as_json(for_player).to_json
    end
  end
end
