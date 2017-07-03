require "html"

module Markd::Lexer
  class Inline
    include Lexer

    property refmap

    @text = ""
    @pos = 0
    @refmap = {} of String => String

    def parse(document : Node)
      @text = document.text.strip
      # puts @text.bytes
      # puts @text.bytes.size
      loop do
        # puts @pos
        # puts peek
        break unless process_line(document)
      end

      document
    end

    def process_line(node : Node)
      char = peek
      return false if char == -1

      case char
      when Rule::CHAR_CODE_NEWLINE
        res = newline(node)
      when Rule::CHAR_CODE_BACKSLASH
        res = backslash(node)
      when Rule::CHAR_CODE_BACKTICK
        res = backtick(node)
      when Rule::CHAR_CODE_ASTERISK, Rule::CHAR_CODE_UNDERSCORE
        res = handle_delim(char, node)
      # when Rule::CHAR_CODE_SINGLE_QUOTE, Rule::CHAR_CODE_DOUBLE_QUOTE
      #   res = handle_delim(char, node)
      when Rule::CHAR_CODE_OPEN_BRACKET
        res = open_bracket(node)
      when Rule::CHAR_CODE_BANG
        res = bang(node)
      when Rule::CHAR_CODE_CLOSE_BRACKET
        res = close_bracket(node)
      when Rule::CHAR_CODE_LESSTHAN
        res = auto_link(node) || html_tag(node)
      when Rule::CHAR_CODE_AMPERSAND
        res = entity(node)
      else
        res = string(node)
      end

      unless res
        @pos += 1
        node.append_child(text(char.to_s))
      end

      true
    end

    def newline(container : Node)
      @pos += 1
      last_child = container.last_child
      if last_child && last_child.type == Node::Type::Text &&
         last_child.literal[last_child.literal.size - 1] == " "

        hard_break = last_child.literal[last_child.literal.size - 2]
        last_child.literal = last_child.literal.gsub(Rule::FINAL_SPACE, "")
        node = Node.new(hard_break ? Node::Type::LineBreak : Node::Type::SoftBreak)
        container.append_child(node)
      else
        container.append_child(Node.new(Node::Type::SoftBreak))
      end

      true
    end

    def backslash(container : Node)
      @pos += 1
      if peek == Rule::CHAR_CODE_NEWLINE
        @pos += 1
        node = Node.new(Node::Type::Linebreak)
        container.append_child(node)
      elsif @text.byte_at(@pos).to_s.match(Rule::ESCAPABLE)
        container.append_child(text(@text.byte_at(@pos).to_s))
        @pos += 1
      else
        container.append_child(text("\\"))
      end

      true
    end

    def backtick(container : Node)
      ticks = match(Rule::TICKS_HERE)
      return false unless ticks

      after_open_ticks = @pos
      while text = match(Rule::TICKS)
        if text == ticks
          node = Node.new(Node::Type::Code)
          end_index = @pos - ticks.size
          container.literal = @text[after_open_ticks..end_index]
          container.append_child(node)

          return true
        end
      end

      @pos = after_open_ticks
      container.append_child(text(ticks))

      true
    end

    def add_bracket(container : Node, index : Int32, image = false)
    end

    def open_bracket(container : Node)
    end

    def close_bracket(container : Node)
    end

    def bang(container : Node)
      start_pos = @pos
      @pos += 1
      if peek == Rule::CHAR_CODE_OPEN_BRACKET
        @pos += 1
        node = text("![")
        container.append_child(node)

        add_bracket(node, start_pos + 1, true)
      else
        container.append_child(text("!"))
      end

      true
    end

    def auto_link(container : Node)
      if text = match(Rule::EMAIL_AUTO_LINK)
        node = link(text, true)
        container.append_child(node)
        return true
      elsif text = match(Rule::AUTO_LINK)
        node = link(text, false)
        container.append_child(node)
        return true
      end

      false
    end

    def html_tag(container : Node)
      if text = match(Rule::HTML_TAG)
        node = Node.new(Node::Type::HTMLInline)
        node.literal = text
        container.append_child(node)

        true
      else
        false
      end
    end

    def entity(container : Node)
      if text = match(Rule::ENTITY_HERE)
        container.append_child(text(HTML.unescape(text)))
        true
      else
        false
      end
    end

    def string(container : Node)

    end

    def handle_delim(char : Int32, container : Node)
    end

    def reference(text : String, refmap)
      @text = text
      @pos = 0

      startpos = @pos
      # match_chars = parse_link_label

      # # label
      # return 0 if match_chars == 0
      # raw_label = @text[0..match_chars]

      # # colon
      # if peek == CHAR_CODE_COLON
      #   @pos += 1
      # else
      #   @post = startpos
      #   return 0
      # end

      # # link url
      # spnl

      # dest = parse_link_description
      # if dest.size == 0
      #   @pos = startpos
      #   return 0
      # end

      # before_title = @pos
      # spnl
      # title = parse_link_title
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

      # normal_label = normalize_reference(raw_label)
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
      @pos < @text.size ? @text.byte_at(@pos).to_i : -1
    end

    private def match(regex : Regex) : String?
      text = @text[@pos..-1]
      if match = text.match(regex)
        @pos += text.index(regex).not_nil! + match[0].size
        return match[0]
      end
    end

    private def link(match : String, email = false) : Node
      dest = match[1..match.size-1]
      destination = email ? "mailto:#{dest}" : dest

      node = Node.new(Node::Type::Link)
      node.data["title"] = ""
      node.data["destination"] = destination
      node.append_child(text(dest))
      node
    end

    private def text(string : String) : Node
      node = Node.new(Node::Type::Text)
      node.text = string
      node
    end
  end
end
