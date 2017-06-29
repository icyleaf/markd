module Markd::Rule
  class Heading
    include Rule

    def token(context : Lexer, node : Node)
      # do nothing
    end

    def match(context : Lexer, node : Node) : MatchValue
      if (!context.indented && (match = context.line.match(Rule::ATX_HEADING_MARKER)))
        # ATX Heading matched
        context.advance_next_nonspace!
        context.advance_offset(match[0].size, false)
        context.close_unmatched_blocks

        container = context.add_child(Node::Type::Heading, context.next_nonspace)
        container.data["level"] = match[1].chomp.size
        container.text = match[2]

        context.advance_offset(context.line.size - context.offset)

        MatchValue::Leaf
      else
        MatchValue::None
      end
    end

    def continue(context : Lexer, node : Node)
      # a heading can never container > 1 line, so fail to match
      1
    end

    def can_contain(t)
      false
    end

    def accepts_lines?
      false
    end
  end
end
