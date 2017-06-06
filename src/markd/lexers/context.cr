module Markd
  module Lexer
    class Context
      getter source : String

      property document : Document

      # :nodoc:
      def initialize(@source : String, @document = Document.new)
      end
    end
  end
end
