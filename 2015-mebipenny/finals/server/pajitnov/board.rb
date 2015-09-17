require 'set'
require_relative 'piece'

module Pajitnov
  class Board
    attr_reader :rows, :cols

    def initialize(rows, cols)
      @rows = rows
      @cols = cols

      row = [nil] * @cols
      @cells = @rows.times.map{ row.dup }
    end

    def in_bounds?(row, col)
      (0...@rows) === row && (0...@cols) === col
    end

    def set(row, col, piece)
      raise IndexError unless in_bounds?(row, col)
      raise ArgumentError unless piece.nil? || Piece.valid_piece?(piece)
      @cells[row][col] = piece
    end

    def at(row, col)
      in_bounds?(row, col) ? @cells[row][col] : nil
    end

    def empty?(row, col)
      in_bounds?(row, col) && at(row, col).nil?
    end

    def supported?(row, col)
      row == 0 || !empty?(row - 1, col)
    end

    def empty_location?(location)
      empty?(location.row, location.col)
    end

    def supported_location?(location)
      supported?(location.row, location.col)
    end

    def empty_placement?(move)
      move.locations.all? { |location| empty_location?(location) }
    end

    def supported_placement?(move)
      move.locations.any? { |location| supported_location?(location) }
    end

    def valid_placement?(move)
      empty_placement?(move) && supported_placement?(move)
    end

    def valid_drop?(move)
      move.tops.all? do |(col, row)|
        ((row+1)...@rows).all? do |r|
          empty?(r, col)
        end
      end
    end

    def add(move)
      # make sure the move is on the board
      return 0 unless valid_placement?(move)

      # fill the move's locations with the specified piece
      rows_affected = Set.new
      move.locations.each do |loc|
        set(loc.row, loc.col, move.piece)
        rows_affected << loc.row
      end

      # clear lines
      rows_cleared = rows_affected.select{ |row| @cells[row].all? }
      rows_cleared.sort.reverse_each do |row|
        @cells.delete_at(row)
        @cells << [nil] * @cols
      end

      # number of lines cleared
      rows_cleared.size
    end

    def add_garbage(lines)
      fits = true
      lines.times do
        popped = @cells.pop
        fits &&= popped.none?
        @cells.unshift(garbage_row)
      end
      return fits
    end

    def garbage_row
      row = @cols.times.map{ Piece.random }
      row[rand(@cols)] = nil
      row
    end

    def as_json
      @cells.map(&:dup)
    end

    def hash
      @cells.hash
    end
  end
end
