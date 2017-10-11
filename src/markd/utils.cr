require "json"

module Markd
  module Utils
    def self.timer(label : String, measure_time? : Bool)
      return yield unless measure_time?

      start_time = Time.now
      yield

      puts "#{label}: #{(Time.now - start_time).total_milliseconds}ms"
    end

    def decode_entities_string(text : String) : String
      HTML.decode_entities(text).gsub(Regex.new("\\\\" + Rule::ESCAPABLE_STRING, Regex::Options::IGNORE_CASE)) { |text| text[1].to_s }
    end
  end
end
