module Markd::Rule
  class CodeBlock
    include Rule

    def match(parser : Lexer, container : Node) : MatchValue
      MatchValue::None
    end

    def continue(parser : Lexer, container : Node)
      # 0/1
      0
    end

    def token(parser : Lexer, container : Node)
      # if container.is_fenced

    end

    def can_contain(t)
      false
    end

    def accepts_lines?
      true
    end
  end
end
