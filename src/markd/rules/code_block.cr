module Markd::Rule
  class CodeBlock
    include Rule

    CODE_FENCE = /^`{3,}(?!.*`)|^~{3,}(?!.*~)/
    CLOSING_CODE_FENCE = /^(?:`{3,}|~{3,})(?= *$)/

    def match(parser : Lexer, container : Node) : MatchValue
      if !parser.indented &&
         (match = text_clean(parser).match(CODE_FENCE))
        # fenced
        fence_length = match[0].size

        parser.close_unmatched_blocks
        node = parser.add_child(Node::Type::CodeBlock, parser.next_nonspace)
        node.fenced = true
        node.fence_length = fence_length
        node.fence_char = match[0][0].to_s
        node.fence_offset = parser.indent

        parser.advance_next_nonspace
        parser.advance_offset(fence_length, false)

        MatchValue::Leaf
      elsif parser.indented && !parser.blank &&
            parser.tip.not_nil!.type != Node::Type::Paragraph
        # indented
        parser.advance_offset(Rule::CODE_INDENT, true)
        parser.close_unmatched_blocks
        parser.add_child(Node::Type::CodeBlock, parser.offset)

        MatchValue::Leaf
      else
        MatchValue::None
      end
    end

    def continue(parser : Lexer, container : Node)
      line = parser.line
      indent = parser.indent
      if container.fenced
        # fenced
        # TODO: indent <= Rule::CODE_INDENT is missing first char
        match = indent <= Rule::CODE_INDENT &&
                line.byte_at(parser.next_nonspace) == container.fence_char &&
                line[parser.next_nonspace..-1].match(CLOSING_CODE_FENCE)
        if match && match.as(Regex::MatchData)[0].size >= container.fence_length
          parser.token(container, parser.current_line)
          return 2
        else
          index = container.fence_offset
          while index > 0 && blank?(char_code_at(parser, parser.offset))
            parser.advance_offset(1, true)
            index -= 1
          end
        end
      else
        # indented
        if indent >= Rule::CODE_INDENT
          parser.advance_offset(Rule::CODE_INDENT, true)
        elsif parser.blank
          parser.advance_next_nonspace
        else
          return 1
        end
      end

      0
    end

    def token(parser : Lexer, container : Node)
      if container.fenced
        content = container.text
        newline_pos = content.index("\n")
        newline_pos = -1 unless newline_pos
        first_line = content[0..newline_pos]
        text = content[newline_pos + 1..-1]
        container.fence_language = first_line.strip
        container.literal = text
      else
        container.literal = container.text.gsub(/(\n *)+$/, "\n")
      end

      # container.text = ""
    end

    def can_contain(t)
      false
    end

    def accepts_lines?
      true
    end
  end
end
