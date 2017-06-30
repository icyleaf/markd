module Markd::Rule
  class List
    include Rule

    def token(context : Lexer, node : Node)

    end

    def match(context : Lexer, node : Node)
      MatchValue::None
    end

    def continue(context : Lexer, node : Node)
      0
    end

    def can_contain(t)
      t == Node::Type::Item
    end

    def accepts_lines?
      false
    end
  end
end
