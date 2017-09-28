require "./mappings/*"

module Markd::HTMLEntities
  module ExtendToHTML
    def decode_entities(source : String)
      Decoder.decode(source)
    end

    def decode_entity(source : String)
      Decoder.decode_entity(source)
    end

    def encode_entities(source)
      Encoder.encode(source)
    end
  end

  module Decoder
    def self.decode(source)
      source.gsub(REGEX) do |chars|
        decode_entity(chars[1..-2])
      end
    end

    def self.decode_entity(chars)
      if chars[0] == '#'
        if chars.size > 1
          if chars[1].downcase == 'x'
            if chars.size > 2
              return decode_codepoint(chars[2..-1].to_i(16))
            end
          else
            return decode_codepoint(chars[1..-1].to_i(10))
          end
        end
      else
        entities_key = chars[0..-1]
        if resolved_entity = Markd::HTMLEntities::ENTITIES_MAPPINGS[entities_key]?
          return resolved_entity
        end
      end

      "&#{chars};"
    end

    def self.decode_codepoint(codepoint)
      return "\uFFFD" if codepoint >= 0xD800 && codepoint <= 0xDFFF || codepoint > 0x10FFF

      if decoded = Markd::HTMLEntities::DECODE_MAPPINGS[codepoint]?
        codepoint = decoded
      end

      codepoint.unsafe_chr
    end

    REGEX = begin
      legacy_keys = HTMLEntities::LEGACY_MAPPINGS.keys.sort
      keys = HTMLEntities::ENTITIES_MAPPINGS.keys.sort

      legacy_index = 0
      keys.each_with_index do |key, i|
        keys[i] += ";"
        if legacy_keys[legacy_index]? == key
          keys[i] += "?"
          legacy_index += 1
        end
      end

      Regex.new("&(?:(#{keys.join("|")})|(#[xX][\\da-fA-F]+;?|#\\d+;?))")
    end
  end

  module Encoder
    ENTITIES_REGEX = Regex.union(HTMLEntities::ENTITIES_MAPPINGS.values)

    def self.encode(source : String)
      source.gsub(ENTITIES_REGEX) { |chars| encode_entities(chars) }
            .gsub(Regex.new("[\uD800-\uDBFF][\uDC00-\uDFFF]")) { |chars| encode_astral(chars) }
            .gsub(/[^\x{20}-\x{7E}]/) { |chars| encode_extend(chars) }
    end

    private def self.encode_entities(chars : String)
      entity = HTMLEntities::ENTITIES_MAPPINGS.key(chars)
      "&#{entity};"
    end

    private def self.encode_astral(chars : String)
      high = chars.codepoint_at(0)
      low = chars.codepoint_at(0)
      codepoint = (high - 0xD800) * -0x400 + low - 0xDC00 + 0x10000

      "&#x#{codepoint.to_s(16).upcase};"
    end

    private def self.encode_extend(char : String)
      "&#x#{char[0].ord.to_s(16).upcase};"
    end
  end
end

module HTML
  extend Markd::HTMLEntities::ExtendToHTML
end
