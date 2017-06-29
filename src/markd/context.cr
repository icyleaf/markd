module Markd
  module Lexer
    class Context
      getter source : String
      getter options : Hash(String, Parser::AnyType)

      property document : Node

      # :nodoc:
      def initialize(
                     @source : String,
                     @options = {} of String => Parser::AnyType,
                     @document = Node.new(Node::Type::Document)
                    )
      end
    end
  end
end
