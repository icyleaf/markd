require "html"

module Markd::Lexer
  class Inline
    include Lexer

    property refmap

    @delimiters : Delimiter?

    def initialize(@options : Options)
      @text = ""
      @pos = 0
      @refmap = {} of String => Hash(String, String)|String
    end

    def parse(node : Node)
      @pos = 0
      @delimiters = nil
      @text = node.text.strip

      loop do
        break unless process_line(node)
      end

      node.text = ""
      process_emphasis(nil)
    end

    def process_line(node : Node)
      char = peek
      return false if char == -1

      res = case char
            when Rule::CHAR_CODE_NEWLINE
              newline(node)
            when Rule::CHAR_CODE_BACKSLASH
              backslash(node)
            when Rule::CHAR_CODE_BACKTICK
              backtick(node)
            when Rule::CHAR_CODE_ASTERISK, Rule::CHAR_CODE_UNDERSCORE
              handle_delim(char, node)
            when Rule::CHAR_CODE_SINGLE_QUOTE, Rule::CHAR_CODE_DOUBLE_QUOTE
              @options.smart && handle_delim(char, node)
            when Rule::CHAR_CODE_OPEN_BRACKET
              open_bracket(node)
            when Rule::CHAR_CODE_BANG
              bang(node)
            when Rule::CHAR_CODE_CLOSE_BRACKET
              close_bracket(node)
            when Rule::CHAR_CODE_LESSTHAN
              auto_link(node) || html_tag(node)
            when Rule::CHAR_CODE_AMPERSAND
              entity(node)
            else
              string(node)
            end

      unless res
        @pos += 1
        node.append_child(text(char.unsafe_chr))
      end

      true
    end

    def newline(node : Node)
      @pos += 1 # assume we're at a \n
      last_child = node.last_child
      # check previous node for trailing spaces
      if last_child && last_child.type == Node::Type::Text &&
         last_child.text[last_child.text.size - 1] == " "

        hard_break = last_child.text[last_child.text.size - 2]
        last_child.text = last_child.text.gsub(Rule::FINAL_SPACE, "")
        node.append_child(Node.new(hard_break ? Node::Type::LineBreak : Node::Type::SoftBreak))
      else
        node.append_child(Node.new(Node::Type::SoftBreak))
      end

      # gobble leading spaces in next line
      match(Rule::INITIAL_SPACE)

      true
    end

    def backslash(node : Node)
      @pos += 1

      char = @text.size > @pos ? @text[@pos].to_s : nil
      child = if peek == Rule::CHAR_CODE_NEWLINE
                @pos += 1
                Node.new(Node::Type::Linebreak)
              elsif char && char.match(Rule::ESCAPABLE)
                c = text(char)
                @pos += 1
                c
              else
                text("\\")
              end

      node.append_child(child)

      true
    end

    def backtick(node : Node)
      ticks = match(Rule::TICKS_HERE)
      return false unless ticks

      after_open_ticks = @pos
      while text = match(Rule::TICKS)
        if text == ticks
          child = Node.new(Node::Type::Code)
          child.text = @text[after_open_ticks..(@pos - ticks.size)]
          node.append_child(child)

          return true
        end
      end

      @pos = after_open_ticks
      node.append_child(text(ticks))

      true
    end

    def bang(node : Node)
      start_pos = @pos
      @pos += 1
      if peek == Rule::CHAR_CODE_OPEN_BRACKET
        @pos += 1
        child = text("![")
        node.append_child(child)

        add_bracket(child, start_pos + 1, true)
      else
        node.append_child(text("!"))
      end

      true
    end

    def add_bracket(node : Node, index : Int32, image = false)
      @brackets.not_nil!.bracket_after = true if @brackets
      @brackets = Bracket.new(node, @brackets, @delimiters, index, image, true)
    end

    def remove_bracket
      @brackets = @brackets.not_nil!.previous
    end

    def open_bracket(node : Node)
      start_pos = @pos
      @pos += 1

      child = text("[")
      node.append_child(child)

      add_bracket(child, start_pos, false)

      true
    end

    def close_bracket(node : Node)
      matched = false
      @pos += 1
      start_pos = @pos

      opener = @brackets
      unless opener
        node.append_child(text("]"))
        return true
      end

      unless opener.active
        node.append_child(text("]"))
        remove_bracket
        return true
      end

      is_image = opener.image
      save_pos = @pos

      if peek == Rule::CHAR_CODE_OPEN_PAREN
        @pos += 1
        if spnl &&
           ((dest = link_destination != nil) &&
           spnl && (@text[@pos-1..-1] &&
           (title = link_title || true)) &&
           spnl && peek == Rule::CHAR_CODE_CLOSE_PAREN)
          @pos += 1
          matched = true
        else
          @pos = save_pos
        end
      end

      unless matched
        child = Node.new(is_image ? Node::Type::Image : Node::Type::Link)
        child.data["destination"] = dest.not_nil!
        child.data["title"] = title || ""

        tmp = opener.node.next
        while tmp
          next_node = tmp.next
          tmp.unlink
          child.append_child(tmp)
          tmp = next_node
        end

        node.append_child(child)
        process_emphasis(opener.previous_delimiter)
        remove_bracket
        opener.node.unlink

        unless is_image
          opener = @brackets
          while opener
            opener.active = false unless opener.image
            opener = opener.previous
          end
        end
      else
        remove_bracket
        @pos = start_pos
        node.append_child(text("]"))
      end

      true
    end

    def process_emphasis(delimiter : Delimiter?)
      openers_bottom = {
        Rule::CHAR_CODE_UNDERSCORE => delimiter,
        Rule::CHAR_CODE_ASTERISK => delimiter,
        Rule::CHAR_CODE_SINGLE_QUOTE => delimiter,
        Rule::CHAR_CODE_DOUBLE_QUOTE => delimiter,
      } of Int32 => Delimiter?

      closer = @delimiters
      while closer && closer.previous != delimiter
        closer = closer.previous
      end

      while closer
        closer_codepoint = closer.codepoint
        unless closer.can_close
          closer = closer.next
        else
          opener = closer.previous
          opener_found = false
          while !opener.nil? && opener != delimiter && opener != openers_bottom[closer_codepoint]
            odd_match = (closer.can_open || opener.can_close) &&
                        (opener.orig_delims + closer.orig_delims) % 3 == 0
            if opener.codepoint == closer.codepoint && opener.can_open && !odd_match
              opener_found = true
              break
            end
            opener = opener.previous
          end

          old_closer = closer

          if [Rule::CHAR_CODE_ASTERISK, Rule::CHAR_CODE_UNDERSCORE].includes?(closer_codepoint)
            unless opener_found
              closer = closer.next
            else
              # calculate actual number of delimiters used from closer
              use_delims = (closer.num_delims >= 2 && opener.not_nil!.num_delims >= 2) ? 2 : 1
              opener_inl = opener.not_nil!.node
              closer_inl = closer.not_nil!.node

              # remove used delimiters from stack elts and inlines
              opener.not_nil!.num_delims -= use_delims
              closer.not_nil!.num_delims -= use_delims
              opener_inl.not_nil!.text = opener_inl.not_nil!.text[0..(opener_inl.text.size - use_delims)]
              closer_inl.not_nil!.text = closer_inl.not_nil!.text[0..(closer_inl.text.size - use_delims)]

              # build contents for new emph element
              emph = Node.new(use_delims ? Node::Type::Emphasis : Node::Type::Strong)

              tmp = opener_inl.not_nil!.next
              while tmp && tmp != closer_inl
                next_node = tmp.next
                tmp.unlink
                emph.append_child(tmp)
                tmp = next_node
              end

              opener_inl.insert_after(emph)

              # remove elts between opener and closer in delimiters stack
              remove_delimiter_between(opener.not_nil!, closer.not_nil!)

              # if opener has 0 delims, remove it and the inline
              if opener.not_nil!.num_delims == 0
                opener_inl.unlink
                remove_delimiter(opener.not_nil!)
              end

              if closer.not_nil!.num_delims == 0
                closer_inl.unlink
                tmp_stack = closer.next
                remove_delimiter(closer.not_nil!)
                closer = tmp_stack
              end
            end
          elsif closer_codepoint == Rule::CHAR_CODE_SINGLE_QUOTE
            closer.not_nil!.node.text = "\u{2019}"
            opener.not_nil!.node.text = "\u{2018}" if opener_found
            closer = closer.next
          elsif closer_codepoint == Rule::CHAR_CODE_DOUBLE_QUOTE
            closer.not_nil!.node.text = "\u{201D}"
            opener.not_nil!.node.text = "\u{201C}" if opener_found
            closer = closer.next
          end

          if !opener_found && !odd_match
            openers_bottom[closer_codepoint] = old_closer.previous
            remove_delimiter(old_closer) if !old_closer.can_open
          end
        end

        while @delimiters && @delimiters != delimiter
          remove_delimiter(@delimiters.not_nil!)
        end
      end
    end

    def auto_link(node : Node)
      if text = match(Rule::EMAIL_AUTO_LINK)
        node.append_child(link(text, true))
        return true
      elsif text = match(Rule::AUTO_LINK)
        node.append_child(link(text, false))
        return true
      end

      false
    end

    def html_tag(node : Node)
      if text = match(Rule::HTML_TAG)
        child = Node.new(Node::Type::HTMLInline)
        child.text = text
        node.append_child(child)
        true
      else
        false
      end
    end

    def entity(node : Node)
      if text = match(Rule::ENTITY_HERE)
        node.append_child(text(HTML.unescape(text)))
        true
      else
        false
      end
    end

    def string(node : Node)
      if text = match(Rule::MAIN)
        if @options.smart
          text = text.gsub(Rule::ELLIPSES, "\u{2026}")
                     .gsub(Rule::DASH) do |chars|
                       en_count = em_count = 0
                       chars_length = chars.size

                       if chars_length % 3 == 0
                         em_count = chars_length / 3
                       elsif chars_length % 2 == 0
                         en_count = chars_length / 2
                       elsif chars_length % 3 == 2
                         en_count = 1
                         em_count = (chars_length - 2) / 3
                       else
                         en_count = 2
                         em_count = (chars_length - 4) / 3
                       end

                       "\u{2014}" * em_count + "\u{2013}" * en_count
                     end
        end
        node.append_child(text(text))
        true
      else
        false
      end
    end

    def link(match : String, email = false) : Node
      dest = match[1..match.size-1]
      destination = email ? "mailto:#{dest}" : dest

      node = Node.new(Node::Type::Link)
      node.data["title"] = ""
      node.data["destination"] = destination
      node.append_child(text(dest))
      node
    end

    def link_label
      text = match(Rule::LINK_LABEL)
      if !text || text.not_nil!.size > 1001 || text =~ /[^\\]\\\]$/
        0
      else
        text.not_nil!.size
      end
    end

    def link_title
      title = match(Rule::LINK_TITLE)
      return unless title

      HTML.unescape(title[1..title.size-2])
    end

    def link_destination
      res = match(Rule::LINK_DESTINATION_BRACES)
      return HTML.unescape(res[1..res.size-2]) if res

      save_pos = @pos
      open_parens = 0
      while (codepoint = peek) != -1
        if codepoint == Rule::CHAR_CODE_BACKSLASH
          @pos += 1
          @pos += 1 if peek != -1
        elsif codepoint == Rule::CHAR_CODE_OPEN_PAREN
          @pos += 1
          open_parens += 1
        elsif codepoint == Rule::CHAR_CODE_CLOSE_PAREN
          break if open_parens < 1

          @pos += 1
          open_parens -= 1
        elsif codepoint.unsafe_chr =~ Rule::WHITESPACE_CHAR
          break
        else
          @pos += 1
        end
      end

      res = @text[save_pos..(@pos - save_pos)]
      HTML.unescape(res)
    end

    def handle_delim(codepoint : Int32, node : Node)
      res = scan_delims(codepoint)
      return false unless res

      num_delims = res["num_delims"].as(Int32)
      start_pos = @pos
      @pos += num_delims
      text = case codepoint
              when Rule::CHAR_CODE_SINGLE_QUOTE
                "\u{2019}"
              when Rule::CHAR_CODE_DOUBLE_QUOTE
                "\u{201C}"
              else
                @text[start_pos..@pos-1]
              end

      child = text(text)
      node.append_child(child)

      @delimiters = Delimiter.new(codepoint, num_delims, num_delims, child, @delimiters, nil,
                                   res["can_open"].as(Bool), res["can_close"].as(Bool))

      @delimiters.not_nil!.previous.not_nil!.next = @delimiters if @delimiters.not_nil!.previous

      true
    end

    def remove_delimiter(delimiter : Delimiter)
      delimiter.previous.not_nil!.next = delimiter.next if delimiter.previous

      unless delimiter.next
        @delimiters = delimiter.previous
      else
        delimiter.next.not_nil!.previous = delimiter.previous
      end
    end

    def remove_delimiter_between(bottom : Delimiter, top : Delimiter)
      if bottom.next != top
        bottom.next = top
        top.previous = bottom
      end
    end

    def scan_delims(codepoint : Int32)
      num_delims = 0
      start_pos = @pos
      if [Rule::CHAR_CODE_SINGLE_QUOTE, Rule::CHAR_CODE_DOUBLE_QUOTE].includes?(codepoint)
        num_delims += 1
        @pos += 1
      else
        while peek == codepoint
          num_delims += 1
          @pos += 1
        end
      end

      return if num_delims == 0

      codepoint_after = peek
      char_before = start_pos == 0 ? '\n'  : @text[start_pos - 1]
      char_after = codepoint_after == -1 ? '\n' : codepoint_after.unsafe_chr

      after_is_whitespace = (char_after =~ Rule::UNICODE_WHITESPACE_CHAR).nil? ? false : true
      after_is_punctuation = (char_after =~ Rule::PUNCTUATION).nil? ? false : true
      before_is_whitespace = (char_before =~ Rule::UNICODE_WHITESPACE_CHAR).nil? ? false : true
      before_is_punctuation = (char_before =~ Rule::PUNCTUATION).nil? ? false : true

      left_flanking = !after_is_whitespace &&
                      (!after_is_punctuation || before_is_whitespace || before_is_punctuation)
      right_flanking = !before_is_whitespace &&
                       (!before_is_punctuation || after_is_whitespace || after_is_punctuation)

      if codepoint == Rule::CHAR_CODE_UNDERSCORE
        can_open = left_flanking && (!right_flanking || before_is_punctuation)
        can_close = right_flanking && (!left_flanking || after_is_punctuation)
      elsif [Rule::CHAR_CODE_SINGLE_QUOTE, Rule::CHAR_CODE_DOUBLE_QUOTE].includes?(codepoint)
        can_open = left_flanking && !right_flanking
        can_close = right_flanking
      else
        can_open = left_flanking
        can_close = right_flanking
      end

      @pos = start_pos

      {
        "num_delims" => num_delims,
        "can_open" => can_open,
        "can_close" => can_close
      }
    end

    def reference(text : String, refmap)
      @text = text
      @pos = 0

      startpos = @pos
      # match_chars = link_label

      # # label
      # return 0 if match_chars == 0
      # raw_label = @text[0..match_chars]

      # # colon
      # if peek == Rule::CHAR_CODE_COLON
      #   @pos += 1
      # else
      #   @pos = startpos
      #   return 0
      # end

      # # link url
      # spnl

      # dest = link_destination
      # if dest.size == 0
      #   @pos = startpos
      #   return 0
      # end

      # before_title = @pos
      # spnl
      # title = link_title
      # unless title
      #   title = ""
      #   @pos = before_title
      # end

      # at_line_end = true
      # unless match(Rule::SPACE_AT_END_OF_LINE)
      #   if title.empty?
      #     at_line_end = false
      #   else
      #     title = ""
      #     @pos = before_title
      #     at_line_end = match(Rule::SPACE_AT_END_OF_LINE) != nil
      #   end
      # end

      # unless at_line_end
      #   @pos = startpos
      #   return 0
      # end

      # normal_label = HTML.escape(raw_label)
      # unless normal_label
      #   @pos = startpos
      #   return 0
      # end

      # unless refmap[normal_label]
      #   refmap[normal_label] = {
      #     "destination" => dest,
      #     "title" => title
      #   }
      # end

      return @pos - startpos
    end

    private def peek : Int32
      @pos < @text.size ? @text[@pos].ord : -1
    end

    private def spnl
      match(Rule::SPNL)
      return
    end

    private def match(regex : Regex) : String?
      text = @text[@pos..-1]
      if match = text.match(regex)
        @pos += text.index(regex).not_nil! + match[0].size
        return match[0]
      end
    end

    private def text(string : Char) : Node
      text(string.to_s)
    end

    private def text(string : String) : Node
      node = Node.new(Node::Type::Text)
      node.text = string
      node
    end

    class Bracket
      property node : Node
      property previous : Bracket?
      property previous_delimiter : Delimiter?
      property index : Int32
      property image : Bool
      property active : Bool
      property bracket_after : Bool

      def initialize(@node, @previous, @previous_delimiter, @index, @image, @active = true)
        @bracket_after = false
      end
    end

    class Delimiter
      property codepoint : Int32
      property num_delims : Int32
      property orig_delims : Int32
      property node : Node
      property previous : Delimiter?
      property next : Delimiter?
      property can_open : Bool
      property can_close : Bool

      def initialize(@codepoint, @num_delims, @orig_delims, @node,
                     @previous, @next, @can_open, @can_close)
      end
    end

  end
end
