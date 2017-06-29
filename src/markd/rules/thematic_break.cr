module Markd::Rule
  class ThematicBreak
    include Rule

    def token(context : Lexer, node : Node)

    end

    def match(context : Lexer, node : Node)
      MatchValue::Skip
    end

    def continue(context : Lexer, node : Node)
      # a thematic break can never container > 1 line, so fail to match:
      1
    end

    def can_contain(t)
      true
    end

    def accepts_lines?
      false
    end
  end
end
