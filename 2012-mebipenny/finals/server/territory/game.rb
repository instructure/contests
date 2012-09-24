require 'finals-framework/game'
require 'territory/tile'
require 'territory/claim'
require 'territory/move'
require 'territory/player'
require 'territory/game_snapshot'

module Territory
  class Game < FinalsFramework::Game
    attr_reader :rows, :cols, :claims, :draw

    def self.random(opts={})
      rows = rand(10) + 15
      cols = rand(10) + 15
      seed_coverage = rand * 0.2
      new({ 'rows' => rows, 'cols' => cols, 'seed_coverage' => seed_coverage }.merge(opts))
    end

    def initialize(payload={})
      unless payload.is_a?(Hash) and
             payload.has_key?('rows') and
             payload.has_key?('cols') and
             payload['rows'].is_a?(Fixnum) and
             payload['cols'].is_a?(Fixnum)
        @invalid = true
        return
      end

      rows = payload['rows']
      cols = payload['cols']
      seed_coverage = payload['seed_coverage'] || 0.0
      seats = payload['seats'] || 2
      unless seats.is_a?(Fixnum) and
             seats >= 2 and seats <= 4 and
             seed_coverage.is_a?(Numeric) and
             seed_coverage >= 0 and seed_coverage <= 1
        @invalid = true
        return
      end

      super
      @rows = rows
      @cols = cols
      @seats = seats
      @claims = {}
      @draw = []

      rows.times do |i|
        @claims[i] = {}
        cols.times do |j|
          @draw << Territory::Tile.new(i, j)
        end
      end

      @draw.shuffle!

      (rows * cols * seed_coverage).to_i.times{ generate_claim(@draw.shift, nil) }
    end

    def generate_claim(tile, owner)
      claim = Territory::Claim.new(tile, owner)
      @claims[tile.row][tile.col] = claim
      claim
    end

    def valid?
      !@invalid
    end

    def full?
      @players.size >= @seats
    end

    def init_game
      super
      6.times do
        break if @draw.empty?
        @players.each do |player|
          break if @draw.empty?
          player.hand << @draw.shift
        end
      end
    end

    def build_move(payload)
      # validate input
      return Territory::Move::PASS if payload == 'PASS'
      return false, "invalid move data" unless payload.is_a?(Hash)
      return false, "invalid move data" unless payload.has_key?('tile')

      tile = payload['tile']
      return false, "invalid tile data" unless tile.is_a?(Hash)
      return false, "invalid tile data" unless tile.has_key?('row')
      return false, "invalid tile data" unless tile.has_key?('col')
      return false, "invalid tile data" unless tile['row'].is_a?(Fixnum)
      return false, "invalid tile data" unless tile['col'].is_a?(Fixnum)
      tile = Territory::Tile.new(tile['row'], tile['col'])

      favor = payload['favor'] || @current_player.id
      favor = @players.detect{ |p| p.id == favor }

      Territory::Move.new(tile, favor)
    end

    def move_legal?(move)
      return true if move == Territory::Move::PASS
      return false, "invalid tile coordinates" unless (0...rows).include?(move.tile.row) && (0...cols).include?(move.tile.col)
      return false, "tile already claimed" if @claims[move.tile.row][move.tile.col]
      return false, "tile not in hand" unless @current_player.hand.any?{ |tile| tile == move.tile }
      return true
    end

    def process_move(move)
      @current_player.passed = (move == Territory::Move::PASS)

      unless @current_player.passed
        @current_player.hand.delete(move.tile)

        # add the claim to the board with its nominal owner
        claim = generate_claim(move.tile, @current_player)
        @current_player.score += 1

        # see if there's a capture
        army = army_for(claim)
        factions = army.group_by{ |claim| claim.owner }

        if factions.size > 1
          # more than one player represented in new army, determine who captures
          biggest_faction_count = factions.map{ |player,claims| claims.size }.sort.last
          winning_players = factions.keys.select{ |player| factions[player].size == biggest_faction_count }
          if winning_players.size > 1
            # more than one player tied for most territory in new army, decide by
            # move
            return([false, "favored minor faction"]) unless winning_players.include?(move.favor)
            winning_player = move.favor
          else
            # just one player with most territory, he wins
            winning_player = winning_players.first
          end

          # move all claims from other factions in the new army to the winning
          # player
          factions.each do |player,claims|
            next if player == winning_player
            claims.each{ |claim| claim.owner = winning_player }
            player.score -= claims.size unless player.disqualified?
            winning_player.score += claims.size unless winning_player.disqualified?
          end
        end

        # draw replacement tile, if any
        @current_player.hand << @draw.shift unless @draw.empty?
      end

      # check for end game conditions
      if @players.all?{ |p| p.passed || p.disqualified? }
        end_game
      elsif @players.all?{ |p| p.hand.empty? || p.disqualified? }
        end_game
      else
        end_turn
      end

      return true
    end

    def army_for(claim)
      seen = Set.new
      seen << claim
      queue = [claim]
      army = []

      while claim = queue.pop
        # pop queue into army
        army << claim

        [:east, :west, :north, :south].each do |dir|
          neighbor_tile = claim.tile.neighbor(dir)
          neighbor = @claims[neighbor_tile.row] && @claims[neighbor_tile.row][neighbor_tile.col]

          # ignore if it isn't claimed, it's claimed by the map, or we already
          # saw it
          next unless neighbor && neighbor.owner
          next if seen.include?(neighbor)

          # mark as seen and add to queue
          seen << neighbor
          queue << neighbor
        end
      end

      # done
      army
    end

    def flat_claims
      @claims.values.map{ |column| column.values }.flatten
    end

    def player_class
      Territory::Player
    end

    def snapshot_class
      Territory::Game::Snapshot
    end

    def player_changed?(player, snapshot, for_player=nil)
      super ||
      snapshot.player_hands[player].size != player.hand.size ||
      (player == for_player && snapshot.player_hands[player] != player.hand.map{ |tile| tile.as_json })
    end

    def delta(snapshot, for_player=nil)
      super.merge(
        :draw_size => @draw.size,
        :claims => snapshot_class.new(self).claims - snapshot.claims
      )
    end

    def as_json(for_player=nil)
      super.merge({
        :rows      => @rows,
        :cols      => @cols,
        :draw_size => @draw.size,
        :claims    => flat_claims.map{ |claim| claim.as_json },
        :players   => @players.map{ |player| player.as_json(for_player) },
        :player_id => for_player && for_player.id,
      })
    end

    def to_json(for_player=nil)
      as_json(for_player).to_json
    end
  end
end
