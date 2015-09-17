module Pajitnov
  class Piece
    PIECES = %w(I J L O S T Z)

    SHAPES = [
      [['I', 'I', 'I', 'I']].hash,

      [['I'],
       ['I'],
       ['I'],
       ['I']].hash,

      [[nil, 'J'],
       [nil, 'J'],
       ['J', 'J']].hash,

      [['J', nil, nil],
       ['J', 'J', 'J']].hash,

      [['J', 'J'],
       ['J', nil],
       ['J', nil]].hash,

      [['J', 'J', 'J'],
       [nil, nil, 'J']].hash,

      [['L', nil],
       ['L', nil],
       ['L', 'L']].hash,

      [['L', 'L', 'L'],
       ['L', nil, nil]].hash,

      [['L', 'L'],
       [nil, 'L'],
       [nil, 'L']].hash,

      [[nil, nil, 'L'],
       ['L', 'L', 'L']].hash,

      [['O', 'O'],
       ['O', 'O']].hash,

      [[nil, 'S', 'S'],
       ['S', 'S', nil]].hash,

      [['S', nil],
       ['S', 'S'],
       [nil, 'S']].hash,

      [[nil, 'T', nil],
       ['T', 'T', 'T']].hash,

      [['T', nil],
       ['T', 'T'],
       ['T', nil]].hash,

      [['T', 'T', 'T'],
       [nil, 'T', nil]].hash,

      [[nil, 'T'],
       ['T', 'T'],
       [nil, 'T']].hash,

      [['Z', 'Z', nil],
       [nil, 'Z', 'Z']].hash,

      [[nil, 'Z'],
       ['Z', 'Z'],
       ['Z', nil]].hash
    ]

    def self.valid_shape?(shape)
      SHAPES.include?(shape.hash)
    end

    def self.valid_piece?(piece)
      PIECES.include?(piece)
    end

    def self.example_shape_for(piece)
      case piece
      when 'I'
        [['I', 'I', 'I', 'I']]
      when 'J'
        [[nil, 'J'],
         [nil, 'J'],
         ['J', 'J']]
      when 'L'
        [['L', nil],
         ['L', nil],
         ['L', 'L']]
      when 'O'
        [['O', 'O'],
         ['O', 'O']]
      when 'S'
        [[nil, 'S', 'S'],
         ['S', 'S', nil]]
      when 'T'
        [['T', 'T', 'T'],
         [nil, 'T', nil]]
      when 'Z'
        [['Z', 'Z', nil],
         [nil, 'Z', 'Z']]
      else
        raise ArgumentError
      end
    end

    def self.random
      PIECES[rand(PIECES.size)]
    end
  end
end
