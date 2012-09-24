require 'finals-framework/game'

describe FinalsFramework::Game do
  context "creation" do
    it "should have no players" do
      game = FinalsFramework::Game.new
      game.players.should be_empty
    end

    it "should be in the 'initiating' state" do
      game = FinalsFramework::Game.new
      game.state.should == 'initiating'
    end
  end
end
