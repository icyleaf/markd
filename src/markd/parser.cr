module Markd
  class Parser
    getter context

    alias AnyType = String|Bool|Int32

    def initialize(source : String, options = {} of String => AnyType, lexers = [] of Lexer)
      @context = Lexer::Context.new(source, options: options)

      lexers = default_lexers if lexers.empty?
      lexer = build_lexer(lexers)
      lexer.call(@context)
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

    def build_lexer(lexers)
      raise ArgumentError.new "You must specify at least one Markd Lexer." if lexers.empty?

      0.upto(lexers.size - 2) { |i| lexers[i].next = lexers[i + 1] }
      lexers.first
    end

    private def default_lexers
      [Lexer::Block.new.as(Lexer), Lexer::Inline.new.as(Lexer)]
    end
  end
end
