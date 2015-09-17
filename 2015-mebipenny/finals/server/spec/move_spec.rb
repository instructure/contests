require_relative '../pajitnov/move'
require_relative '../pajitnov/location'

describe Pajitnov::Move do
  let(:floating_S) do
    Pajitnov::Move.new('S', [
      Pajitnov::Location.new(3, 3),
      Pajitnov::Location.new(3, 2),
      Pajitnov::Location.new(2, 2),
      Pajitnov::Location.new(2, 1)
    ])
  end

  describe "tops" do
    it "has an entry for each occupied column" do
      expect(floating_S.tops.keys.sort).to eql([1, 2, 3].sort)
    end

    it "has the top row for each column" do
      tops = floating_S.tops
      expect(tops[1]).to eql(2)
      expect(tops[2]).to eql(3)
      expect(tops[3]).to eql(3)
    end
  end

  describe "valid_shape?" do
    let(:corner_L) do
      Pajitnov::Move.new('L', [
        Pajitnov::Location.new(2, 0),
        Pajitnov::Location.new(1, 0),
        Pajitnov::Location.new(0, 0),
        Pajitnov::Location.new(0, 1)
      ])
    end

    let(:rotated_L) do
      Pajitnov::Move.new('L', [
        Pajitnov::Location.new(0, 0),
        Pajitnov::Location.new(0, 1),
        Pajitnov::Location.new(0, 2),
        Pajitnov::Location.new(1, 2)
      ])
    end

    let(:mislabeled) do
      Pajitnov::Move.new('T', [
        Pajitnov::Location.new(0, 0),
        Pajitnov::Location.new(0, 1),
        Pajitnov::Location.new(0, 2),
        Pajitnov::Location.new(1, 2)
      ])
    end

    let(:misshapen) do
      Pajitnov::Move.new('L', [
        Pajitnov::Location.new(0, 0),
        Pajitnov::Location.new(0, 1),
        Pajitnov::Location.new(0, 2),
        Pajitnov::Location.new(2, 2)
      ])
    end

    it "works for an expected shape in the corner" do
      expect(corner_L.valid_shape?).to be_truthy
    end

    it "works for all rotations of that shape" do
      expect(rotated_L.valid_shape?).to be_truthy
    end

    it "works for translated shapes" do
      expect(floating_S.valid_shape?).to be_truthy
    end

    it "fails for mislabeled shapes" do
      expect(mislabeled.valid_shape?).to be_falsey
    end

    it "fails for unrecognized shapes" do
      expect(misshapen.valid_shape?).to be_falsey
    end
  end
end
