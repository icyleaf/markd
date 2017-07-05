module Markd
  module Lexer
    class Context
      property document : Node
      property source : String
      property options : Hash(String, Parser::AnyType)

      # :nodoc:
      def initialize(
                     @source = "",
                     @options = {} of String => Parser::AnyType,
                     @document = Node.new(Node::Type::Document)
                    )
      end
    end
  end
end
