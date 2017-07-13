module Markd::Rule
  class List
    include Rule

    BULLET_LIST_MARKER = /^[*+-]/
    ORDERED_LIST_MARKER = /^(\d{1,9})([.)])/

    def match(parser : Lexer, container : Node)
      if (!parser.indented || container.type == Node::Type::List) &&
         (data = parse_list_marker(parser, container))

        return MatchValue::None if data.nil? || data.empty?

        parser.close_unmatched_blocks
        if parser.tip.not_nil!.type != Node::Type::List || !list_match?(container.data, data.not_nil!)
          list_node = parser.add_child(Node::Type::List, parser.next_nonspace)
          list_node.data = data
        end

        item_node = parser.add_child(Node::Type::Item, parser.next_nonspace)
        item_node.data = data

        MatchValue::Container
      else
        MatchValue::None
      end
    end

    def continue(parser : Lexer, container : Node)
      0
    end

    def token(parser : Lexer, container : Node)
      item = container.first_child
      while item
        if ends_with_blankline?(item) && item.next
          container.data["tight"] = false
          break
        end

        subitem = item.first_child.not_nil!
        while subitem
          if ends_with_blankline?(subitem) && (item.next || subitem.next)
            container.data["tight"] = false
            break
          end

          subitem = subitem.next
        end

        item = item.next
      end
    end

    def can_contain(t)
      t == Node::Type::Item
    end

    def accepts_lines?
      false
    end

    private def list_match?(list_data, item_data)
      list_data["type"] == item_data["type"] &&
      list_data["delimiter"] == item_data["delimiter"] &&
      list_data["bullet_char"] == item_data["bullet_char"]
    end

    private def parse_list_marker(parser : Lexer, container : Node) : Node::DataType
      line = text_clean(parser)

      empty_data = {} of String => Node::DataValue
      data = {
        "delimiter" => 0,
        "marker_offset" => parser.indent,
        "bullet_char" => "",
        "tight" => true,  # lists are tight by default
        "start" => -1
      } of String => Node::DataValue


      if match = line.match(BULLET_LIST_MARKER)
        data["type"] = "bullet"
        data["bullet_char"] = match[0][0].to_s
      elsif (match = line.match(ORDERED_LIST_MARKER)) &&
            (container.type != Node::Type::Paragraph || match[1] == "1")
        data["type"] = "ordered"
        data["start"] = match[1].to_i
        data["delimiter"] = match[2]
      else
        return empty_data
      end

      # make sure we have spaces after
      first_match_size = match[0].size
      next_char = char_code_at(parser, parser.next_nonspace + first_match_size)
      if !(next_char == -1 || blank?(next_char))
        return empty_data
      end

      if container.type == Node::Type::Paragraph &&
         !text_clean(parser, parser.next_nonspace + first_match_size).match(Rule::NONSPACE)
         return empty_data
      end

      parser.advance_next_nonspace
      parser.advance_offset(first_match_size, true)
      spaces_start_column = parser.column
      spaces_start_offset = parser.offset

      loop do
        parser.advance_offset(1, true)
        next_char = char_code_at(parser, parser.offset)

        break unless parser.column - spaces_start_column < 5 && blank?(next_char)
      end

      blank_item = char_code_at(parser, parser.offset).nil?
      spaces_after_marker = parser.column - spaces_start_column
      if spaces_after_marker >= 5 || spaces_after_marker < 1 || blank_item
        data["padding"] = match[0].size + 1
        parser.column = spaces_start_column
        parser.offset = spaces_start_offset

        parser.advance_offset(1, true) if blank?(char_code_at(parser, parser.offset))
      else
        data["padding"] = match[0].size + spaces_after_marker
      end

      data
    end

    private def ends_with_blankline?(container : Node) : Bool
      while container
        return true if container.last_line_blank

        break unless [Node::Type::List, Node::Type::Item].includes?(container.type)
        container = container.last_child
      end

      false
    end
  end
end
