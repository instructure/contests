require_relative '../hexagons/game'

describe Hexagons::Game do
  context "creation" do
    it "should set rows and cols" do
      rows = 5
      cols = 10
      game = Hexagons::Game.new('rows' => rows, 'cols' => cols)
      expect(game.rows).to eq(rows)
      expect(game.cols).to eq(cols)
    end

    it "should have no lines" do
      game = Hexagons::Game.new('rows' => 5, 'cols' => 10)
      expect(game.lines).to be_empty
    end

    it "should have no hexagons" do
      game = Hexagons::Game.new('rows' => 5, 'cols' => 10)
      expect(game.hexagons).to be_empty
    end
  end
end
