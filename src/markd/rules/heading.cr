module Markd::Rule
  class Heading
    include Rule

    ATX_HEADING_MARKER = /^\#{1,6}(?:[ \t]+|$)/
    SETEXT_HEADING_MARKER = /^(?:=+|-+)[ \t]*$/

    def match(parser : Lexer, container : Node) : MatchValue
      if match = match?(parser, ATX_HEADING_MARKER)
        # ATX Heading matched
        parser.advance_next_nonspace
        parser.advance_offset(match[0].size, false)
        parser.close_unmatched_blocks

        container = parser.add_child(Node::Type::Heading, parser.next_nonspace)
        container.data["level"] = match[0].strip.size
        container.text = parser.line[parser.offset..-1]
                               .sub(/^ *#+ *$/, "")
                               .sub(/ +#+ *$/, "")

        parser.advance_offset(parser.line.size - parser.offset)

        MatchValue::Leaf
      elsif (match = match?(parser, SETEXT_HEADING_MARKER)) &&
             container.type == Node::Type::Paragraph
        # Setext Heading matched
        parser.close_unmatched_blocks
        heading = Node.new(Node::Type::Heading)
        heading.source_pos = container.source_pos
        heading.data["level"] = match[0][0] == '=' ? 1 : 2
        heading.text = container.text

        container.insert_after(heading)
        container.unlink

        parser.tip = heading
        parser.advance_offset(parser.line.size - parser.offset, false)

        MatchValue::Leaf
      else
        MatchValue::None
      end
    end

    def token(parser : Lexer, container : Node)
      # do nothing
    end

    def continue(parser : Lexer, container : Node)
      # a heading can never container > 1 line, so fail to match
      1
    end

    def can_contain(t)
      false
    end

    def accepts_lines?
      false
    end

    private def match?(parser : Lexer, regex : Regex) : Regex::MatchData?
      match = text_clean(parser).match(regex)
      !parser.indented && match ? match : nil
    end
  end
end
