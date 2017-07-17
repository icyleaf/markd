require "json"

module Markd
  module Utils
    @time_table = {} of String => Time
    @html_entities = {} of String => JSON::Type
    @escape_html = {} of String => String
    @unescape_html = {} of String => String

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

    def normalize_uri(uri : String)
      URI.escape(decode(uri)) do |byte|
        URI.unreserved?(byte) || {'&', '+', ',', '(', ')', '#', '*', '!', '#', '$', '/', ':', ';', '?', '@', '='}.includes?(byte.chr)
      end
    end

    def unescape_char(text : String) : String
      if char_code(text, 0) == Rule::CHAR_CODE_BACKSLASH
        text[1].to_s
      elsif text.match(/^&(\w+);$/)
        unescape_html[text]
      else
        HTML.unescape(text)
      end
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

    def encode(text : String)
      URI.escape(text).each_byte do |char|
        escape_html[char]
      end
    end

    def decode(text : String)
      URI.unescape(text).gsub(/^&(\w+);$/) { |chars| unescape_html[chars] }
    end

    def escape_html
      return @escape_html unless @escape_html.empty?

      entities
      @escape_html = entities.keys.sort.each_with_object({} of String => String) do |name, data|
        key = entities[name].as(String)
        value = "&" + name + ";"
        data[key] = value
      end
    end

    def unescape_html
      return @unescape_html unless @unescape_html.empty?

      entities
      @unescape_html = entities.keys.sort.each_with_object({} of String => String) do |name, data|
        value = entities[name].as(String)
        key = "&" + name + ";"
        data[key] = value
      end
    end

    private def entities
      return @html_entities unless @html_entities.empty?

      file = File.expand_path("./entities/entities.json")
      content = File.open(file, "r").gets_to_end
      @html_entities = JSON.parse(content).as_h
    end
  end
end
