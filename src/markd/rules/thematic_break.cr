module Markd::Rule
  class ThematicBreak
    include Rule

    THEMATIC_BREAK = /^(?:(?:\*[ \t]*){3,}|(?:_[ \t]*){3,}|(?:-[ \t]*){3,})[ \t]*$/

    def match(parser : Lexer, container : Node)
      if !parser.indented && slice(parser).match(THEMATIC_BREAK)
        parser.close_unmatched_blocks
        parser.add_child(Node::Type::ThematicBreak, parser.next_nonspace)
        parser.advance_offset(parser.line.size - parser.offset, false)
        MatchValue::Leaf
      else
        MatchValue::None
      end
    end

    def continue(parser : Lexer, container : Node)
      # a thematic break can never container > 1 line, so fail to match:
      1
    end

    def token(parser : Lexer, container : Node)
      # do nothing
    end

    def can_contain(t)
      false
    end

    def accepts_lines?
      false
    end
  end
end
