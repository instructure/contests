module FinalsFramework
  class GameRegistry
    def initialize
      @instances = {}
    end

    def add(game)
      @instances[game.id] = game
    end

    def instance(id)
      @instances[id]
    end

    def as_json
      @instances.map do |id, game|
        { 'id' => game.id, 'state' => game.state }
      end
    end

    def to_json
      as_json.to_json
    end
  end
end
