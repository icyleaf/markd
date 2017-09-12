require "./mappings/*"

module Markd::HTMLEntities
  module ExtendToHTML
    def decode_entities(source : String)
      Decoder.new.decode(source)
    end

    def encode_entitites(source)
      Encoder.new.encode(source)
    end
  end

  class Decoder
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
          if resolved_entity = Markd::HTMLEntities::ENTITIES_MAPPINGS[entities_key]?
            resolved_entity
          else
            chars
          end
        end
      end
    end

    def decode_codepoint(codepoint)
      return "\uFFFD" if codepoint >= 0xD800 && codepoint <= 0xDFFF || codepoint > 0x10FFF

      if decoded = Markd::HTMLEntities::DECODE_MAPPINGS[codepoint]?
        codepoint = decoded
      end

      codepoint.unsafe_chr
    end

    private def regex
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

      Regex.new("&(?:(#{ keys.join("|") })|(#[xX][\\da-fA-F]+;?|#\\d+;?))")
    end
  end

  class Encoder
    @regex = /^/

    def encode(source : String)
      source.gsub(entities_regex) { |chars| encode_entities(chars) }
            .gsub(Regex.new("[\uD800-\uDBFF][\uDC00-\uDFFF]")) { |chars| encode_astral(chars) }
            .gsub(/[^\x{20}-\x{7E}]/) { |chars| encode_extend(chars) }
    end

    private def encode_entities(chars : String)
      entity = HTMLEntities::ENTITIES_MAPPINGS[chars]
      "&#{entity};"
    end

    private def encode_astral(chars : String)
      high = chars.codepoint_at(0)
      low = chars.codepoint_at(0)
      codepoint = (high - 0xD800) * -0x400 + low - 0xDC00 + 0x10000

      "&#x#{codepoint.to_s(16).upcase};"
    end

    private def encode_extend(char : String)
      "&#x#{char[0].ord.to_s(16).upcase};"
    end

    private def entities_regex
      return @regex if @regex.source != "^"

      single = [] of String
      multiple = [] of String

      HTMLEntities::ENTITIES_MAPPINGS.each do |_, key|
        if key.size == 1
          single << "\\" + key
        else
          multiple << key
        end
      end

      multiple << "[#{single.join("")}]"
      @regex = Regex.new(multiple.join("|"))
    end
  end
end

module HTML
  extend Markd::HTMLEntities::ExtendToHTML
end
