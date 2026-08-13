module Markd::Parser
  class Block
    include Parser

    def self.parse(source : String, options = Options.new)
      new(options).parse(source)
    end

    RULES = {
      Node::Type::Document           => Rule::Document.new,
      Node::Type::BlockQuote         => Rule::BlockQuote.new,
      Node::Type::Alert              => Rule::BlockQuote.new, # Alerts and BlockQuotes are the same
      Node::Type::Heading            => Rule::Heading.new,
      Node::Type::CodeBlock          => Rule::CodeBlock.new,
      Node::Type::HTMLBlock          => Rule::HTMLBlock.new,
      Node::Type::ThematicBreak      => Rule::ThematicBreak.new,
      Node::Type::List               => Rule::List.new,
      Node::Type::Item               => Rule::Item.new,
      Node::Type::Paragraph          => Rule::Paragraph.new,
      Node::Type::Table              => Rule::Table.new,
      Node::Type::FootnoteDefinition => Rule::FootnoteDefinition.new,
    }

    property! tip : Node?
    property offset, column

    getter line, current_line, blank, inline_lexer,
      indent, indented, next_nonspace, refmap

    delegate gfm?, tagfilter?, to: @options

    def initialize(@options : Options)
      @inline_lexer = Inline.new(@options)

      @document = Node.new(Node::Type::Document)
      @tip = @document
      @oldtip = @tip
      @last_matched_container = @tip

      @line = ""

      @current_line = 0
      @offset = 0
      @column = 0
      @last_line_length = 0

      @next_nonspace = 0
      @next_nonspace_column = 0

      @indent = 0
      @indented = false
      @blank = false
      @partially_consumed_tab = false
      @all_closed = true
      @refmap = {} of String => Hash(String, String) | String
    end

    def parse(source : String)
      Utils.timer("block parsing", @options.time?) do
        parse_blocks(source)
      end

      # Process footnote definitions - parse their content as blocks
      if @options.gfm?
        process_footnote_definitions
      end

      Utils.timer("inline parsing", @options.time?) do
        process_inlines
      end

      if @options.gfm?
        process_footnotes
      end

      @document
    end

    # Process footnotes: extract, resolve nested references, number them, and move definitions to end
    private def process_footnotes
      # Extract all footnotes and footnote definitions
      walker = @document.walker
      footnotes = {} of String => Array(Node)
      footnote_definitions = {} of String => Node
      while (event = walker.next)
        node, entering = event
        if node.type.footnote?
          title = node.data["title"].to_s
          footnotes[title] ||= [] of Node
          footnotes[title] << node
        elsif !entering && node.type.footnote_definition?
          footnote_definitions[node.data["title"].to_s] = node
        end
      end

      # Recursively resolve nested footnotes in definitions before numbering
      loop do
        new_nodes = 0
        footnotes.keys.each do |footnote_title|
          nodes = footnotes[footnote_title]?
          next unless nodes
          if !footnote_definitions.has_key?(footnote_title)
            nodes.each do |fn_node|
              fn_node.type = Node::Type::Text
              fn_node.text = "[^#{footnote_title}]"
            end
            footnotes.delete footnote_title
          else
            def_node = footnote_definitions[footnote_title]
            walker = def_node.walker
            while (event = walker.next)
              n, entering = event
              if entering && n.type.text?
                replaced = false
                n.text = n.text.gsub(/\[\^([^\]]+)\]/) do |m|
                  nested_label = $1
                  if footnote_definitions[nested_label]?
                    fn = Node.new(Node::Type::Footnote)
                    fn.data["title"] = nested_label
                    n.insert_after(fn)
                    footnotes[nested_label] ||= [] of Node
                    footnotes[nested_label] << fn
                    replaced = true
                    new_nodes += 1
                    ""
                  else
                    m
                  end
                end
                if replaced && n.parent?
                  @inline_lexer.parse(n.parent)
                end
                n.unlink if n.text.empty?
              end
            end
          end
        end
        break if new_nodes == 0
      end

      # Ensure all Footnote nodes are present in the footnotes hash
      walker = @document.walker
      while (event = walker.next)
        node, entering = event
        if node.type.footnote?
          title = node.data["title"].to_s
          footnotes[title] ||= [] of Node
          unless footnotes[title].includes?(node)
            footnotes[title] << node
          end
        end
      end

      # Remove definitions without footnotes
      footnote_definitions.keys.each do |footnote_title|
        def_node = footnote_definitions[footnote_title]?
        next unless def_node
        unless footnotes.has_key?(footnote_title)
          def_node.unlink
          footnote_definitions.delete footnote_title
        end
      end

      # Footnote numbers are normalized to 1...n
      # Each reference gets a ref_index (1, 2, 3...) and the definition gets a ref_count
      footnote_number = 0
      footnotes.each do |footnote_title, nodes|
        footnote_number += 1
        nodes.each_with_index do |fn_node, index|
          fn_node.data["number"] = footnote_number
          fn_node.data["ref_index"] = index + 1
        end
        footnote_definitions[footnote_title].data["number"] = footnote_number
        footnote_definitions[footnote_title].data["ref_count"] = nodes.size
      end

      # Footnote definitions are moved to the end of the document
      footnotes.each do |footnote_title, _|
        def_node = footnote_definitions[footnote_title]
        def_node.unlink
        @document.append_child(def_node)
      end

      # After all footnote definitions are attached, re-run inline parsing on their children
      footnote_definitions.each_value do |def_node|
        child = def_node.first_child?
        while child
          next_child = child.next?
          if child.type.paragraph? || child.type.heading? || child.type.table_cell?
            @inline_lexer.parse(child)
          end
          child = next_child
        end
      end

      nil
    end

    private def parse_blocks(source)
      lines_size = 0
      source.each_line do |line|
        process_line(line)
        lines_size += 1
      end

      # ignore last blank line created by final newline
      lines_size -= 1 if source.ends_with?('\n')

      while (tip = tip?)
        token(tip, lines_size)
      end
    end

    private def process_line(line : String)
      container = @document
      @oldtip = tip
      @offset = 0
      @column = 0
      @blank = false
      @partially_consumed_tab = false
      @current_line += 1

      line = line.gsub(Char::ZERO, '\u{FFFD}')
      @line = line

      while (last_child = container.last_child?) && last_child.open?
        container = last_child

        find_next_nonspace

        case RULES[container.type].continue(self, container)
        when Rule::ContinueStatus::Continue
          # we've matched, keep going
        when Rule::ContinueStatus::Stop
          # we've failed to match a block
          # back up to last matching block
          container = container.parent
          break
        when Rule::ContinueStatus::Return
          # we've hit end of line for fenced code close and can return
          @last_line_length = line.size
          return
        end
      end

      @all_closed = (container == @oldtip)
      @last_matched_container = container

      matched_leaf = !container.type.paragraph? && RULES[container.type].accepts_lines?

      while !matched_leaf
        find_next_nonspace

        # this is a little performance optimization
        unless @indented
          first_char = @line[@next_nonspace]?
          unless first_char && (Rule::MAYBE_SPECIAL.includes?(first_char) || first_char.ascii_number? || @line.match(Rule::TABLE_CELL_SEPARATOR))
            advance_next_nonspace
            break
          end
        end

        matched = RULES.each_value do |rule|
          case rule.match(self, container)
          when Rule::MatchValue::Container
            container = tip
            break true
          when Rule::MatchValue::Leaf
            container = tip
            matched_leaf = true
            break true
          else
            false
          end
        end

        # nothing matched
        unless matched
          advance_next_nonspace
          break
        end
      end

      if !@all_closed && !@blank && tip.type.paragraph?
        # lazy paragraph continuation
        add_line
      else
        # not a lazy continuation
        close_unmatched_blocks
        if @blank && (last_child = container.last_child?)
          last_child.last_line_blank = true
        end

        container_type = container.type
        last_line_blank = @blank &&
                          !(container_type.block_quote? ||
                            (container_type.code_block? && container.fenced?) ||
                            (container_type.item? && !container.first_child? && container.source_pos[0][0] == @current_line))

        cont = container
        while cont
          cont.last_line_blank = last_line_blank
          cont = cont.parent?
        end

        if RULES[container_type].accepts_lines?
          add_line

          # if HtmlBlock, check for end condition
          if container_type.html_block? && match_html_block?(container)
            token(container, @current_line)
          end
        elsif @offset < line.size && !@blank
          # create paragraph container for line
          add_child(Node::Type::Paragraph, @offset)
          advance_next_nonspace
          add_line
        end

        @last_line_length = line.size
      end

      nil
    end

    private def process_inlines
      walker = @document.walker
      @inline_lexer.refmap = @refmap
      while (event = walker.next)
        node, entering = event
        # Note: footnote_definition is not parsed here because its content
        # has already been parsed as blocks in process_footnote_definitions
        if !entering && (node.type.paragraph? || node.type.heading? || node.type.table_cell?)
          @inline_lexer.parse(node)
        end
      end

      nil
    end

    # Parse footnote definition contents as block-level content
    private def process_footnote_definitions
      walker = @document.walker
      while (event = walker.next)
        node, entering = event
        if entering && node.type.footnote_definition? && !node.text.empty?
          # Parse the footnote definition content as blocks
          content = node.text
          node.text = ""

          # Create a temporary sub-parser for the footnote content
          sub_parser = Block.new(@options)
          sub_doc = sub_parser.parse(content)

          # Move all children from the sub-document to the footnote definition
          child = sub_doc.first_child?
          while child
            next_child = child.next?
            child.unlink
            node.append_child(child)
            child = next_child
          end
        end
      end

      nil
    end

    def token(container : Node, line_number : Int32)
      container_parent = container.parent?

      container.open = false
      container.source_pos = {
        container.source_pos[0],
        {line_number, @last_line_length},
      }
      RULES[container.type].token(self, container)

      @tip = container_parent

      nil
    end

    private def add_line
      if @partially_consumed_tab
        @offset += 1 # skip over tab
        # add space characters
        chars_to_tab = Rule::CODE_INDENT - (@column % 4)
        tip.text += " " * chars_to_tab
      end

      tip.text += @line[@offset..-1] + "\n"

      nil
    end

    def add_child(type : Node::Type, offset : Int32) : Node
      while !RULES[tip.type].can_contain?(type)
        token(tip, @current_line - 1)
      end

      column_number = offset + 1 # offset 0 = column 1

      node = Node.new(type)
      node.source_pos = { {@current_line, column_number}, {0, 0} }
      node.text = ""
      tip.append_child(node)
      @tip = node

      node
    end

    def close_unmatched_blocks
      unless @all_closed
        while (oldtip = @oldtip) && oldtip != @last_matched_container
          parent = oldtip.parent?
          token(oldtip, @current_line - 1)
          @oldtip = parent
        end
        @all_closed = true
      end
      nil
    end

    private def find_next_nonspace
      offset = @offset
      column = @column

      if @line.empty?
        @blank = true
      else
        while (char = @line[offset]?)
          case char
          when ' '
            offset += 1
            column += 1
          when '\t'
            offset += 1
            column += (4 - (column % 4))
          else
            break
          end
        end

        @blank = {nil, '\n', '\r'}.includes?(char)
      end

      @next_nonspace = offset
      @next_nonspace_column = column
      @indent = @next_nonspace_column - @column
      @indented = @indent >= Rule::CODE_INDENT

      nil
    end

    def advance_offset(count : Int32, columns = false)
      line = @line
      while count > 0 && (char = line[@offset]?)
        if char == '\t'
          chars_to_tab = Rule::CODE_INDENT - (@column % 4)
          if columns
            @partially_consumed_tab = chars_to_tab > count
            chars_to_advance = chars_to_tab > count ? count : chars_to_tab
            @column += chars_to_advance
            @offset += @partially_consumed_tab ? 0 : 1
            count -= chars_to_advance
          else
            @partially_consumed_tab = false
            @column += chars_to_tab
            @offset += 1
            count -= 1
          end
        else
          @partially_consumed_tab = false
          @column += 1 # assume ascii; block starts are ascii
          @offset += 1
          count -= 1
        end
      end

      nil
    end

    def advance_next_nonspace
      @offset = @next_nonspace
      @column - @next_nonspace_column
      @partially_consumed_tab = false

      nil
    end

    private def match_html_block?(container : Node)
      if (block_type = container.data["html_block_type"])
        block_type = block_type.as(Int32)
        block_type >= 0 && block_type <= 4 && Rule::HTML_BLOCK_CLOSE[block_type].match(@line[@offset..-1])
      else
        false
      end
    end
  end
end
