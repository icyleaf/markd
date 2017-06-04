require "html"

module Markd
  class Lexer
    alias Token = Hash(String, Symbol|String|Int32)

    module Rule
      # BULLET = /(?:[*+-]|\d+\.)/

      # LIST_HR = /\\n+(?=\\1?(?:[-*_] *){3,}(?:\\n+|$))/
      # LIST_DEF = /\\n+(?=#{BULLET})/

      NEWLINE = /^\n+/
      CODE = /^( {4}[^\n]+\n*)+/
      FENCES = /^ *(`{3,}|~{3,})[ \.]*(\S+)? *\n([\s\S]*?)\s*\1 *(?:\n+|$)/
      HEADING = /^ *(\#{1,6}) +([^\n]+?) *#* *(?:\n+|$)/

      # HR = /^( *[-*_]){3,} *(?:\n+|$)/
      # LHEADING = /^([^\n]+)\n *(=|-){2,} *(?:\n+|$)/
      # INLINE_LINK = /^ *\[([^\]]+)\]: *<?([^\s>]+)>?(?: +["(]([^\n]+)[")])? *(?:\n+|$)/
      # BLOCKQUOTE = /^( *>[^\n]+(\n(?!#{INLINE_LINK})[^\n]+)*\n*)+/
      # LIST = /^( *)(#{BULLET}) [\s\S]+?(?:#{LIST_HR}|#{LIST_DEF}|\n{2,}(?! )(?!\1#{BULLET} )\n*|\s*$)/
      # ITEM = /^( *)(#{BULLET}) [^\n]*(?:\n(?!\1#{BULLET} )[^\n]*)*/m
      # HTML = /^ *(?:comment *(?:\n|\s*$)|closed *(?:\n{2,}|\s*$)|closing *(?:\n{2,}|\s*$))/

      PARAGRAPH = /^((?:[^\n]+\n?(?!hr|heading|lheading|blockquote|tag|def))+)\n*/
      TEXT = /^[^\n]+/
    end

    struct Block
      property newline, code, fences, heading, paragraph, text

      def initialize
        @newline = Rule::NEWLINE
        @code = Rule::CODE
        @fences = Rule::FENCES
        @heading = Rule::HEADING
        # @hr = Rule::HR
        # @lheading = Rule::LHEADING
        # @blockquote = Rule::BLOCKQUOTE
        # @list = Rule::LIST
        # @html = Rule::HTML
        # @inline_link = Rule::INLINE_LINK
        @paragraph = Rule::PARAGRAPH
        @text = Rule::TEXT
      end
    end

    @src : String
    @rules = Block.new
    @tokens = [] of Token

    def initialize(src)
      @src = src.gsub(/\r\n|\r/, "\n")
                .gsub(/\t/, "    ")
      .gsub(/\x{00a0}/, " ")
      .gsub(/\x{2424}/, "\n")
    end

    def lex
      token(@src, top: true)
    end

    def token(src, top = false, bq = false)
      src = src.gsub(/^ +$/m, "")

      while src
        break if src.empty?

        # newline
        if match = src.match(@rules.newline)
          src = substring(src, match[0])
          if match[0].size > 1
            @tokens.push({
              "type" => :space,
            })
          end
        end

        # code
        if match = src.match(@rules.code)
          src = substring(src, match[0])
          text = match[0].gsub(/^ {4}/m, "")
          @tokens.push({
            "type" => :code,
            "text" => text.sub(/\n+$/, "")
          })
          next
        end

        # fences
        if match = src.match(@rules.fences)
          src = substring(src, match[0])
          token = {
            "type" => :code,
            "text" => text_escape(match[3])
          }
          token["lang"] = match[2].downcase if match[2]?
          @tokens.push(token)
          next
        end

        # heading
        if match = @rules.heading.match(src)
          src = substring(src, match[0])
          @tokens.push({
            "type" => :heading,
            "level" => match[1].size,
            "text" => match[2]
          })
          next
        end

        # top-level paragraph
        if top && (match = src.match(@rules.paragraph))
          src = substring(src, match[0])
          @tokens.push({
            "type" => :paragraph,
            "text" => match[1].chomp
          })
          next
        end

        # text
        if match = src.match(@rules.text)
          # Top-level should never reach here.
          src = substring(src, match[0])
          @tokens.push({
            "type" => :text,
            "text" => match[0],
          })
          next
        end
      end

      @tokens
    end

    private def text_escape(src)
      src.gsub("&", "&amp;")
         .gsub("<", "&lt;")
         .gsub(">", "&gt;")
         .gsub("\"", "&quot;")
    end

    private def substring(src, match)
      src[match.size..-1]
    end
  end
end
