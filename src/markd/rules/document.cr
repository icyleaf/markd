module Markd::Rule
  struct Document
    include Rule

    def match(parser : Lexer, container : Node)
      MatchValue::None
    end

    def continue(parser : Lexer, container : Node)
      ContinueStatus::Continue
    end

    def token(parser : Lexer, container : Node)
      # do nothing
    end

    def can_contain(type : Node::Type) : Bool
      type != Node::Type::Item
    end

    def accepts_lines?
      false
    end
  end
end
