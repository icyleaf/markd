module Markd::Rule
  struct FootnoteDefinition
    include Rule

    def match(parser : Parser, container : Node) : MatchValue
      if match?(parser) && parser.gfm
        parser.close_unmatched_blocks
        parser.add_child(Node::Type::FootnoteDefinition, 0)
        MatchValue::Leaf
      else
        MatchValue::None
      end
    end

    # Footnote definitions continue as long as lines are indented
    def continue(parser : Parser, container : Node) : ContinueStatus
      if parser.line.starts_with?("    ")
        ContinueStatus::Continue
      else
        ContinueStatus::Stop
      end
    end

    def token(parser : Parser, container : Node) : Nil
      lines = container.text.split "\n"
      lines.each_with_index do |line, i|
        if i == 0
          # First line has the footnote definition label removed and
          # leading spaces removed.
          container.data["title"] = line.split("]:")[0].lstrip("[^")
          lines[i] = line.split("]:", 2)[1].lstrip
        elsif line == ""
          # Empty lines go as-is
          lines[i] = ""
        else
          # Subsequent lines have the leading 4 spaces removed
          lines[i] = line[4..-1]
        end
      end
      container.text = lines.join("\n")
    end

    def can_contain?(type)
      true
    end

    # Footnote definitions can be multiline
    def accepts_lines? : Bool
      true
    end

    # Match only lines that look like the first line of a footnote definition:
    # Start with [^something]:

    private def match?(parser)
      !parser.indented && \
         parser.line.match(FOOTNOTE_DEFINITION_START)
    end
  end
end
