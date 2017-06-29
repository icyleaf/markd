module Markd
  class Parser
    getter context

    alias AnyType = String|Bool|Int32

    def initialize(source : String, options = {} of String => AnyType)
      @context = Lexer::Context.new(source, options: options)
      Lexer::Block.parse(@context)
    end

    # def parse(renderer = HTMLRenderer.new)
    #   out = ""
    #   while next_token
    #     out += tok
    #   end
    # end

    # def next_token
    #   @tokens.pop
    # end

    # def peek_token
    #   @tokens[@tokens.size - 1] || nil;
    # end

    # def tok
    #   case @token["type"]
    #   when :space
    #     next
    #   end
    # end
  end
end
