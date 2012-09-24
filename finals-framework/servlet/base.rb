module FinalsFramework
  module Servlet
    class Base
      def initialize(server)
        @server = server
      end

      def self.process(server, request)
        servlet = self.new(server)
        if servlet.respond_to?(request[:method])
          servlet.send(request[:method], request)
        else
          servlet.method_not_allowed
        end
      end

      def method_not_allowed
        [ 405, { 'Allow' => ['GET', 'POST'].select{ |m| respond_to?(m) }.join(', ') }, [] ]
      end
    end
  end
end
