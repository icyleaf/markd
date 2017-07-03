module Markd
  class Parser
    getter context

    alias AnyType = String|Bool|Int32

    def initialize(source : String, options = {} of String => AnyType)
      @context = Lexer::Context.new(source, options: options)
      Lexer::Block.parse(@context)
    end
  end
end
