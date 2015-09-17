require_relative '../pajitnov/piece'

describe Pajitnov::Piece do
  describe "valid_shape?" do
    it "passes flat I" do
      expect(Pajitnov::Piece.valid_shape?([['I', 'I', 'I', 'I']])).to be_truthy
    end

    it "passes upright I" do
      expect(Pajitnov::Piece.valid_shape?([['I'],
                                           ['I'],
                                           ['I'],
                                           ['I']])).to be_truthy
    end

    it "passes neutral J" do
      expect(Pajitnov::Piece.valid_shape?([[nil, 'J'],
                                           [nil, 'J'],
                                           ['J', 'J']])).to be_truthy
    end

    it "passes laid-down J" do
      expect(Pajitnov::Piece.valid_shape?([['J', nil, nil],
                                           ['J', 'J', 'J']])).to be_truthy
    end

    it "passes upside-down J" do
      expect(Pajitnov::Piece.valid_shape?([['J', 'J'],
                                           ['J', nil],
                                           ['J', nil]])).to be_truthy
    end

    it "passes laid-forward J" do
      expect(Pajitnov::Piece.valid_shape?([['J', 'J', 'J'],
                                           [nil, nil, 'J']])).to be_truthy
    end

    it "passes neutral L" do
      expect(Pajitnov::Piece.valid_shape?([['L', nil],
                                           ['L', nil],
                                           ['L', 'L']])).to be_truthy
    end

    it "passes laid-down L" do
      expect(Pajitnov::Piece.valid_shape?([[nil, nil, 'L'],
                                           ['L', 'L', 'L']])).to be_truthy
    end

    it "passes upside-down L" do
      expect(Pajitnov::Piece.valid_shape?([['L', 'L'],
                                           [nil, 'L'],
                                           [nil, 'L']])).to be_truthy
    end

    it "passes laid-forward L" do
      expect(Pajitnov::Piece.valid_shape?([['L', 'L', 'L'],
                                           ['L', nil, nil]])).to be_truthy
    end

    it "passes O" do
      expect(Pajitnov::Piece.valid_shape?([['O', 'O'],
                                           ['O', 'O']])).to be_truthy
    end

    it "passes neutral S" do
      expect(Pajitnov::Piece.valid_shape?([[nil, 'S', 'S'],
                                           ['S', 'S', nil]])).to be_truthy
    end

    it "passes upright S" do
      expect(Pajitnov::Piece.valid_shape?([['S', nil],
                                           ['S', 'S'],
                                           [nil, 'S']])).to be_truthy
    end

    it "passes neutral T" do
      expect(Pajitnov::Piece.valid_shape?([['T', 'T', 'T'],
                                           [nil, 'T', nil]])).to be_truthy
    end

    it "passes tilt-left T" do
      expect(Pajitnov::Piece.valid_shape?([['T', nil],
                                           ['T', 'T'],
                                           ['T', nil]])).to be_truthy
    end

    it "passes tilt-right T" do
      expect(Pajitnov::Piece.valid_shape?([[nil, 'T'],
                                           ['T', 'T'],
                                           [nil, 'T']])).to be_truthy
    end

    it "passes upside-down T" do
      expect(Pajitnov::Piece.valid_shape?([[nil, 'T', nil],
                                           ['T', 'T', 'T']])).to be_truthy
    end

    it "passes neutral Z" do
      expect(Pajitnov::Piece.valid_shape?([['Z', 'Z', nil],
                                           [nil, 'Z', 'Z']])).to be_truthy
    end

    it "passes upright Z" do
      expect(Pajitnov::Piece.valid_shape?([[nil, 'Z'],
                                           ['Z', 'Z'],
                                           ['Z', nil]])).to be_truthy
    end

    it "fails valid piece in wrong shape" do
      expect(Pajitnov::Piece.valid_shape?([['J', 'J', 'J', 'J']])).to be_falsey
    end
  end

  describe "valid_piece?" do
    it "accepts all seven valid pieces" do
      expect(Pajitnov::Piece.valid_piece?('I')).to be_truthy
      expect(Pajitnov::Piece.valid_piece?('J')).to be_truthy
      expect(Pajitnov::Piece.valid_piece?('L')).to be_truthy
      expect(Pajitnov::Piece.valid_piece?('O')).to be_truthy
      expect(Pajitnov::Piece.valid_piece?('S')).to be_truthy
      expect(Pajitnov::Piece.valid_piece?('T')).to be_truthy
      expect(Pajitnov::Piece.valid_piece?('Z')).to be_truthy
    end

    it "rejects other labels" do
      expect(Pajitnov::Piece.valid_piece?('Q')).to be_falsey
    end
  end

  describe "random" do
    it "returns valid pieces" do
      100.times do
        piece = Pajitnov::Piece.random
        expect(Pajitnov::Piece.valid_piece?(piece)).to be_truthy
      end
    end

    # TODO spec some expectation of randomness?
  end
end
