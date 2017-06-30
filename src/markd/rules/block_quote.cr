module Markd::Rule
  class BlockQuote
    include Rule

    def token(context : Lexer, node : Node)
      # do nothing
    end

    def match(context : Lexer, node : Node)
      if match?(context)
        seek(context)
        context.close_unmatched_blocks
        context.add_child(Node::Type::BlockQuote, context.next_nonspace)

        MatchValue::Container
      else
        MatchValue::None
      end
    end

    def continue(context : Lexer, node : Node)
      if match?(context)
        seek(context)
      else
        1
      end

      0
    end

    def can_contain(type : Node::Type) : Bool
      type != Node::Type::Item
    end

    def accepts_lines?
      false
    end

    private def match?(context)
      !context.indented && char_code_at(context) == Rule::CHAR_CODE_GREATERTHAN
    end

    private def seek(context : Lexer)
      context.advance_next_nonspace
      context.advance_offset(1, false)

      if [CHAR_CODE_TAB, CHAR_CODE_SPACE].includes?(char_code_at(context, context.offset))
        context.advance_offset(1, true);
      end
    end
  end
end
