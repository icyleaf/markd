module Markd::Rule
  class Paragraph
    include Rule

    CHAR_CODE_OPEN_BRACKET = 91

    def token(context : Lexer, node : Node)
      # do nothing?
    end

    def match(context : Lexer, node : Node)
      has_reference_defs = false

      # && (pos = context.inline_lexer.parser_reference(node.text, context.refmap)
      while node.text.byte_at(0) == CHAR_CODE_OPEN_BRACKET
        # node.text = node.text[pos..-1]
        has_reference_defs = true

        if has_reference_defs && node.text.match(Rule::NONSPACE)
          node.unlink
        end
      end

      MatchValue::Skip
    end

    def continue(context : Lexer, node : Node)
      context.blank ? 1 : 0
    end

    def can_contain(t)
      false
    end

    def accepts_lines?
      true
    end
  end
end
