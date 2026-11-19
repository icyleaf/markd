module Markd::Rule
  struct FootnoteDefinition
    include Rule

    def match(parser : Parser, container : Node) : MatchValue
      if match?(parser) && parser.gfm?
        parser.close_unmatched_blocks
        parser.add_child(Node::Type::FootnoteDefinition, 0)
        MatchValue::Leaf
      else
        MatchValue::None
      end
    end

    # Footnote definitions continue as long as lines are indented (4+ spaces)
    # Blank lines are allowed (they separate paragraphs inside footnotes)
    def continue(parser : Parser, container : Node) : ContinueStatus
      # Blank lines are allowed (separate paragraphs)
      return ContinueStatus::Continue if parser.blank

      # Indented content continues the definition
      return ContinueStatus::Continue if parser.indent >= Rule::CODE_INDENT

      ContinueStatus::Stop
    end

    def token(parser : Parser, container : Node) : Nil
      lines = container.text.split "\n"
      lines.each_with_index do |line, i|
        if i == 0
          # First line has the footnote definition label removed and
          # leading spaces removed.
          title = line.split("]:")[0]
          # Strip exactly the `[^` syntax prefix, not every leading
          # `[` or `^` character (labels may legitimately start with them).
          title = title[2..] if title.starts_with?("[^")
          container.data["title"] = title
          lines[i] = line.split("]:", 2)[1].lstrip
        elsif line == ""
          # Empty lines go as-is
          lines[i] = ""
        else
          # Subsequent lines have the leading indentation removed
          lines[i] = strip_code_indent(line)
        end
      end
      # Store the processed text for later block parsing
      container.text = lines.join("\n")
    end

    # Remove up to CODE_INDENT columns of leading whitespace, expanding
    # tabs to their column width, so tab-indented continuation lines keep
    # their content instead of losing characters.
    private def strip_code_indent(line : String) : String
      column = 0
      offset = 0
      while offset < line.size && column < Rule::CODE_INDENT
        char = line[offset]
        if char == ' '
          column += 1
          offset += 1
        elsif char == '\t'
          column += Rule::CODE_INDENT - (column % Rule::CODE_INDENT)
          offset += 1
        else
          break
        end
      end

      line[offset..]
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
