require_relative '../pajitnov/player'

describe Pajitnov::Player do
  let(:player) do
    Pajitnov::Player.new(
      'name' => 'Player 1',
      'rows' => 20,
      'cols' => 10
    )
  end

  describe "construction" do
    it "forwards parameters to board" do
      expect(player.board.rows).to eql(20)
      expect(player.board.cols).to eql(10)
    end

    it "creates with id" do
      expect(player.as_json[:id]).not_to be_nil
    end

    it "creates with zero lines" do
      expect(player.lines).to eql(0)
    end
  end

  describe "valid_placement?" do
    it "checks move against player's board" do
      move = Pajitnov::Move.new('J', [
        Pajitnov::Location.new(0, 0),
        Pajitnov::Location.new(1, 0),
        Pajitnov::Location.new(2, 0),
        Pajitnov::Location.new(2, 1)
      ])
      expect(player.valid_placement?(move)).to be_truthy

      player.board.set(0, 0, 'T')
      expect(player.valid_placement?(move)).to be_falsey
    end
  end

  describe "valid_drop?" do
    it "checks move against player's board" do
      move = Pajitnov::Move.new('J', [
        Pajitnov::Location.new(0, 0),
        Pajitnov::Location.new(1, 0),
        Pajitnov::Location.new(2, 0),
        Pajitnov::Location.new(2, 1)
      ])
      expect(player.valid_drop?(move)).to be_truthy

      player.board.set(5, 0, 'T')
      expect(player.valid_drop?(move)).to be_falsey
    end
  end

  describe "add_move" do
    before do
      (2...10).each do |i|
        player.board.set(0, i, 'I')
        player.board.set(1, i, 'I')
        player.board.set(2, i, 'I')
        player.board.set(3, i, 'I')
      end
    end

    let(:move) do
      Pajitnov::Move.new('I', [
        Pajitnov::Location.new(0, 0),
        Pajitnov::Location.new(1, 0),
        Pajitnov::Location.new(2, 0),
        Pajitnov::Location.new(3, 0)
      ])
    end

    it "makes move on player's board" do
      player.add_move(move)
      expect(player.board.at(0, 0)).to eql('I')
    end

    it "returns number of lines cleared" do
      (0..2).each{ |i| player.board.set(i, 1, 'I') }
      expect(player.add_move(move)).to eql(3)
    end

    it "increases line count" do
      (0..2).each{ |i| player.board.set(i, 1, 'I') }
      player.add_move(move)
      expect(player.lines).to eql(3)
    end

    it "increases score (1 line = 40)" do
      player.board.set(0, 1, 'I')
      player.add_move(move)
      expect(player.score).to eql(40)
    end

    it "increases score (2 lines = 100)" do
      (0..1).each{ |i| player.board.set(i, 1, 'I') }
      player.add_move(move)
      expect(player.score).to eql(100)
    end

    it "increases score (3 lines = 300)" do
      (0..2).each{ |i| player.board.set(i, 1, 'I') }
      player.add_move(move)
      expect(player.score).to eql(300)
    end

    it "increases score (4 lines = 1200)" do
      (0..3).each{ |i| player.board.set(i, 1, 'I') }
      player.add_move(move)
      expect(player.score).to eql(1200)
    end

    it "does nothing if disqualified" do
      (0..3).each{ |i| player.board.set(i, 1, 'I') }
      player.disqualify!
      board_was = player.board.hash
      lines_was = player.lines
      score_was = player.score
      expect(player.add_move(move)).to eql(0)
      expect(player.board.hash).to eql(board_was)
      expect(player.lines).to eql(lines_was)
      expect(player.score).to eql(score_was)
      expect(player.disqualified?).to be_truthy
    end
  end

  describe "add_garbage" do
    it "should add garbage to the player's board" do
      player.add_garbage(3)
      expect(player.board.as_json[2].any?).to be_truthy
    end

    it "should disqualify the player if too much" do
      player.add_garbage(21)
      expect(player.disqualified?).to be_truthy
    end

    it "should not disqualify the player if it fits" do
      player.add_garbage(20)
      expect(player.disqualified?).to be_falsey
    end
  end

  describe "as_json" do
    it "includes lines" do
      expect(player.as_json[:lines]).to eql(0)
    end

    it "includes board" do
      expect(player.as_json[:board]).to eql(player.board.as_json)
    end
  end
end
