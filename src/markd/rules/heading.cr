module Markd::Rule
  class Heading
    include Rule

    ATX_HEADING_MARKER = /^ *(\#{1,6}) +([^\n]+?) *#* *(?:\n+|$)/
    SETEXT_HEADING_MARKER = /^(?:=+|-+)[ \t]*$/

    def token(context : Lexer, node : Node)
      # do nothing
    end

    def match(context : Lexer, node : Node) : MatchValue
      if match = match?(context, ATX_HEADING_MARKER)
        # ATX Heading matched
        context.advance_next_nonspace
        context.advance_offset(match[0].size, false)
        context.close_unmatched_blocks

        container = context.add_child(Node::Type::Heading, context.next_nonspace)
        container.data["level"] = match[1].chomp.size
        container.text = match[2]

        context.advance_offset(context.line.size - context.offset)

        MatchValue::Leaf
      elsif (match = match?(context, SETEXT_HEADING_MARKER)) &&
             node.type == Node::Type::Paragraph
        # Setext Heading matched
        context.close_unmatched_blocks
        heading = Node.new(Node::Type::Heading)
        heading.source_pos = node.source_pos
        # NOTE: match[0][0] is return char is cant equal to string with same char
        heading.data["level"] = match[0][0] == '=' ? 1 : 2
        heading.text = node.text

        node.insert_after(heading)
        node.unlink

        context.tip = heading
        context.advance_offset(context.line.size - context.offset, false)

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

    private def match?(context : Lexer, regex : Regex) : Regex::MatchData?
      match = text_clean(context).match(regex)
      !context.indented && match ? match : nil
    end
  end
end
