module Markd::Lexer
  class Block
    include Lexer
    include Utils

    def self.parse(source : String)
      new(Options.new).parse(source)
    end

    def self.parse(source : String, options : Options)
      new(options).parse(source)
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

    property tip : Node?
    property offset, column

    getter line, current_line, blank, inline_lexer,
           indent, indented, next_nonspace, refmap

    def initialize(@options : Options)
      @inline_lexer = Lexer::Inline.new(@options)

      @document = Node.new(Node::Type::Document)
      @tip = @document
      @oldtip = @tip
      @last_matched_container = @tip

      @lines = [] of String
      @line = ""

      @current_line = 0
      @line_size = 0
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
      @refmap = {} of String => Hash(String, String)|String
    end

    def parse(source : String)
      start_time("preparing input") if @options.time
      @lines = source.split(Rule::LINE_ENDING)
      @line_size = @lines.size
      # ignore last blank line created by final newline
      @line_size -= 1 if source.byte_at(source.size - 1) == Rule::CHAR_CODE_NEWLINE
      end_time("preparing input") if @options.time

      start_time("block parsing") if @options.time
      @lines.each { |line| process_line(line) }
      while tip = @tip
        token(tip, @line_size)
      end
      end_time("block parsing") if @options.time

      start_time("inline parsing") if @options.time
      process_inlines
      end_time("inline parsing") if @options.time

      @document
    end

    def process_line(line : String)
      all_matched = true
      container = @document
      @oldtip = @tip
      @offset = @column = 0
      @blank = @partially_consumed_tab = false
      @current_line += 1

      line = line.gsub(/\0/, "\u{FFFD}") if line.includes?("\u{0000}")
      @line = line

      while (last_child = container.last_child) && last_child.open
        container = last_child

        find_next_nonspace

        case @rules[container.type].continue(self, container)
        when 0
          # we've matched, keep going
        when 1
          # we've failed to match a block
          all_matched = false
        when 2
          # we've hit end of line for fenced code close and can return
          @last_line_length = line.size
          return
        else
          raise Exception.new("continue returned illegal value, must be 0, 1, or 2")
        end

        unless all_matched
          # back up to last matching block
          container = container.parent.not_nil!
          break
        end
      end

      @all_closed = container == @oldtip
      @last_matched_container = container.not_nil!

      matched_leaf = container.type != Node::Type::Paragraph && @rules[container.type].accepts_lines?

      rules_size = @rules.size
      while !matched_leaf
        find_next_nonspace

        # this is a little performance optimization
        if !@indented && !slice(@line, @next_nonspace).match(Rule::MAYBE_SPECIAL)
          advance_next_nonspace
          break
        end

        rule_index = 0
        while rule_index < rules_size
          case @rules.values[rule_index].match(self, container.not_nil!)
          when Rule::MatchValue::Container
            container = @tip.not_nil!
            break
          when Rule::MatchValue::Leaf
            container = @tip.not_nil!
            matched_leaf = true
            break
          else
            rule_index += 1
          end
        end

        # nothing matched
        if rule_index == rules_size
          # nothing matched
          advance_next_nonspace
          break
        end
      end

      if !@all_closed && !@blank && @tip.not_nil!.type == Node::Type::Paragraph
        # lazy paragraph continuation
        add_line
      else
        # not a lazy continuation
        close_unmatched_blocks
        if (@blank && container.last_child)
          container.last_child.not_nil!.last_line_blank = true
        end

        container_type = container.type
        last_line_blank = @blank &&
                          !(container_type == Node::Type::BlockQuote ||
                          (container_type == Node::Type::CodeBlock && container.fenced?) ||
                          (container_type == Node::Type::Item && !container.first_child && container.source_pos[0][0] == @current_line))

        cont = container
        while cont
          cont.not_nil!.last_line_blank = last_line_blank
          cont = cont.parent
        end

        if @rules[container_type].accepts_lines?
          add_line

          # if HtmlBlock, check for end condition
          if (container_type == Node::Type::HTMLBlock && match_html_block?(container))
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

    def process_inlines
      walker = @document.walker
      @inline_lexer.refmap = @refmap
      while (event = walker.next)
        node = event["node"].as(Node)
        if !event["entering"].as(Bool) && [Node::Type::Paragraph, Node::Type::Heading].includes?(node.type)
          @inline_lexer.parse(node)
        end
      end

      nil
    end

    def token(container : Node, line_number : Int32)
      above = container.parent
      container.open = false
      container.source_pos[1] = [line_number, @last_line_length]
      @rules[container.type].token(self, container)

      @tip = above

      nil
    end

    def add_line
      if @partially_consumed_tab
        @offset += 1 # skip over tab
        # add space characters
        chars_to_tab = Rule::CODE_INDENT - (@column % 4)
        @tip.not_nil!.text += " " * chars_to_tab
      end

      @tip.not_nil!.text += slice(@line, @offset) + "\n"

      nil
    end

    def add_child(type : Node::Type, offset : Int32) : Node
      while !@rules[@tip.not_nil!.type].can_contain(type)
        token(@tip.not_nil!, @current_line - 1)
      end

      column_number = offset + 1 # offset 0 = column 1

      node = Node.new(type)
      node.source_pos = [[@current_line, column_number], [0, 0]]
      node.text = ""
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
      nil
    end

    def find_next_nonspace
      offset = @offset
      column = @column

      if @line.empty?
        @blank = true
      else
        while char = char_code(@line, offset)
          case char
          when Rule::CHAR_CODE_SPACE
            offset += 1
            column += 1
          when Rule::CHAR_CODE_TAB
            offset += 1
            column += (4 - (column % 4))
          else
            break
          end
        end

        @blank = [Rule::CHAR_CODE_NONE,
                  Rule::CHAR_CODE_NEWLINE,
                  Rule::CHAR_CODE_CARRIAGE].includes?(char)
      end

      @next_nonspace = offset
      @next_nonspace_column = column
      @indent = @next_nonspace_column - @column
      @indented = @indent >= Rule::CODE_INDENT

      nil
    end

    def advance_offset(count, columns = false)
      line = @line
      while count > 0 && (char = char_code(line, @offset))
        if char == Rule::CHAR_CODE_TAB
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

      nil
    end

    def advance_next_nonspace
      @offset = @next_nonspace
      @column - @next_nonspace_column
      @partially_consumed_tab = false

      nil
    end

    private def match_html_block?(container : Node)
      if block_type = container.data["html_block_type"]
        block_type = block_type.as(Int32)
        block_type >= 1 && block_type <= 5 && Rule::HTML_BLOCK_CLOSE[block_type].match(slice(@line, @offset))
      else
        false
      end
    end
  end
end
