module Markd::Rule
  struct Table
    include Rule

    def match(parser : Parser, container : Node) : MatchValue
      if match?(parser)
        seek(parser)
        parser.close_unmatched_blocks
        node = parser.add_child(Node::Type::Table, parser.next_nonspace)

        MatchValue::Container
      else
        MatchValue::None
      end
    end

    def continue(parser : Parser, container : Node) : ContinueStatus
      if match?(parser)
        seek(parser)
        ContinueStatus::Continue
      else
        ContinueStatus::Stop
      end
    end

    def token(parser : Parser, container : Node) : Nil
      # The table contents are in container.text (except the leading | in each line)
      # So, let's parse it and shove it into container.data
    end

    def can_contain?(type : Node::Type) : Bool
      !type.container?
    end

    def accepts_lines? : Bool
      true
    end

    private def match?(parser)
      !parser.indented && parser.line[parser.next_nonspace]? == '|'
    end

    private def seek(parser : Parser)
      parser.advance_next_nonspace
      parser.advance_offset(1, false)

      if space_or_tab?(parser.line[parser.offset]?)
        parser.advance_offset(1, true)
      end
    end
  end
end
