module Markd::Rule
  class Paragraph
    include Rule

    def token(context : Lexer, node : Node)
      # do nothing
    end

    def match(context : Lexer, node : Node)
      has_reference_defs = false

      while !node.text.empty? && node.text.byte_at(0) == Rule::CHAR_CODE_OPEN_BRACKET &&
            (pos = context.inline_lexer.parse_reference(node.text, context.refmap))

        node.text = node.text[pos..-1]
        has_reference_defs = true
      end

      node.unlink if has_reference_defs && node.text.match(Rule::NONSPACE)

      MatchValue::None
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
