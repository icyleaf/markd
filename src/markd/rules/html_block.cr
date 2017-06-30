module Markd::Rule
  class HTMLBlock
    include Rule

    def match(parser : Lexer, container : Node)
      MatchValue::None
    end

    def continue(parser : Lexer, container : Node)
      #  0/1
      0
    end

    def token(parser : Lexer, container : Node)

    end

    def can_contain(t)
      true
    end

    def accepts_lines?
      true
    end
  end
end
