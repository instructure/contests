require_relative 'piece'
require_relative 'location'

module Pajitnov
  class Move
    attr_reader :piece, :locations

    def initialize(piece, locations)
      @piece = piece
      @locations = locations
    end

    def tops
      @locations.each_with_object({}) do |loc, tops|
        if !tops[loc.col] || loc.row > tops[loc.col]
          tops[loc.col] = loc.row
        end
      end
    end

    def valid_shape?
      # build a "canvas" for the shape
      rows = @locations.map(&:row)
      cols = @locations.map(&:col)
      row_count = rows.max - rows.min + 1
      col_count = cols.max - cols.min + 1
      shape = row_count.times.map do
        [nil] * col_count
      end

      # "paint" the shape onto that canvas
      @locations.each do |loc|
        row = loc.row - rows.min
        col = loc.col - cols.min
        shape[row][col] = @piece
      end

      # the shape built so far has row index 0 meaning bottom of the
      # shape, but Piece.valid_shape? expects row index 0 to mean the
      # top of the shape (for visual clarity). so reverse the shape
      # here before sending it in.
      Piece.valid_shape?(shape.reverse)
    end

    def self.example_for_piece(piece, options={})
      left = options[:left] || 0
      bottom = options[:bottom] || 0
      locations = []
      Piece.example_shape_for(piece).reverse.each_with_index do |row, i|
        row.each_with_index do |value, j|
          if value
            locations << Location.new(bottom + i, left + j)
          end
        end
      end
      new(piece, locations)
    end
  end
end
