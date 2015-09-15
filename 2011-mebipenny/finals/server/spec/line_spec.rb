require_relative '../hexagons/line'

describe Hexagons::Line do
  context "creation" do
    it "should set first and last" do
      a = Hexagons::Coordinate.new(2, 6)
      b = Hexagons::Coordinate.new(2, 7)
      line = Hexagons::Line.new(a, b)
      expect(line.first).to eq(a)
      expect(line.last).to eq(b)
    end

    it "should sort first and last in row-major order" do
      c1 = Hexagons::Coordinate.new(1, 2)
      c2 = Hexagons::Coordinate.new(1, 3)
      c3 = Hexagons::Coordinate.new(2, 2)

      line = Hexagons::Line.new(c1, c2)
      expect(line.first).to be < line.last

      line = Hexagons::Line.new(c2, c1)
      expect(line.first).to be < line.last

      line = Hexagons::Line.new(c1, c3)
      expect(line.first).to be < line.last

      line = Hexagons::Line.new(c3, c1)
      expect(line.first).to be < line.last

      line = Hexagons::Line.new(c2, c3)
      expect(line.first).to be < line.last

      line = Hexagons::Line.new(c3, c2)
      expect(line.first).to be < line.last
    end
  end
end
