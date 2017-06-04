require "html"

module Markd
  module Lexer
    alias Token = Hash(String, Symbol | String | Int32)

    property next : Lexer | Nil

    abstract def call(lexer : Lexer)

    def call_next(lexer : Lexer)
      if next_handler = @next
        next_handler.call(lexer)
      end
    end
  end

  # class Lexer
  #   alias Token = Hash(String, Symbol | String | Int32)

  #   @src : String
  #   @rules = Block.new
  #   @tokens = [] of Token

  #   def initialize(src)
  #     @src = src.gsub(/\r\n|\r/, "\n")
  #               .gsub(/\t/, "    ")
  #               .gsub(/\x{00a0}/, " ")
  #               .gsub(/\x{2424}/, "\n")
  #   end

  #   def lex
  #     token(@src, top: true)
  #   end

  #   def token(src, top = false, bq = false)
  #     src = src.gsub(/^ +$/m, "")

  #     while src
  #       break if src.empty?

  #       # newline
  #       if match = @rules.newline.match(src)
  #         src = delete_match_text(src, match)
  #         if match[0].size > 1
  #           @tokens.push({
  #             "type" => :space,
  #           })
  #         end
  #       end

  #       # indented code
  #       if match = @rules.code.match(src)
  #         src = delete_match_text(src, match)
  #         text = match[0].gsub(/^ {4}/m, "")
  #         @tokens.push({
  #           "type" => :code,
  #           "text" => text_escape(text.strip),
  #         })
  #         next
  #       end

  #       # fences code
  #       if match = @rules.fences.match(src)
  #         src = delete_match_text(src, match)
  #         token = {
  #           "type" => :code,
  #           "text" => text_escape(match[3]),
  #         }
  #         token["lang"] = match[2].downcase if match[2]?
  #         @tokens.push(token)
  #         next
  #       end

  #       # ATX heading
  #       if match = @rules.heading.match(src)
  #         src = delete_match_text(src, match)
  #         @tokens.push({
  #           "type"  => :heading,
  #           "level" => match[1].size,
  #           "text"  => match[2],
  #         })
  #         next
  #       end

  #       # setext heading
  #       if match = @rules.lheading.match(src)
  #         src = delete_match_text(src, match)
  #         @tokens.push({
  #           "type"  => :heading,
  #           "level" => match[2] == "=" ? 1 : 2,
  #           "text"  => match[1].strip,
  #         })
  #         next
  #       end

  #       # thematic break(hr)
  #       if match = @rules.hr.match(src)
  #         src = delete_match_text(src, match)
  #         @tokens.push({
  #           "type" => :hr,
  #         })
  #         next
  #       end

  #       # blockquote
  #       if match = @rules.blockquote.match(src)
  #         src = delete_match_text(src, match)

  #         @tokens.push({
  #           "type" => :blockquote_start,
  #         })

  #         text = match[0].gsub(/^ *> ?/m, "")
  #         token(text, top, bq: true)

  #         @tokens.push({
  #           "type" => :blockquote_end,
  #         })

  #         next
  #       end

  #       # top-level paragraph
  #       if top && (match = src.match(@rules.paragraph))
  #         src = delete_match_text(src, match)
  #         @tokens.push({
  #           "type" => :paragraph,
  #           "text" => match[1].strip,
  #         })
  #         next
  #       end

  #       # text
  #       if match = src.match(@rules.text)
  #         # Top-level should never reach here.
  #         src = delete_match_text(src, match)
  #         @tokens.push({
  #           "type" => :text,
  #           "text" => match[0],
  #         })
  #         next
  #       end
  #     end

  #     @tokens
  #   end

  #   protected def text_escape(src)
  #     src.gsub("&", "&amp;")
  #        .gsub("<", "&lt;")
  #        .gsub(">", "&gt;")
  #        .gsub("\"", "&quot;")
  #   end

  #   protected def delete_match_text(src, match, index = 0)
  #     src[match[index].size..-1]
  #   end
  # end
end
