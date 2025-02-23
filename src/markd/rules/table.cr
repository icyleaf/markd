module Markd::Rule
  struct Table
    include Rule

    SEPARATOR_REGEX = /^(\|?\s*-+\s*)+(\||\s*)$/

    def match(parser : Parser, container : Node) : MatchValue
      if match?(parser)
        seek(parser)
        parser.close_unmatched_blocks
        parser.add_child(Node::Type::Table, 0)

        MatchValue::Leaf
      else
        MatchValue::None
      end
    end

    def continue(parser : Parser, container : Node) : ContinueStatus
      if match_continuation?(parser)
        seek(parser)
        ContinueStatus::Continue
      else
        ContinueStatus::Stop
      end
    end

    def token(parser : Parser, container : Node) : Nil
      # The table contents are in container.text (except the leading | in each line)
      # So, let's parse it and shove them into the tree

      original_text = container.text.rstrip.split("\n").map do |l|
        "|#{l}"
      end.join("\n")
      lines = container.text.strip.split('\n')

      # Make all lines end with '|'
      lines = lines.map do |l|
        if l.rstrip.ends_with? '|'
          l
        else
          l + '|'
        end
      end

      row_sizes = lines[...2].map(&.count "|").uniq!

      # Do we have a real table?
      # * At least two lines
      # * Second line is a divider
      # * First two lines have the same number of cells

      if lines.size < 2 || !"|#{lines[1]}".match(SEPARATOR_REGEX) ||
         row_sizes.size != 1
        # Not enough table. We need to convert it into a paragraph
        # Turn the table into a paragraph. I am fairly sure this is not supposed to work
        container.type = Node::Type::Paragraph
        # Patch the text to have the leading |s
        container.text = original_text
        return
      end

      max_row_size = row_sizes[0]
      has_body = lines.size > 2
      container.data["has_body"] = has_body

      lines.each_with_index do |line, i|
        next if i == 1
        row = Node.new(Node::Type::TableRow)
        row.data["heading"] = i == 0
        row.data["has_body"] = has_body
        container.append_child(row)
        # This splits on | but not on \| (escaped |)
        cells = line.rstrip.rstrip("|").split(/(?<!\\)\|/)[...max_row_size]
        while cells.size < max_row_size
          cells << ""
        end
        cells.each do |text|
          cell = Node.new(Node::Type::TableCell)
          cell.text = text.strip
          cell.data["heading"] = i == 0
          row.append_child(cell)
        end
      end
    end

    def can_contain?(type : Node::Type) : Bool
      !type.container?
    end

    def accepts_lines? : Bool
      true
    end

    private def match?(parser)
      !parser.indented && parser.line[0]? == '|'
    end

    private def match_continuation?(parser : Parser)
      !parser.indented && (parser.line[0]? == '|' || parser.line.match(SEPARATOR_REGEX))
    end

    private def seek(parser : Parser)
      parser.advance_offset(1, false)
    end
  end
end
