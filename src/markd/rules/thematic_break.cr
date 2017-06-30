module Markd::Rule
  class ThematicBreak
    include Rule

    def match(parser : Lexer, container : Node)
      MatchValue::None
    end

    def continue(parser : Lexer, container : Node)
      # a thematic break can never container > 1 line, so fail to match:
      1
    end

    def token(parser : Lexer, container : Node)

    end

    def can_contain(t)
      true
    end

    def accepts_lines?
      false
    end
  end
end
