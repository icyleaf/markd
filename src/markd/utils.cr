module Markd
  module Utils
    @time_table = {} of String => Time

    def start_time(label : String)
      @time_table[label] = Time.now
    end

    def end_time(label : String)
      raise Exception.new("Not found time label: #{label}") unless @time_table[label]
      puts "#{label}: #{(Time.now - @time_table[label]).total_milliseconds}ms"
    end

    def slice(text : String, starts = 0, ends = -1) : String
      return "" unless starts < text.size
      starts != ends ? text[starts..ends] : text[starts].to_s
    end

    def char(text : String, index : Int32) : Char?
      return unless index < text.size
      text[index]
    end

    def char_code(text : String, index : Int32) : Int32
      if char = char(text, index)
        char.ord
      else
        -1
      end
    end

    def unescape_char(text : String)
      if char_code(text, 0) == Rule::CHAR_CODE_BACKSLASH
        text[1]
      else
        HTML.unescape(text)
      end
    end

    def unescape_string(text : String)
      if text.match(Rule::BACKSLASH_OR_AMP)
        text.sub(Rule::ENTITY_OR_ESCAPED_CHAR, unescape_char)
      else
        text
      end
    end
  end
end
