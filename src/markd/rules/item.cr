module Markd::Rule
  struct Item
    include Rule

    def match(parser : Lexer, container : Node)
      # match and parse in Rule::List
      MatchValue::None
    end

    def continue(parser : Lexer, container : Node)
      indent_offset = container.data["marker_offset"].as(Int32) + container.data["padding"].as(Int32)

      if parser.blank
        if container.first_child
          parser.advance_next_nonspace
        else
          # Blank line after empty list item
          return 1
        end
      elsif parser.indent >= indent_offset
        parser.advance_offset(indent_offset, true)
      else
        return 1
      end

      0
    end

    def token(parser : Lexer, container : Node)
      # do nothing
    end

    def can_contain(type : Node::Type)
      type != Node::Type::Item
    end

    def accepts_lines?
      false
    end
  end
end
