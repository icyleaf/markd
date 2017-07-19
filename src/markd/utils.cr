require "json"

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

    # Normalize reference label: collapse internal whitespace
    # to single space, remove leading/trailing whitespace, case fold.
    def normalize_refrenence(text : String)
      slice(text, 1, -2).strip.downcase.gsub("\n", " ")
    end

    def normalize_uri(uri : String)
      URI.escape(decode_uri(uri)) do |byte|
        URI.unreserved?(byte) || ['&', '+', ',', '(', ')', '#', '*', '!', '#', '$', '/', ':', ';', '?', '@', '='].includes?(byte.chr)
      end
    end

    def encode_uri(text : String)
      URI.escape(text).each_byte { |char| HTML.escape(chars, true) }
    end

    def decode_uri(text : String)
      URI.unescape(text).gsub(/^&(\w+);$/) { |chars| HTML.unescape(chars, true) }
    end

    def unescape_string(text : String) : String
      if text.match(Rule::BACKSLASH_OR_AMP)
        text.gsub(Rule::ENTITY_OR_ESCAPED_CHAR) do |chars|
          unescape_char(chars)
        end
      else
        text
      end
    end

    def unescape_char(text : String) : String
      if char_code(text, 0) == Rule::CHAR_CODE_BACKSLASH
        text[1].to_s
      else
        HTML.unescape(text, true)
      end
    end
  end
end
