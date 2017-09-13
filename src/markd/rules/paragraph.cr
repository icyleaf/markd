module Markd::Rule
  struct Paragraph
    include Rule

    def match(parser : Lexer, container : Node)
      MatchValue::None
    end

    def continue(parser : Lexer, container : Node)
      parser.blank ? ContinueStatus::Stop : ContinueStatus::Continue
    end

    def token(parser : Lexer, container : Node)
      has_reference_defs = false

      while container.text[0]? == '[' &&
            (pos = parser.inline_lexer.reference(container.text, parser.refmap)) && pos > 0
        container.text = slice(container.text, pos)
        has_reference_defs = true
      end

      container.unlink if has_reference_defs && container.text.each_char.all? &.ascii_whitespace?
    end

    def can_contain(t)
      false
    end

    def accepts_lines?
      true
    end
  end
end
