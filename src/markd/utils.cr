require "json"

module Markd
  module Utils
    def self.timer(label : String, measure_time? : Bool)
      return yield unless measure_time?

      start_time = Time.now
      yield

      puts "#{label}: #{(Time.now - start_time).total_milliseconds}ms"
    end

    # Normalize reference label: collapse internal whitespace
    # to single space, remove leading/trailing whitespace, case fold.
    def normalize_refrenence(text : String)
      text[1..-2].strip.downcase.gsub("\n", " ")
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
