module Markd::Rule
  struct Table
    include Rule


    def match(parser : Parser, container : Node) : MatchValue
      if match?(parser) # Looks like the 1st line of a table
        parser.close_unmatched_blocks
        parser.add_child(Node::Type::Table, 0)

        MatchValue::Leaf
      else
        MatchValue::None
      end
    end

    def continue(parser : Parser, container : Node) : ContinueStatus
      # Only continue if line looks like a divider or a table row
      if match_continuation?(parser)
        ContinueStatus::Continue
      else
        ContinueStatus::Stop
      end
    end

    def token(parser : Parser, container : Node) : Nil
      # The table contents are in container.text (except the leading | in each line)
      # So, let's parse it and shove it into the tree

      original_text = container.text.rstrip.split("\n").map do |l|
        "#{l}"
      end.join("\n")
      lines = container.text.strip.split("\n")

      row_sizes = lines[...2].map do |l|
        l.strip.strip("|").split(TABLE_CELL_SEPARATOR).size
      end.uniq!

      # Do we have a real table?
      # * At least two lines
      # * Second line is a divider
      # * First two lines have the same number of cells

      if lines.size < 2 || !lines[1].match(TABLE_HEADING_SEPARATOR) ||
         row_sizes.size != 1
        # Not enough table or a broken table.
        # We need to convert it into a paragraph
        # I am fairly sure this is not supposed to work
        container.type = Node::Type::Paragraph
        # Patch the text to have the leading |s
        container.text = original_text
        return
      end

      max_row_size = row_sizes[0]
      has_body = lines.size > 2
      container.data["has_body"] = has_body

      alignments = lines[1].strip.strip("|").split(/(?<!\\)\|/).map do |cell|
        if cell.strip.starts_with?(":") && cell.strip.ends_with?(":")
          "center"
        elsif cell.strip.starts_with?(":")
          "left"
        elsif cell.strip.ends_with?(":")
          "right"
        else
          ""
        end
      end

      # Each line maps to a table row
      lines.each_with_index do |line, i|
        next if i == 1
        row = Node.new(Node::Type::TableRow)
        row.data["heading"] = i == 0
        row.data["has_body"] = has_body
        container.append_child(row)
        # This splits on | but not on \| (escaped |)
        cells = line.strip.strip("|").split(TABLE_CELL_SEPARATOR)[...max_row_size]

        # Each row should have exactly the same size as the header.
        while cells.size < max_row_size
          cells << ""
        end

        # Create cells with text and metadata
        cells.each_with_index do |text, j|
          cell = Node.new(Node::Type::TableCell)
          cell.text = text.strip
          cell.data["align"] = alignments[j]
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
      !parser.indented && \
         (parser.line[0]? == '|' || parser.line.match(TABLE_CELL_SEPARATOR)) &&
          parser.line.size > 2
    end

    private def match_continuation?(parser : Parser)
      !parser.indented && (parser.line[0]? == '|' || parser.line.match(TABLE_HEADING_SEPARATOR) || parser.line.match(TABLE_CELL_SEPARATOR))
    end
  end
end
