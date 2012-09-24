require 'finals-framework/player'

describe FinalsFramework::Player do
  context "creation" do
    it "should set the name" do
      name = "John Doe"
      player = FinalsFramework::Player.new('name' => name)
      player.name.should == name
    end

    it "should zero out the score" do
      player = FinalsFramework::Player.new('name' => "John Doe")
      player.score.should == 0
    end
  end
end
