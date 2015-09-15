require 'gameworks'
require_relative 'line'
require_relative 'coordinate'
require_relative 'hexagon'
require_relative 'game_snapshot'

module Hexagons
  class Game < Gameworks::Game
    attr_reader :rows, :cols, :lines, :hexagons

    def self.random(opts={})
      rows = rand(5) * 2 + 5
      cols = rand(7) - 3 + rows
      seed_coverage = 0#rand * 0.4
      new({ 'rows' => rows, 'cols' => cols, 'seed_coverage' => seed_coverage }.merge(opts))
    end

    def initialize(payload={})
      unless payload.is_a?(Hash) and
             payload.has_key?('rows') and
             payload.has_key?('cols') and
             payload['rows'].is_a?(Fixnum) and
             payload['cols'].is_a?(Fixnum) and
             payload['rows'] % 2 == 1
        @invalid = true
        return
      end

      rows = payload['rows']
      cols = payload['cols']
      seed_coverage = payload['seed_coverage'] || 0.0

      super
      @rows = rows
      @cols = cols
      @lines = []
      @hexagons = []

      lines = 2 * (rows - 1) * (cols - 1) + ((rows + 1) / 2) * (cols - 2) + ((rows - 1) / 2) * (cols - 1)
      (lines * seed_coverage).to_i.times{ add_random_line }
    end

    def valid?
      !@invalid
    end

    def add_random_line
      # choose random line
      row = rand(@rows)
      col = rand(@cols - 1 + (row % 2))
      first = Hexagons::Coordinate.new(row, col)
      neighbors = neighborhood(first)
      index = rand(neighbors.size)
      second = neighbors[index]
      line = Hexagons::Line.new(first, second)

      # add line; just skip if it's a dup
      legal, error = move_legal?(line)
      return unless legal
      @lines << line

      # undo if it would complete a hex
      hexes = neighborhood(line.first) & neighborhood(line.last)
      @lines.pop if hexes.any?{ |center| hex_complete?(center) }
    end

    def full?
      @players.size >= 2
    end

    def active_players
      [@players.reject(&:disqualified?).first]
    end

    def build_move(payload, player)
      # validate input
      return false, "invalid line data" unless payload.is_a?(Array)
      return false, "invalid line data" unless payload.size == 2
      coordinates = payload.map do |coord|
        return false, "invalid line data" unless coord.is_a?(Hash)
        return false, "invalid line data" unless coord.has_key?('row')
        return false, "invalid line data" unless coord.has_key?('col')
        return false, "invalid line data" unless coord['row'].is_a?(Fixnum)
        return false, "invalid line data" unless coord['col'].is_a?(Fixnum)
        Hexagons::Coordinate.new(coord['row'], coord['col'])
      end

      # the line is the move
      line = Hexagons::Line.new(*coordinates)
      line.owner = player
      line
    end

    def process_move(line, player)
      @lines << line

      # add any completed hexes
      candidate_hex_centers = neighborhood(line.first) & neighborhood(line.last)
      new_hex_centers = candidate_hex_centers.select{ |center| hex_complete?(center) }
      new_hex_centers.each do |center|
        @hexagons << Hexagons::Hexagon.new(center, player)
      end
      player.score += new_hex_centers.size

      # next state
      if !more_hexagons_possible?
        end_game
      else
        if new_hex_centers.empty?
          @players << players.shift
          signal_turns
        else
          signal_turns
        end
      end

      return true
    end

    def snapshot_class
      Hexagons::Game::Snapshot
    end

    def move_legal?(line, _ = nil)
      return false, "line already placed" if @lines.include?(line)
      first_s, last_s = line.first.as_json.inspect, line.last.as_json.inspect
      return false, "endpoint #{first_s} not on board" unless coordinate_legal?(line.first)
      return false, "endpoint #{last_s} not on board" unless coordinate_legal?(line.last)
      return false, "endpoints #{first_s} and #{last_s} are not adjacent" unless neighborhood(line.first).include?(line.last)
      return false, "line falls within claimed hex" if line_in_existing_hex?(line)
      return true
    end

    def line_in_existing_hex?(line)
        !([line.first, line.last] & @hexagons.map{ |h| h.center }).empty?
    end

    def coordinate_legal?(coordinate)
      boundary = @cols
      boundary -= 1 if (coordinate.row % 2).zero?
      coordinate.row >= 0 && coordinate.row < @rows &&
      coordinate.col >= 0 && coordinate.col < boundary
    end

    def neighborhood(coordinate)
      # adjacent vertices on the board in CW order
      shift = (coordinate.row + 1) % 2
      [ Hexagons::Coordinate.new(coordinate.row, coordinate.col - 1),
        Hexagons::Coordinate.new(coordinate.row - 1, coordinate.col + shift - 1),
        Hexagons::Coordinate.new(coordinate.row - 1, coordinate.col + shift),
        Hexagons::Coordinate.new(coordinate.row, coordinate.col + 1),
        Hexagons::Coordinate.new(coordinate.row + 1, coordinate.col + shift),
        Hexagons::Coordinate.new(coordinate.row + 1, coordinate.col + shift - 1) ].
        select{ |c| coordinate_legal?(c) }
    end

    def hex_complete?(center)
      vertices = neighborhood(center)
      vertices.size == 6 && (0...6).all? do |i|
        line = Line.new(vertices[i], vertices[(i+1) % 6])
        @lines.include?(line) && !line_in_existing_hex?(line)
      end
    end

    def more_hexagons_possible?
      # check every grid point
      @rows.times do |row|
        boundary = @cols
        boundary -= 1 if (row % 2).zero?
        boundary.times do |col|
          center = Hexagons::Coordinate.new(row, col)
          neighbors = neighborhood(center)
          next if neighbors.size < 6 # exclude edges
          next if hex_complete?(center) # exclude already completed hexes
          next if neighbors.any?{ |other| hex_complete?(other) } # exclude hexes overlapping completed hexes
          # still here? the hex with this center is still possible, then
          return true
        end
      end
      return false
    end

    def delta(snapshot, for_player=nil)
      super.merge(
        :lines    => (@lines - snapshot.lines).map{ |line| line.as_json },
        :hexagons => (@hexagons - snapshot.hexagons).map{ |hex| hex.as_json }
      )
    end

    def as_json(for_player=nil)
      super.merge(
        :rows     => @rows,
        :cols     => @cols,
        :lines    => @lines.map{ |line| line.as_json },
        :hexagons => @hexagons.map{ |hex| hex.as_json }
      )
    end
  end
end
