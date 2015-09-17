require 'gameworks'
require_relative 'board'

module Pajitnov
  class Player < Gameworks::Player
    attr_reader :board, :lines, :last_move

    def initialize(payload={})
      super
      return if @invalid
      @id = SecureRandom.uuid.to_s.split('-').first
      @board = Board.new(*payload.values_at('rows', 'cols'))
      if payload.fetch('initial_garbage', 0) > 0
        add_garbage(payload['initial_garbage'])
      end
      @lines = 0
      @last_move = nil
    end

    def valid_placement?(move)
      @board.valid_placement?(move)
    end

    def valid_drop?(move)
      @board.valid_drop?(move)
    end

    def add_move(move)
      return 0 if disqualified?
      @last_move = move
      cleared = @board.add(move)
      @lines += cleared
      @score += case cleared
        when 1 then 40
        when 2 then 100
        when 3 then 300
        when 4 then 1200
        else 0
      end
      cleared
    end

    def add_garbage(lines)
      disqualify! unless @board.add_garbage(lines)
    end

    def as_json(for_player=nil)
      super.merge(
        id: @id,
        lines: @lines,
        last_move: @last_move ? @last_move.locations.map(&:as_json) : nil,
        board: board.as_json
      )
    end
  end
end
