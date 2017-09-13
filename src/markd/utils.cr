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
      URI.escape(text).each_byte { |char| HTML.encode_entities(chars) }
    end

    def decode_uri(text : String)
      URI.unescape(text).gsub(/^&(\w+);$/) { |chars| HTML.decode_entities(chars) }
    end

    def decode_entities_string(text : String) : String
      HTML.decode_entities(text).gsub(Regex.new("\\\\" + Rule::ESCAPABLE_STRING, Regex::Options::IGNORE_CASE)) { |text| text[1].to_s }
    end
  end
end
