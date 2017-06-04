require "html"

module Markd
  class InlineLexer
    include Lexer

    module Rule
      # BULLET = /(?:[*+-]|\d+\.)/

      # LIST_HR = /\\n+(?=\\1?(?:[-*_] *){3,}(?:\\n+|$))/
      # LIST_DEF = /\\n+(?=#{BULLET})/

      NEWLINE  = /^\n+/
      CODE     = /^( {4}[^\n]+\n*)+/
      FENCES   = /^ *(`{3,}|~{3,})[ \.]*(\S+)? *\n([\s\S]*?)\s*\1 *(?:\n+|$)/
      HEADING  = /^ *(\#{1,6}) +([^\n]+?) *#* *(?:\n+|$)/
      LHEADING = /^([^\n]+)\n *(=|-){2,} *(?:\n+|$)/
      HR       = /^( *[-*_]){3,} *(?:\n+|$)/

      INLINE_LINK = /^ *\[([^\]]+)\]: *<?([^\s>]+)>?(?: +["(]([^\n]+)[")])? *(?:\n+|$)/
      BLOCKQUOTE  = /^( *>[^\n]+(\n(?!#{INLINE_LINK})[^\n]+)*\n*)+/
      # LIST = /^( *)(#{BULLET}) [\s\S]+?(?:#{LIST_HR}|#{LIST_DEF}|\n{2,}(?! )(?!\1#{BULLET} )\n*|\s*$)/
      # ITEM = /^( *)(#{BULLET}) [^\n]*(?:\n(?!\1#{BULLET} )[^\n]*)*/m
      # HTML = /^ *(?:comment *(?:\n|\s*$)|closed *(?:\n{2,}|\s*$)|closing *(?:\n{2,}|\s*$))/

      PARAGRAPH = /^((?:[^\n]+\n?(?!hr|heading|lheading|blockquote|tag|def))+)\n*/
      TEXT      = /^[^\n]+/
    end

    struct Block
      property newline, code, fences, heading, lheading, hr, blockquote, paragraph, text

      def initialize
        @newline = Rule::NEWLINE
        @code = Rule::CODE
        @fences = Rule::FENCES
        @heading = Rule::HEADING
        @lheading = Rule::LHEADING
        @hr = Rule::HR
        @blockquote = Rule::BLOCKQUOTE
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

    def initialize
      @src = ""
    end

    def lex
      token(@src, top: true)
    end

    def token(src, top = false, bq = false)
      src = src.gsub(/^ +$/m, "")

      while src
        break if src.empty?

        # newline
        if match = @rules.newline.match(src)
          src = substring(src, match[0])
          if match[0].size > 1
            @tokens.push({
              "type" => "space",
            })
          end
        end

        # indented code
        if match = @rules.code.match(src)
          src = substring(src, match[0])
          text = match[0].gsub(/^ {4}/m, "")
          @tokens.push({
            "type" => "code",
            "text" => text_escape(text.strip),
          })
          next
        end

        # fences code
        if match = @rules.fences.match(src)
          src = substring(src, match[0])
          token = {
            "type" => "code",
            "text" => text_escape(match[3]),
          }
          token["lang"] = match[2].downcase if match[2]?
          @tokens.push(token)
          next
        end

        # ATX heading
        if match = @rules.heading.match(src)
          src = substring(src, match[0])
          @tokens.push({
            "type"  => "heading",
            "level" => match[1].size,
            "text"  => match[2],
          })
          next
        end

        # setext heading
        if match = @rules.lheading.match(src)
          src = substring(src, match[0])
          @tokens.push({
            "type"  => "heading",
            "level" => match[2] == "=" ? 1 : 2,
            "text"  => match[1].strip,
          })
          next
        end

        # thematic break(hr)
        if match = @rules.hr.match(src)
          src = substring(src, match[0])
          @tokens.push({
            "type" => "hr",
          })
          next
        end

        # blockquote
        if match = @rules.blockquote.match(src)
          src = substring(src, match[0])

          @tokens.push({
            "type" => "blockquote_start",
          })

          text = match[0].gsub(/^ *> ?/m, "")
          token(text, top, bq: true)

          @tokens.push({
            "type" => "blockquote_end",
          })

          next
        end

        # top-level paragraph
        if top && (match = src.match(@rules.paragraph))
          src = substring(src, match[0])
          @tokens.push({
            "type" => "paragraph",
            "text" => match[1].strip,
          })
          next
        end

        # text
        if match = src.match(@rules.text)
          # Top-level should never reach here.
          src = substring(src, match[0])
          @tokens.push({
            "type" => "text",
            "text" => match[0],
          })
          next
        end
      end

      @tokens
    end
  end
end
