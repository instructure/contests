require_relative '../hexagons/coordinate'

describe Hexagons::Coordinate do
  context "creation" do
    it "should set row and col" do
      row = 2
      col = 5
      coord = Hexagons::Coordinate.new(row, col)
      expect(coord.row).to eq(row)
      expect(coord.col).to eq(col)
    end
  end

  context "sorting" do
    it "should be orderable" do
      coord = Hexagons::Coordinate.new(0, 0)
      expect(coord).to be_respond_to(:<)
      expect(coord).to be_respond_to(:>)
      expect(coord).to be_respond_to(:<=)
      expect(coord).to be_respond_to(:>=)
    end

    it "should use row-major order" do
      c1 = Hexagons::Coordinate.new(1, 2)
      c2 = Hexagons::Coordinate.new(1, 3)
      c3 = Hexagons::Coordinate.new(2, 3)

      expect(c1).to eq(c1)
      expect(c1).to be < c2
      expect(c1).to be < c3
      expect(c2).to be > c1
      expect(c2).to eq(c2)
      expect(c2).to be < c3
      expect(c3).to be > c1
      expect(c3).to be > c2
      expect(c3).to eq(c3)
    end
  end
end
