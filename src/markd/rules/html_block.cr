module Markd::Rule
  struct HTMLBlock
    include Rule

    def match(parser : Lexer, container : Node)
      if !parser.indented && char_code(parser) == CHAR_CODE_LESSTHAN
        text = slice(parser)
        block_type_size = Rule::HTML_BLOCK_OPEN.size - 1

        Rule::HTML_BLOCK_OPEN.each_with_index do |regex, index|
          if (text.match(regex) &&
             (index < block_type_size || container.type != Node::Type::Paragraph))
            parser.close_unmatched_blocks
            # We don't adjust parser.offset;
            # spaces are part of the HTML block:
            node = parser.add_child(Node::Type::HTMLBlock, parser.offset)
            node.data["html_block_type"] = index

            return MatchValue::Leaf
          end
        end
      end

      MatchValue::None
    end

    def continue(parser : Lexer, container : Node)
      (parser.blank && [5, 6].includes?(container.data["html_block_type"])) ? 1 : 0
    end

    def token(parser : Lexer, container : Node)
      container.text = container.text.gsub(/(\n *)+$/, "")
    end

    def can_contain(t)
      false
    end

    def accepts_lines?
      true
    end
  end
end
