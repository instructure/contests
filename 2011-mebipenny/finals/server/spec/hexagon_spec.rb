require_relative '../hexagons/hexagon'

describe Hexagons::Hexagon do
  context "creation" do
    it "should set center and owner" do
      center = Hexagons::Coordinate.new(1, 1)
      owner = Gameworks::Player.new('name' => "John Doe")
      hex = Hexagons::Hexagon.new(center, owner)
      expect(hex.center).to eq(center)
      expect(hex.owner).to eq(owner)
    end
  end
end
