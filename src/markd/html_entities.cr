require "./mappings/*"

module Markd::HTMLEntities
  MAPPINGS = {} of String => Hash(String, String)

  def self.decode(source)
    Decoder.new.decode(source)
  end

  def self.encode(source)
    Encoder.new.encode(source)
  end

  module ExtendToHTML
    def unescape(source : String, entities : Bool)
      entities ? Decoder.new.decode(source) : unescape(source)
    end

    def escape(source, entities : Bool)
      entities ? Encoder.new.encode(source) : escape(source)
    end
  end

  class Decoder
    @map : Hash(String, String)

    def initialize
      @map = Markd::HTMLEntities::MAPPINGS["entities"]
    end

    def decode(source)
      source.gsub(regex) do |chars|
        if chars[1] == '#'
          if chars[2].downcase == 'x'
            decode_codepoint(chars[3..-2].to_i(16))
          else
            decode_codepoint(chars[2..-2].to_i(10))
          end
        else
          entities_key = chars[1..-2]
          if @map[entities_key]?
            @map[entities_key]
          else
            chars
          end
        end
      end
    end

    def decode_codepoint(codepoint)
      return "\uFFFD" if codepoint >= 0xD800 && codepoint <= 0xDFFF || codepoint > 0x10FFF

      decode_map = Markd::HTMLEntities::MAPPINGS["decode"]
      if decode_map.keys.includes?(codepoint.to_s)
        codepoint = decode_map[codepoint.to_s].to_i
      end

      codepoint.unsafe_chr
    end

    private def regex
      legacy = HTMLEntities::MAPPINGS["legacy"].keys.sort
      keys = HTMLEntities::MAPPINGS["entities"].keys.sort

      legacy_index = 0
      keys.each_with_index do |k, i|
        if legacy[legacy_index]? && legacy[legacy_index] == k
          keys[i] += ";?"
          legacy_index += 1
        else
          keys[i] += ";"
        end
      end

      Regex.new("&(?:(" + keys.join("|") + ")|(#[xX][\\da-fA-F]+;?|#\\d+;?))")
    end
  end

  class Encoder
    @data = {} of String => String
    @regex = /^/

    def encode(source : String)
      source.gsub(entities_regex) { |chars| encode_entities(chars) }
            .gsub(Regex.new("[\uD800-\uDBFF][\uDC00-\uDFFF]")) { |chars| encode_astral(chars) }
            .gsub(/[^\x{20}-\x{7E}]/) { |chars| encode_extend(chars) }
    end

    private def encode_entities(chars : String)
      data[chars]
    end

    private def encode_astral(chars : String)
      high = chars.codepoint_at(0)
      low = chars.codepoint_at(0)
      codepoint = (high - 0xD800) * -0x400 + low - 0xDC00 + 0x10000

      "&#x" + codepoint.to_s(16).upcase + ";"
    end

    private def encode_extend(char : String)
      "&#x" + char[0].ord.to_s(16).upcase + ";"
    end

    private def data
      return @data unless @data.empty?

      entites = HTMLEntities::MAPPINGS["entities"]
      entites.keys.sort.each do |key|
        key = key.as(String)
        value = "&" + key + ";"
        @data[entites[key]] = value
      end

      @data
    end

    private def entities_regex
      return @regex if @regex.source != "^"

      single = [] of String
      multiple = [] of String

      HTMLEntities::MAPPINGS["entities"].each do |_, key|
        if key.size == 1
          single << "\\" + key
        else
          multiple << key
        end
      end

      multiple << "[" + single.join("") + "]"
      @regex = Regex.new(multiple.join("|"))
    end
  end
end

module HTML
  extend Markd::HTMLEntities::ExtendToHTML
end
