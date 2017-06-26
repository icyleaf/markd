module Markd
  class Parser
    getter context

    def initialize(source : String, lexers = [] of Lexer)
      @context = Lexer::Context.new(source)
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
      [CommonLexer.new.as(Lexer), InlineLexer.new.as(Lexer)]
    end
  end
end