module Markd::Lexer
  class Block
    include Lexer

    def self.parse(context : Context)
      new.parse(context)
    end

    @rules = {
      Node::Type::Document => Rule::Document.new,
      Node::Type::BlockQuote => Rule::BlockQuote.new,
      Node::Type::Heading => Rule::Heading.new,
      Node::Type::CodeBlock => Rule::CodeBlock.new,
      Node::Type::HTMLBlock => Rule::HTMLBlock.new,
      Node::Type::ThematicBreak => Rule::ThematicBreak.new,
      Node::Type::List => Rule::List.new,
      Node::Type::Item => Rule::Item.new,
      Node::Type::Paragraph => Rule::Paragraph.new
    }

    property tip, offset, column

    getter inline_lexer, current_line, line_size, line, next_nonspace,
           next_nonspace_column, indent, indented, blank, partially_consumed_tab,
           all_closed, last_matched_container, refmap, last_line_length

    @inline_lexer = Lexer::Inline.new

    @document = Node.new(Node::Type::Document)
    @tip : Node?
    @tip = @document
    @oldtip = @tip
    @last_matched_container = @document

    @lines = [] of String
    @line = ""

    @current_line = 0
    @line_size = 0
    @offset = 0
    @column = 0

    @next_nonspace = 0
    @next_nonspace_column = 0

    @indent = 0
    @indented = false
    @blank = false
    @partially_consumed_tab = false
    @all_closed = true
    @last_matched_container = @document
    @refmap = {} of String => String
    @last_line_length = 0

    def parse(context : Context)
      @lines = context.source.split(/\r\n|\n|\r/)
      @line_size = @lines.size
      @lines.each do |line|
        process_line(line)
      end

      while @tip
        token(@tip.not_nil!, @line_size)
      end

      context.document = @document
    end

    def process_line(line : String)
      all_matched = true
      container = @document
      @oldtip = @tip
      @offset = @column = 0
      @blank = @partially_consumed_tab = false
      @current_line += 1
      @line = line

      while (last_child = container.last_child) && last_child.open
        container = last_child

        find_next_nonspace

        case @rules[container.type].continue(self, container)
        when 0
          break
        when 1
          all_matched = false
          break
        when 2
          @last_line_length = line.size
          return
        else
          raise Exception.new("continue returned illegal value, must be 0, 1, or 2")
        end

        unless all_matched
          container = container.parent.not_nil!
          break
        end
      end

      @all_closed = container == @oldtip
      @last_matched_container = container.not_nil!

      matched_leaf = container.type != Node::Type::Paragraph && @rules[container.type].accepts_lines?

      while !matched_leaf
        find_next_nonspace

        # this is a little performance optimization
        if !@indented && !@line[next_nonspace..-1].match(Rule::MAYBE_SPECIAL)
          advance_next_nonspace
          break
        end

        rule_index = 0
        rules_size = @rules.size

        while rule_index < rules_size
          puts "[#{rule_index}/#{rules_size - 1}] #{@rules.keys[rule_index]} #{container}"
          case @rules.values[rule_index].match(self, container.not_nil!)
          when Rule::MatchValue::Container
            container = @tip
            break
          when Rule::MatchValue::Leaf
            container = @tip
            matched_leaf = true
            break
          else
            rule_index += 1
          end
        end

        # nothing matched
        if rule_index == rules_size
          advance_next_nonspace
          break
        end
      end

      if !@all_closed && !@blank && @tip.not_nil!.type == Node::Type::Paragraph
        add_line
      else
        close_unmatched_blocks
        container.not_nil!.last_child.not_nil!.last_line_blank = true if (@blank && container.not_nil!.last_child)

        t = container.not_nil!.type
        cont = container
        while cont
          last_line_blank = @blank &&
                            !(t == Node::Type::BlockQuote ||
                            (t == Node::Type::CodeBlock && container.not_nil!.fenced?) ||
                            (t == Node::Type::Item && !container.not_nil!.first_child && container.not_nil!.source_pos[0][0] == @current_line))

          cont.not_nil!.last_line_blank = last_line_blank
          cont = cont.parent
        end

        if @rules[t].accepts_lines?
          add_line

          # if HtmlBlock, check for end condition
          if (t == Node::Type::HTMLBlock && match_html_block?(container.not_nil!))
            token(container.not_nil!, @current_line)
          end
        elsif @offset < line.size && !@blank
          container = add_child(Node::Type::Paragraph, @offset)
          advance_next_nonspace
          add_line
        end

        @last_line_length = line.size
      end
    end

    def token(container : Node, line_number : Int32)
      above = container.parent
      container.open = false
      container.source_pos[1] = [line_number, @last_line_length]
      @rules[container.type].token(self, container)

      @tip = above
    end

    def add_line
      if @partially_consumed_tab
        @offset += 1
        chars_to_tab = Rule::CODE_INDENT - (@column % 4)
        @tip.not_nil!.text += " " * chars_to_tab
      end

      @tip.not_nil!.text += @line[@offset..-1] + "\n"
    end

    def add_child(tag : Node::Type, offset : Int32) : Node
      while !@rules[@tip.not_nil!.type].can_contain(tag)
        token(@tip.not_nil!, @current_line - 1)
      end

      column_number = offset + 1
      node = Node.new(tag)
      node.source_pos = [[@current_line, column_number], [0, 0]]
      @tip.not_nil!.append_child(node)
      @tip = node

      node
    end

    def close_unmatched_blocks
      unless @all_closed
        while @oldtip != @last_matched_container
          parent = @oldtip.not_nil!.parent
          token(@oldtip.not_nil!, @current_line - 1)
          @oldtip = parent.not_nil!
        end

        @all_closed = true
      end
    end

    def find_next_nonspace
      offset = @offset
      column = @column

      if @line.empty?
        @blank = true
      else
        while char = @line[offset]
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

        @blank = char.whitespace?
      end

      @next_nonspace = offset
      @next_nonspace_column = column
      @indent = @next_nonspace_column - @column
      @indented = @indent >= Rule::CODE_INDENT
    end

    def advance_next_nonspace
      @offset = @next_nonspace
      @column - @next_nonspace_column
      @partially_consumed_tab = false
    end

    def advance_offset(count, columns = false)
      line = @line
      while count > 0 && (char = line[@offset])
        if char == "\t"
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
          @column += 1  # assume ascii; block starts are ascii
          @offset += 1
          count -= 1
        end
      end
    end

    private def match_html_block?(container : Node)
      if block_type = container.data["html_block_type"]
        block_type = block_type.as(Int32)
        block_type >= 1 && block_type <= 5 && Rule::HTML_BLOCK_CLOSE[block_type].match(@line[@offset..-1])
      else
        false
      end
    end
  end
end
