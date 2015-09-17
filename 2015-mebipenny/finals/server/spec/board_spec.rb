require_relative '../pajitnov/board'
require_relative '../pajitnov/location'
require_relative '../pajitnov/move'

describe Pajitnov::Board do
  let(:board) { Pajitnov::Board.new(20, 10) }
  let(:location) { Pajitnov::Location.new(3, 2) }
  let(:move) do
    Pajitnov::Move.new('J', [
      Pajitnov::Location.new(1, 1),
      Pajitnov::Location.new(2, 1),
      Pajitnov::Location.new(3, 1),
      Pajitnov::Location.new(3, 2)
    ])
  end

  describe "construction" do
    it "creates with given size" do
      expect(board.as_json.size).to eql(20)
      board.as_json.each{ |row| expect(row.size).to eql(10) }
    end

    it "creates with all cells empty" do
      expect(board.as_json.flatten.none?).to be_truthy
    end
  end

  describe "in_bounds?" do
    it "returns true in bounds" do
      expect(board.in_bounds?(0, 0)).to be_truthy
    end

    it "returns false for row out of bounds" do
      expect(board.in_bounds?(-1, 0)).to be_falsey
      expect(board.in_bounds?(20, 0)).to be_falsey
    end

    it "returns false for column out of bounds" do
      expect(board.in_bounds?(0, -1)).to be_falsey
      expect(board.in_bounds?(0, 10)).to be_falsey
    end
  end

  describe "set" do
    it "persists value in given cell" do
      board.set(1, 1, 'I')
      expect(board.as_json[1][1]).to eql('I')
    end

    it "doesn't modify other cells" do
      board.set(1, 1, 'I')
      expect(board.as_json[0][0]).to be_nil
    end

    it "doesn't allow setting cells out of bounds" do
      expect{ board.set(-1, 0, 'I') }.to raise_exception(IndexError)
    end

    it "doesn't allow setting cells to invalid pieces" do
      expect{ board.set(0, 0, 'Q') }.to raise_exception(ArgumentError)
    end

    it "allows setting cells to nil" do
      board.set(0, 0, 'I')
      expect{ board.set(0, 0, nil) }.not_to raise_exception
      expect(board.at(0, 0)).to be_nil
    end
  end

  describe "at" do
    it "reads set value in given cell" do
      board.set(1, 1, 'I')
      expect(board.at(1, 1)).to eql('I')
    end

    it "reads nil from unset cells" do
      expect(board.at(0, 0)).to be_nil
    end

    it "reads nil when out of bounds" do
      expect(board.at(-1, 0)).to be_nil
    end
  end

  describe "empty?" do
    it "returns false when out of bounds" do
      expect(board.empty?(-1, -1)).to be_falsey
    end

    it "returns true when in bounds but unset" do
      expect(board.empty?(0, 0)).to be_truthy
    end

    it "returns false when in bounds and set" do
      board.set(0, 0, 'I')
      expect(board.empty?(0, 0)).to be_falsey
    end
  end

  describe "supported?" do
    it "returns true for row 0" do
      expect(board.supported?(0, 2)).to be_truthy
    end

    it "returns true just above set cell" do
      board.set(2, 2, 'I')
      expect(board.supported?(3, 2)).to be_truthy
    end

    it "returns false farther above set cell" do
      board.set(2, 2, 'I')
      expect(board.supported?(4, 2)).to be_falsey
    end

    it "returns false for set cell itself" do
      board.set(2, 2, 'I')
      expect(board.supported?(2, 2)).to be_falsey
    end

    it "returns false for other neighboring cells" do
      board.set(2, 2, 'I')
      expect(board.supported?(1, 1)).to be_falsey
      expect(board.supported?(2, 1)).to be_falsey
      expect(board.supported?(3, 1)).to be_falsey
      expect(board.supported?(1, 2)).to be_falsey
      expect(board.supported?(1, 3)).to be_falsey
      expect(board.supported?(2, 3)).to be_falsey
      expect(board.supported?(3, 3)).to be_falsey
    end
  end

  describe "empty_location?" do
    it "maps to the cell for the location" do
      board.set(3, 2, 'I')
      expect(board.empty_location?(location)).to be_falsey
    end
  end

  describe "supported_location?" do
    it "maps to the cell for the location" do
      board.set(2, 2, 'I')
      expect(board.supported_location?(location)).to be_truthy
    end
  end

  describe "empty_placement?" do
    it "returns true if all cells are empty" do
      board.set(1, 2, 'I')
      expect(board.empty_placement?(move)).to be_truthy
    end

    it "returns false if any cells is not empty" do
      board.set(2, 1, 'I')
      expect(board.empty_placement?(move)).to be_falsey
    end
  end

  describe "supported_placement?" do
    it "returns false if no cells are supported" do
      board.set(1, 2, 'I')
      expect(board.supported_placement?(move)).to be_falsey
    end

    it "returns true if any cells are supported" do
      board.set(2, 2, 'I')
      expect(board.supported_placement?(move)).to be_truthy
    end
  end

  describe "valid_placement?" do
    it "returns true if empty and supported" do
      board.set(2, 2, 'I')
      expect(board.valid_placement?(move)).to be_truthy
    end

    it "returns false if empty but not supported" do
      board.set(1, 2, 'I')
      expect(board.valid_placement?(move)).to be_falsey
    end

    it "returns false if supported but not empty" do
      board.set(2, 2, 'I')
      board.set(3, 2, 'I')
      expect(board.valid_placement?(move)).to be_falsey
    end
  end

  describe "valid_drop?" do
    it "returns true if all cells above are empty" do
      board.set(1, 2, 'I')
      expect(board.valid_drop?(move)).to be_truthy
    end

    it "returns false if any cell above is not empty" do
      board.set(4, 1, 'I')
      expect(board.valid_drop?(move)).to be_falsey
      board.set(4, 1, nil)

      board.set(6, 2, 'I')
      expect(board.valid_drop?(move)).to be_falsey
    end
  end

  describe "add" do

    context "valid placement" do
      before{ board.set(2, 2, 'L') }

      it "sets cells" do
        board.add(move)
        expect(board.at(1, 1)).to eql('J')
        expect(board.at(2, 1)).to eql('J')
        expect(board.at(3, 1)).to eql('J')
        expect(board.at(3, 2)).to eql('J')
      end

      it "clears removes completed line" do
        board.set(2, 0, 'I')
        (3...10).each{ |i| board.set(2, i, 'I') }
        board.set(9, 9, 'T')
        expect(board.add(move)).to eql(1)
        expect(board.at(2, 2)).to eql('J') # dropped in from above
        expect(board.at(2, 3)).to be_nil # nothing dropped in from above
        expect(board.at(3, 2)).to be_nil # dropped down below
        expect(board.at(8, 9)).to eql('T')
        expect(board.at(9, 9)).to be_nil
      end

      it "clears multiple completed lines" do
        board.set(1, 0, 'I')
        board.set(1, 2, 'I')
        board.set(3, 0, 'I')
        (3...10).each do |i|
          board.set(1, i, 'I')
          board.set(3, i, 'I')
        end
        board.set(9, 9, 'T')
        expect(board.add(move)).to eql(2)
        expect(board.at(1, 2)).to eql('L')
        expect(board.at(7, 9)).to eql('T')
      end
    end

    context "invalid placement" do
      before{ board.set(2, 1, 'I') }

      it "returns 0" do
        expect(board.add(move)).to eql(0)
      end

      it "doesn't modify the board" do
        old_hash = board.hash
        board.add(move)
        expect(board.hash).to eql(old_hash)
      end
    end
  end

  describe "add_garbage" do
    it "does nothing with negative lines" do
      old_hash = board.hash
      board.add_garbage(-1)
      expect(board.hash).to eql(old_hash)
    end

    it "adds that many lines of garbage" do
      old_json = board.as_json
      board.add_garbage(3)
      expect(board.as_json[0]).not_to eql(old_json[0])
      expect(board.as_json[1]).not_to eql(old_json[1])
      expect(board.as_json[2]).not_to eql(old_json[2])
      expect(board.as_json[3]).to eql(old_json[3])
    end

    it "pushes up from the bottom" do
      board.set(0, 0, 'I')
      old_json = board.as_json
      board.add_garbage(1)
      expect(board.as_json[1]).to eql(old_json[0])
      expect(board.as_json[0].count{ |cell| cell.nil? }).to eql(1)
    end

    it "returns true if all garbage fits" do
      (0...(board.rows - 1)).each{ |i| board.set(i, 0, 'I') }
      expect(board.add_garbage(1)).to be_truthy
    end

    it "returns false if non-empty lines pushed off top" do
      (0...board.rows).each{ |i| board.set(i, 0, 'I') }
      expect(board.add_garbage(1)).to be_falsey
    end
  end

  describe "as_json" do
    it "should not reflect modifications back into board" do
      board.set(1, 1, 'T')
      json = board.as_json
      json[1][1] = 'I'
      expect(board.at(1, 1)).to eql('T')
    end
  end

  describe "hash" do
    it "should be consistent when unchanged" do
      first_hash = board.hash
      expect(board.hash).to eql(first_hash)
    end

    it "should be consistent when repeated" do
      original_hash = board.hash
      board.set(1, 1, 'T')
      board.set(1, 1, nil)
      expect(board.hash).to eql(original_hash)
    end

    it "should be distinct when modified" do
      original_hash = board.hash
      board.set(1, 1, 'T')
      expect(board.hash).not_to eql(original_hash)
    end
  end
end
