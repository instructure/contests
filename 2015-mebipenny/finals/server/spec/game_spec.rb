require_relative '../pajitnov/game'

describe Pajitnov::Game do
  describe "construction" do
    it "doesn't require anything" do
      game = Pajitnov::Game.new
      expect(game.valid?).to be_truthy
    end

    describe "rows" do
      it "defaults to 20" do
        game = Pajitnov::Game.new
        expect(game.rows).to eql(20)
      end

      it "allows minimum 1" do
        game1 = Pajitnov::Game.new('rows' => 1)
        game2 = Pajitnov::Game.new('rows' => 0)
        expect(game1.rows).to eql(1)
        expect(game1.valid?).to be_truthy
        expect(game2.valid?).to be_falsey
      end

      it "must be an integer" do
        game = Pajitnov::Game.new('rows' => 0.5)
        expect(game.valid?).to be_falsey
      end
    end

    describe "cols" do
      it "defaults to 10" do
        game = Pajitnov::Game.new
        expect(game.cols).to eql(10)
      end

      it "allows minimum 1" do
        game1 = Pajitnov::Game.new('cols' => 1)
        game2 = Pajitnov::Game.new('cols' => 0)
        expect(game1.cols).to eql(1)
        expect(game1.valid?).to be_truthy
        expect(game2.valid?).to be_falsey
      end

      it "must be an integer" do
        game = Pajitnov::Game.new('cols' => 0.5)
        expect(game.valid?).to be_falsey
      end
    end

    describe "seats" do
      it "defaults to 2" do
        game = Pajitnov::Game.new
        expect(game.seats).to eql(2)
      end

      it "allows maximum 4" do
        game1 = Pajitnov::Game.new('seats' => 4)
        game2 = Pajitnov::Game.new('seats' => 5)
        expect(game1.seats).to eql(4)
        expect(game1.valid?).to be_truthy
        expect(game2.valid?).to be_falsey
      end

      it "allows minimum 1" do
        game1 = Pajitnov::Game.new('seats' => 1)
        game2 = Pajitnov::Game.new('seats' => 0)
        expect(game1.seats).to eql(1)
        expect(game1.valid?).to be_truthy
        expect(game2.valid?).to be_falsey
      end

      it "must be an integer" do
        game = Pajitnov::Game.new('seats' => 2.5)
        expect(game.valid?).to be_falsey
      end
    end

    describe "turns" do
      it "defaults to nil (unlimited)" do
        game = Pajitnov::Game.new
        expect(game.turns_left).to eql(nil)
        expect(game.valid?).to be_truthy
      end

      it "allows arbitrarily large" do
        game = Pajitnov::Game.new('turns' => 10_000)
        expect(game.turns_left).to eql(10_000)
        expect(game.valid?).to be_truthy
      end

      it "allows minimum 1" do
        game1 = Pajitnov::Game.new('turns' => 1)
        game2 = Pajitnov::Game.new('turns' => 0)
        expect(game1.turns_left).to eql(1)
        expect(game1.valid?).to be_truthy
        expect(game2.valid?).to be_falsey
      end

      it "must be an integer" do
        game = Pajitnov::Game.new('turns' => 2.5)
        expect(game.valid?).to be_falsey
      end
    end

    describe "initial_garbage" do
      it "defaults to 0" do
        game = Pajitnov::Game.new
        expect(game.initial_garbage).to eql(0)
      end

      it "allows maximum equal to rows" do
        game1 = Pajitnov::Game.new('rows' => 15, 'initial_garbage' => 15)
        game2 = Pajitnov::Game.new('rows' => 15, 'initial_garbage' => 16)
        expect(game1.initial_garbage).to eql(15)
        expect(game1.valid?).to be_truthy
        expect(game2.valid?).to be_falsey
      end

      it "allows minimum 0" do
        game1 = Pajitnov::Game.new('initial_garbage' => 0)
        game2 = Pajitnov::Game.new('initial_garbage' => -1)
        expect(game1.initial_garbage).to eql(0)
        expect(game1.valid?).to be_truthy
        expect(game2.valid?).to be_falsey
      end

      it "must be an integer" do
        game = Pajitnov::Game.new('initial_garbage' => 2.5)
        expect(game.valid?).to be_falsey
      end
    end

    it "sets current_piece" do
      game = Pajitnov::Game.new
      Pajitnov::Piece.valid_piece?(game.current_piece)
    end

    it "sets next_piece" do
      game = Pajitnov::Game.new
      Pajitnov::Piece.valid_piece?(game.next_piece)
    end
  end

  describe "add_player" do
    it "includes rows and cols" do
      game = Pajitnov::Game.new
      player = game.add_player('name' => 'Player 1')
      expect(player.board.rows).to eql(game.rows)
      expect(player.board.cols).to eql(game.cols)
    end

    it "doles out initial garbage" do
      game = Pajitnov::Game.new('initial_garbage' => 1)
      player = game.add_player('name' => 'Player 1')
      expect(player.board.as_json[0].any?).to be_truthy
      expect(player.board.as_json[1].any?).to be_falsey
    end
  end

  describe "full?" do
    let(:game) { Pajitnov::Game.new }

    it "is false when there are more seats than players" do
      game.add_player('name' => 'Player 1')
      expect(game.full?).to be_falsey
    end

    it "is true when there is a player for each seat" do
      game.add_player('name' => 'Player 1')
      game.add_player('name' => 'Player 2')
      expect(game.full?).to be_truthy
    end
  end

  describe "init_game" do
    it "starts waiting on moves" do
      game = Pajitnov::Game.new
      game.add_player('name' => 'Player 1')
      game.init_game
      expect(game.waiting_on_moves?).to be_truthy
    end
  end

  describe "active_players" do
    let(:game) { Pajitnov::Game.new }

    it "includes all players (not just one)" do
      player1 = game.add_player('name' => 'Player 1')
      player2 = game.add_player('name' => 'Player 2')
      expect(game.active_players).to include(player1)
      expect(game.active_players).to include(player2)
    end

    it "does not include disqualified players" do
      player1 = game.add_player('name' => 'Player 1')
      game.add_player('name' => 'Player 2')
      player1.disqualify!
      expect(game.active_players).not_to include(player1)
    end
  end

  describe "player_changed?" do
    it "is true if the player's board changed" do
      game = Pajitnov::Game.new
      player = game.add_player('name' => 'Player 1')
      snapshot = game.snapshot
      player.board.set(0, 0, 'I')
      expect(game.player_changed?(player, snapshot)).to be_truthy
    end
  end

  describe "delta" do
    let(:game) { Pajitnov::Game.new }
    let(:snapshot) { game.snapshot }

    it "always includes the current piece" do
      delta = game.delta(snapshot)
      expect(delta[:current_piece]).to eql(game.current_piece)
    end

    it "always includes the next piece" do
      delta = game.delta(snapshot)
      expect(delta[:next_piece]).to eql(game.next_piece)
    end
  end

  describe "as_json" do
    let(:game) { Pajitnov::Game.new }

    it "includes rows" do
      expect(game.as_json[:rows]).to eql(game.rows)
    end

    it "includes cols" do
      expect(game.as_json[:cols]).to eql(game.cols)
    end

    it "includes current_piece" do
      expect(game.as_json[:current_piece]).to eql(game.current_piece)
    end

    it "includes next_piece" do
      expect(game.as_json[:next_piece]).to eql(game.next_piece)
    end
  end

  context "when initialized" do
    let(:game) { Pajitnov::Game.new }
    let(:player1) { game.add_player('name' => 'Player 1') }
    let(:player2) { game.add_player('name' => 'Player 2') }

    before do
      player1
      player2
      game.init_game
    end

    describe "build_move" do
      it "requires a Hash argument" do
        move, error = game.build_move("not a hash", player1)
        expect(move).to be_falsey
        expect(error).to eql("invalid move data (not a Hash)")
      end

      it "requires locations" do
        move, error = game.build_move({'other' => 'stuff'}, player1)
        expect(move).to be_falsey
        expect(error).to eql("invalid move data (no locations)")
      end

      it "requires locations to be an array" do
        move, error = game.build_move({'locations' => 'stuff'}, player1)
        expect(move).to be_falsey
        expect(error).to eql("invalid locations (not an Array)")
      end

      it "requires four locations" do
        move, error = game.build_move({'locations' => [1, 2, 3]}, player1)
        expect(move).to be_falsey
        expect(error).to eql("invalid locations (size != 4)")
      end

      it "requires all location values be hashes" do
        move, error = game.build_move({'locations' => [
          "not a hash",
          {'row' => 0, 'col' => 0},
          {'row' => 1, 'col' => 0},
          {'row' => 2, 'col' => 0}
        ]}, player1)
        expect(move).to be_falsey
        expect(error).to eql("invalid locations (non-location values)")
      end

      it "requires all location values have row keys" do
        move, error = game.build_move({'locations' => [
          {'col' => 1},
          {'row' => 0, 'col' => 0},
          {'row' => 1, 'col' => 0},
          {'row' => 2, 'col' => 0}
        ]}, player1)
        expect(move).to be_falsey
        expect(error).to eql("invalid locations (non-location values)")
      end

      it "requires all location values have col keys" do
        move, error = game.build_move({'locations' => [
          {'row' => 0},
          {'row' => 0, 'col' => 0},
          {'row' => 1, 'col' => 0},
          {'row' => 2, 'col' => 0}
        ]}, player1)
        expect(move).to be_falsey
        expect(error).to eql("invalid locations (non-location values)")
      end

      it "requires all location values have integer row" do
        move, error = game.build_move({'locations' => [
          {'row' => 0.5, 'col' => 1},
          {'row' => 0, 'col' => 0},
          {'row' => 1, 'col' => 0},
          {'row' => 2, 'col' => 0}
        ]}, player1)
        expect(move).to be_falsey
        expect(error).to eql("invalid locations (non-location values)")
      end

      it "requires all location values have integer column" do
        move, error = game.build_move({'locations' => [
          {'row' => 0, 'col' => 1.5},
          {'row' => 0, 'col' => 0},
          {'row' => 1, 'col' => 0},
          {'row' => 2, 'col' => 0}
        ]}, player1)
        expect(move).to be_falsey
        expect(error).to eql("invalid locations (non-location values)")
      end

      it "accepts with valid locations" do
        move, _ = game.build_move({'locations' => [
          {'row' => 0, 'col' => 1},
          {'row' => 0, 'col' => 0},
          {'row' => 1, 'col' => 0},
          {'row' => 2, 'col' => 0}
        ]}, player1)
        expect(move).to be_a(Pajitnov::Move)
      end

      it "creates move with current piece" do
        move, _ = game.build_move({'locations' => [
          {'row' => 0, 'col' => 1},
          {'row' => 0, 'col' => 0},
          {'row' => 1, 'col' => 0},
          {'row' => 2, 'col' => 0}
        ]}, player1)
        expect(move.piece).to eql(game.current_piece)
      end
    end

    describe "move_legal?" do
      let(:legal_move) { Pajitnov::Move.example_for_piece(game.current_piece) }
      let(:misshapen_move) { Pajitnov::Move.new(game.current_piece, [
        Pajitnov::Location.new(0, 0),
        Pajitnov::Location.new(0, 1),
        Pajitnov::Location.new(1, 2),
        Pajitnov::Location.new(1, 3)
      ]) }

      it "requires no move yet for player" do
        game.record_move(legal_move, player1)
        legal, error = game.move_legal?(legal_move, player1)
        expect(legal).to be_falsey
        expect(error).to eql("invalid move: player already moved this turn")
      end

      it "requires player not be disqualified" do
        player1.disqualify!
        legal, error = game.move_legal?(legal_move, player1)
        expect(legal).to be_falsey
        expect(error).to eql("invalid move: player disqualified")
      end

      it "requires the shape be valid" do
        legal, error = game.move_legal?(misshapen_move, player1)
        expect(legal).to be_falsey
        expect(error).to eql("invalid move: bad shape")
      end

      it "requires the placement be valid on the player's board" do
        # each possible legal_move will land on top of one of these
        player1.board.set(0, 1, 'I')
        player1.board.set(1, 0, 'I')
        legal, error = game.move_legal?(legal_move, player1)
        expect(legal).to be_falsey
        expect(error).to eql("invalid move: bad placement")
      end

      it "requires the drop be valid on the player's board" do
        # each possible legal_move will drop through one of these
        player1.board.set(4, 0, 'I')
        player1.board.set(4, 1, 'I')
        legal, error = game.move_legal?(legal_move, player1)
        expect(legal).to be_falsey
        expect(error).to eql("invalid move: drop obstructed")
      end

      it "otherwise legal" do
        legal, _ = game.move_legal?(legal_move, player1)
        expect(legal).to be_truthy
      end
    end

    describe "waiting_on_moves?" do
      let(:move) { Pajitnov::Move.example_for_piece(game.current_piece) }

      it "is true with some active players moves not recorded" do
        game.record_move(move, player1)
        expect(game.waiting_on_moves?).to be_truthy
      end

      it "is false with all players moves recorded" do
        game.record_move(move, player1)
        game.record_move(move, player2)
        expect(game.waiting_on_moves?).to be_falsey
      end

      it "is false with only disqualified players moves not recorded" do
        game.record_move(move, player1)
        player2.disqualify!
        expect(game.waiting_on_moves?).to be_falsey
      end
    end

    describe "process_move" do
      let(:move) { Pajitnov::Move.example_for_piece(game.current_piece) }

      before do
        stub_signal_turns(game)
      end

      it "records the player's move" do
        game.process_move(move, player1)
        expect(game.move_recorded?(player1)).to be_truthy
      end

      it "waits to effect move if other players haven't moved" do
        old_board = player1.board.hash
        game.process_move(move, player1)
        expect(player1.board.hash).to eql(old_board)
      end

      it "waits to signal new turns if other players haven't moved" do
        game.process_move(move, player1)
        expect(game.signaled_turns?).to be_falsey
      end

      it "applies all players moves when the last move arrives" do
        old_board1 = player1.board.hash
        old_board2 = player2.board.hash
        game.process_move(move, player1)
        game.process_move(move, player2)
        expect(player1.board.hash).not_to eql(old_board1)
        expect(player2.board.hash).not_to eql(old_board2)
      end

      context "multiple lines cleared" do
        before do
          # setup player 1 for bottom two lines cleared (takes advantage of
          # fact that player.add_move only checks placement, not drop, and
          # we're skipping legal_move? on the game)
          game.instance_variable_set(:@current_piece, "O")
          (0...game.cols).each do |i|
            player1.board.set(0, i, 'I')
            player1.board.set(1, i, 'I')
          end
          move.locations.each{ |loc| player1.board.set(loc.row, loc.col, nil) }
        end

        it "adds garbage to other players" do
          game.process_move(move, player1)
          game.process_move(move, player2)
          expect(player2.board.as_json[0][-2,2].any?).to be_truthy
        end

        it "waits for piece to land before garbage" do
          game.process_move(move, player1)
          game.process_move(move, player2)
          move.locations.each do |loc|
            expect(player2.board.at(loc.row+1, loc.col)).to eql(move.piece)
          end
        end
      end

      it "move to the next piece when the last move arrives" do
        game.instance_variable_set(:@current_piece, "O")
        game.instance_variable_set(:@next_piece, "L")

        old_current = game.current_piece
        old_next = game.next_piece
        game.process_move(move, player1)
        game.process_move(move, player2)
        expect(old_next == game.current_piece).to be_truthy
        expect(old_current == game.current_piece && old_next == game.next_piece).to be_falsey
      end

      it "resets the recorded moves for the new round when the last move arrives" do
        game.process_move(move, player1)
        game.process_move(move, player2)
        expect(game.move_recorded?(player1)).to be_falsey
        expect(game.move_recorded?(player2)).to be_falsey
      end

      it "decrements turns_left when processing a round" do
        game.turns_left = 2
        game.process_move(move, player1)
        game.process_move(move, player2)
        expect(game.turns_left).to eql(1)
      end

      it "signals new turns for the new round when the last move arrives" do
        game.process_move(move, player1)
        game.process_move(move, player2)
        expect(game.signaled_turns?).to be_truthy
      end

      it "ends game if no turns_left after processing a round" do
        game.turns_left = 1
        game.process_move(move, player1)
        game.process_move(move, player2)
        expect(game.state).to eql('completed')
      end

      it "ends game if active players drops from >=2 to <2" do
        # setup player 1 for bottom two lines cleared (takes advantage of
        # fact that player.add_move only checks placement, not drop, and
        # we're skipping legal_move? on the game)
        game.instance_variable_set(:@current_piece, "O")
        (0...game.cols).each do |i|
          player1.board.set(0, i, 'I')
          player1.board.set(1, i, 'I')
        end
        move.locations.each{ |loc| player1.board.set(loc.row, loc.col, nil) }

        # setup player 2 to not survive garbage
        (0...game.rows).each{ |i| player2.board.set(i, 0, 'I') }

        game.process_move(move, player1)
        game.process_move(move, player2)
        expect(player2.disqualified?).to be_truthy
        expect(game.state).to eql('completed')
      end
    end
  end

  context "3 player game" do
    let(:game) { Pajitnov::Game.new('seats' => 3) }
    let(:player1) { game.add_player('name' => 'Player 1') }
    let(:player2) { game.add_player('name' => 'Player 2') }
    let(:player3) { game.add_player('name' => 'Player 3') }
    let(:move) { Pajitnov::Move.example_for_piece(game.current_piece) }

    before do
      stub_signal_turns(game)
      player1
      player2
      player3
      game.init_game
    end

    it "processes the round if the last move is a disqualification" do
      old_board1 = player1.board.hash
      old_board2 = player2.board.hash
      game.process_move(move, player1)
      game.process_move(move, player2)
      game.disqualify(player3)
      expect(player1.board.hash).not_to eql(old_board1)
      expect(player2.board.hash).not_to eql(old_board2)
    end
  end

  def stub_signal_turns(game)
    # don't call gamework's signal_turns method, but instead set it up
    # as a spy so we can verify it gets called
    singleton_class = class << game; self; end
    singleton_class.send(:define_method, :signal_turns) do
      @signaled = true
    end
    singleton_class.send(:define_method, :signaled_turns?) do
      @signaled
    end
  end
end
