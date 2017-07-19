require "html"

module Markd::Lexer
  class Inline
    include Lexer
    include Utils

    property refmap

    @delimiters : Delimiter?

    def initialize(@options : Options)
      @text = ""
      @pos = 0
      @refmap = {} of String => Hash(String, String) | String
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
      char = char_code(@text, @pos)
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
         char(last_child.text, -1) == ' '

        hard_break = if last_child.text.size == 1
                      false # Must be space
                    else
                      char(last_child.text, -2) == ' '
                    end
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
      child = if char_code(@text, @pos) == Rule::CHAR_CODE_NEWLINE
                @pos += 1
                Node.new(Node::Type::LineBreak)
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
          child.text = @text[after_open_ticks..(@pos - ticks.size - 1)].strip.gsub(Rule::WHITESPACE, " ")
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
      if char_code(@text, @pos) == Rule::CHAR_CODE_OPEN_BRACKET
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
      title = ""
      dest = ""
      matched = false
      @pos += 1
      start_pos = @pos

      # get last [ or ![
      opener = @brackets
      unless opener
        # no matched opener, just return a literal
        node.append_child(text("]"))
        return true
      end

      unless opener.active
        # no matched opener, just return a literal
        node.append_child(text("]"))
        # take opener off brackets stack
        remove_bracket
        return true
      end

      # If we got here, open is a potential opener
      is_image = opener.image

      # Check to see if we have a link/image
      save_pos = @pos

      # Inline link?
      if char_code(@text, @pos) == Rule::CHAR_CODE_OPEN_PAREN
        @pos += 1
        if spnl && (dest = link_destination) &&
           spnl && (char(@text, @pos - 1).to_s.match(Rule::WHITESPACE_CHAR) &&
           (title = link_title) || true) && spnl &&
           char_code(@text, @pos) == Rule::CHAR_CODE_CLOSE_PAREN
          @pos += 1
          matched = true
        else
          @pos = save_pos
        end
      end

      ref_label = nil
      unless matched
        # Next, see if there's a link label
        before_label = @pos
        label_size = link_label
        if label_size > 2
          ref_label = normalize_refrenence(slice(@text, before_label, before_label + label_size))
        elsif !opener.bracket_after
          # Empty or missing second label means to use the first label as the reference.
          # The reference must not contain a bracket. If we know there's a bracket, we don't even bother checking it.
          ref_label = normalize_refrenence(slice(@text, opener.index, start_pos - 1))
        end

        if label_size == 0
          # If shortcut reference link, rewind before spaces we skipped.
          @pos = save_pos
        end

        if ref_label && @refmap[ref_label]?
          # lookup rawlabel in refmap
          link = @refmap[ref_label].as(Hash)
          dest = link["destination"] if link["destination"]
          title = link["title"] if link["title"]
          matched = true
        end
      end

      if matched
        child = Node.new(is_image ? Node::Type::Image : Node::Type::Link)
        child.data["destination"] = dest
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
        Rule::CHAR_CODE_UNDERSCORE   => delimiter,
        Rule::CHAR_CODE_ASTERISK     => delimiter,
        Rule::CHAR_CODE_SINGLE_QUOTE => delimiter,
        Rule::CHAR_CODE_DOUBLE_QUOTE => delimiter,
      } of Int32 => Delimiter?

      # find first closer above stack_bottom:
      closer = @delimiters
      while closer && closer.previous != delimiter
        closer = closer.previous
      end

      # move forward, looking for closers, and handling each
      while closer
        closer_codepoint = closer.codepoint

        unless closer.can_close
          closer = closer.next
          next
        end

        # found emphasis closer. now look back for first matching opener:
        opener = closer.previous
        opener_found = false
        while opener && opener != delimiter && opener != openers_bottom[closer_codepoint]
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
            opener = opener.not_nil!
            closer = closer.not_nil!
            use_delims = (closer.num_delims >= 2 && opener.num_delims >= 2) ? 2 : 1
            opener_inl = opener.node.not_nil!
            closer_inl = closer.node.not_nil!

            # remove used delimiters from stack elts and inlines
            opener.num_delims -= use_delims
            closer.num_delims -= use_delims

            opener_inl.text = slice(opener_inl.text, 0, (opener_inl.text.size - 1) - use_delims)
            closer_inl.text = slice(closer_inl.text, 0, (closer_inl.text.size - 1) - use_delims)

            # build contents for new emph element
            emph = Node.new((use_delims == 1) ? Node::Type::Emphasis : Node::Type::Strong)

            tmp = opener_inl.next
            while tmp && tmp != closer_inl
              next_node = tmp.next
              tmp.unlink
              emph.append_child(tmp)
              tmp = next_node
            end

            opener_inl.insert_after(emph)

            # remove elts between opener and closer in delimiters stack
            remove_delimiter_between(opener, closer)

            # if opener has 0 delims, remove it and the inline
            if opener.num_delims == 0
              opener_inl.unlink
              remove_delimiter(opener)
            end

            if closer.num_delims == 0
              closer_inl.unlink
              tmp_stack = closer.next
              remove_delimiter(closer)
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

      # remove all delimiters
      while @delimiters && @delimiters != delimiter
        remove_delimiter(@delimiters.not_nil!)
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
      pp "asfdsad"
      if text = match(Rule::ENTITY_HERE)
        pp text
        node.append_child(text(HTML.unescape(text, true)))
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
      dest = slice(match, 1, match.size - 2)
      destination = email ? "mailto:#{dest}" : dest

      node = Node.new(Node::Type::Link)
      node.data["title"] = ""
      node.data["destination"] = normalize_uri(destination)
      node.append_child(text(dest))
      node
    end

    def link_label
      text = match(Rule::LINK_LABEL)
      if text.nil? || text.to_s.size > 1001 || text.to_s.match(/[^\\]\\\]$/)
        0
      else
        text.to_s.size - 1
      end
    end

    def link_title
      title = match(Rule::LINK_TITLE)
      return unless title

      unescape_string(slice(title, 1, title.size - 2))
    end

    def link_destination
      dest = if text = match(Rule::LINK_DESTINATION_BRACES)
               slice(text, 1, text.size - 2)
             else
               save_pos = @pos
               open_parens = 0
               while (codepoint = char_code(@text, @pos)) != -1
                 if codepoint == Rule::CHAR_CODE_BACKSLASH
                   @pos += 1
                   @pos += 1 if char_code(@text, @pos) != -1
                 elsif codepoint == Rule::CHAR_CODE_OPEN_PAREN
                   @pos += 1
                   open_parens += 1
                 elsif codepoint == Rule::CHAR_CODE_CLOSE_PAREN
                   break if open_parens < 1

                   @pos += 1
                   open_parens -= 1
                 elsif codepoint.unsafe_chr.to_s.match(Rule::WHITESPACE_CHAR)
                   break
                 else
                   @pos += 1
                 end
               end

               slice(@text, save_pos, @pos - 1)
             end

      normalize_uri(unescape_string(dest))
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
               slice(@text, start_pos, @pos - 1)
             end

      child = text(text)
      node.append_child(child)

      @delimiters = Delimiter.new(codepoint, num_delims, num_delims, child, @delimiters, nil,
        res["can_open"].as(Bool), res["can_close"].as(Bool))

      if @delimiters.not_nil!.previous
        @delimiters.not_nil!.previous.not_nil!.next = @delimiters
      end

      true
    end

    def remove_delimiter(delimiter : Delimiter)
      delimiter.previous.not_nil!.next = delimiter.next if delimiter.previous

      unless delimiter.next
        # top of stack
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
        while char_code(@text, @pos) == codepoint
          num_delims += 1
          @pos += 1
        end
      end

      return if num_delims == 0

      codepoint_after = char_code(@text, @pos)
      char_before = start_pos == 0 ? '\n' : @text[start_pos - 1]
      char_after = codepoint_after == -1 ? '\n' : codepoint_after.unsafe_chr

      after_is_whitespace = char_after.to_s.match(Rule::UNICODE_WHITESPACE_CHAR) ? true : false
      after_is_punctuation = char_after.to_s.match(Rule::PUNCTUATION) ? true : false
      before_is_whitespace = char_before.to_s.match(Rule::UNICODE_WHITESPACE_CHAR) ? true : false
      before_is_punctuation = char_before.to_s.match(Rule::PUNCTUATION) ? true : false

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
        "can_open"   => can_open,
        "can_close"  => can_close,
      }
    end

    def reference(text : String, refmap)
      @text = text
      @pos = 0

      startpos = @pos
      match_chars = link_label

      # label
      return 0 if match_chars == 0
      raw_label = slice(@text, 0, match_chars)

      # colon
      if char_code(@text, @pos) == Rule::CHAR_CODE_COLON
        @pos += 1
      else
        @pos = startpos
        return 0
      end

      # link url
      spnl

      dest = link_destination
      if dest.size == 0
        @pos = startpos
        return 0
      end

      before_title = @pos
      spnl
      title = link_title
      unless title
        title = ""
        @pos = before_title
      end

      at_line_end = true
      unless match(Rule::SPACE_AT_END_OF_LINE)
        if title.empty?
          at_line_end = false
        else
          title = ""
          @pos = before_title
          at_line_end = match(Rule::SPACE_AT_END_OF_LINE) != nil
        end
      end

      unless at_line_end
        @pos = startpos
        return 0
      end

      normal_label = normalize_refrenence(raw_label)
      if normal_label.empty?
        @pos = startpos
        return 0
      end

      unless refmap[normal_label]?
        refmap[normal_label] = {
          "destination" => dest,
          "title"       => title,
        }
      end

      return @pos - startpos
    end

    # Parse zero or more space characters, including at most one newline
    private def spnl
      match(Rule::SPNL)
      return true
    end

    private def match(regex : Regex) : String?
      text = slice(@text, @pos)
      if match = text.match(regex)
        @pos += text.index(regex).as(Int32) + match[0].size
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
