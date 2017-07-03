module Markd::Rule
  class HTMLBlock
    include Rule

    def match(parser : Lexer, container : Node)
      if !parser.indented && char_code_at(parser) == CHAR_CODE_LESSTHAN
        text = text_clean(parser)
        block_type_size = Rule::HTML_BLOCK_OPEN.size - 1

        0.upto(block_type_size) do |block_type|
          if (text =~ Rule::HTML_BLOCK_OPEN[block_type]) &&
             (block_type < block_type_size || container.type != Node::Type::Paragraph)

            parser.close_unmatched_blocks
            # We don't adjust parser.offset;
            # spaces are part of the HTML block:
            node = parser.add_child(Node::Type::HTMLBlock, parser.offset)
            node.data["html_block_type"] = block_type + 1

            return MatchValue::Leaf
          end
        end
      end

      MatchValue::None
    end

    def continue(parser : Lexer, container : Node)
      (parser.blank && [6, 7].includes?(container.data["html_block_type"])) ? 1 : 0
    end

    def token(parser : Lexer, container : Node)
      container.literal = container.text.gsub(/(\n *)+$/, "")
      container.text = ""
    end

    def can_contain(t)
      false
    end

    def accepts_lines?
      true
    end
  end
end
