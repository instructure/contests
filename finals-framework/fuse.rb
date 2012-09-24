require 'eventmachine'

module FinalsFramework
  class Fuse
    def initialize(seconds)
      @aborted = false
      EventMachine::add_timer(seconds) do
        yield unless @aborted
      end
    end

    def abort
      @aborted = true
    end
  end
end
