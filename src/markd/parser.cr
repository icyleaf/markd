module Markd
  class Parser
    @lexers : Array(Lexer)
    @lexer : Lexer
    @tokens : Array(Token)

    def initialize(src : String, lexers = [] of Lexer)
      @lexers = lexers.concat([CommonLexer.new, InlineLexer.new])
      @lexer = build_lexer(lexers)
      @tokens = @lexer.call(src)
    end

    def parse(renderer : HTMLRenderer.new)
      out = ""
      while next_token
        out += tok
      end
    end

    def next_token
      @tokens.pop
    end

    def peek_token
      @tokens[@tokens.size - 1] || nil;
    end

    def tok
      case @token["type"]
      when :space
        next
      end
    end

    def build_lexer(lexers)
      raise ArgumentError.new "You must specify at least one Markd Lexer." if lexers.empty?
      0.upto(lexers.size - 2) { |i| lexers[i].next = lexers[i + 1] }
      lexers.first
    end
  end
end