module Markd
  class CommonLexer
    include Lexer

    module Rule
      HTML_TAG = /(?!(?:a|em|strong|small|s|cite|q|dfn|abbr|data|time|code|var|samp|kbd|sub|sup|i|b|u|mark|ruby|rt|rp|bdi|bdo|span|br|wbr|ins|del|img)\b)\w+(?!:\/|[^\w\s@]*@)\b/

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

      PARAGRAPH = /^((?:[^\n]+\n?(?!#{HR}|#{HEADING}|#{LHEADING}|#{BLOCKQUOTE}|<#{HTML_TAG}|#{INLINE_LINK}))+)\n*/
      TEXT      = /^[^\n]+/
    end

    struct Block
      property newline, code, fences, heading, lheading, hr, blockquote,
               paragraph, text

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
    @document = Document.new
    @rules = Block.new

    def initialize(@src = "")
    end

    def call(context : Context)
      lex(context.source)
      context.document = @document
      call_next(context)
    end

    def lex(src : String)
      @src = text_clean(src)
      token(@src, top: true)
    end

    def token(src : String, top = false, bq = false)
      src = src.gsub(/^ +$/m, "")

      while src
        break if src.empty?

        # newline
        if match = @rules.newline.match(src)
          src = delete_match(src, match)
          if match[0].size > 1
            @document.push({
              "type" => "space",
              "source" => match[0],
            })
          end
        end

        # indented code
        if match = @rules.code.match(src)
          src = delete_match(src, match)
          text = match[0].gsub(/^ {4}/m, "")
          @document.push({
            "type" => "code",
            "source" => match[0],
            "text" => text_escape(text.strip),
          })
          next
        end

        # fences code
        if match = @rules.fences.match(src)
          src = delete_match(src, match)
          token = {
            "type" => "code",
            "source" => match[0],
            "text" => text_escape(match[3]),
          }
          token["lang"] = match[2].downcase if match[2]?
          @document.push(token)
          next
        end

        # ATX heading
        if match = @rules.heading.match(src)
          src = delete_match(src, match)
          @document.push({
            "type"  => "heading",
            "source" => match[0],
            "level" => match[1].size,
            "text"  => match[2],
          })
          next
        end

        # setext heading
        if match = @rules.lheading.match(src)
          src = delete_match(src, match)
          @document.push({
            "type"  => "heading",
            "source" => match[0],
            "level" => match[2] == "=" ? 1 : 2,
            "text"  => match[1].strip,
          })
          next
        end

        # thematic break(hr)
        if match = @rules.hr.match(src)
          src = delete_match(src, match)
          @document.push({
            "type" => "hr",
            "source" => match[0],
          })
          next
        end

        # blockquote
        if match = @rules.blockquote.match(src)
          src = delete_match(src, match)

          @document.push({
            "type" => "blockquote_start",
          })

          text = match[0].gsub(/^ *> ?/m, "")
          token(text, top, bq: true)

          @document.push({
            "type" => "blockquote_end",
          })

          next
        end

        # top-level paragraph
        if top && (match = src.match(@rules.paragraph))
          src = delete_match(src, match)
          @document.push({
            "type" => "paragraph",
            "source" => match[0],
            "text" => match[1].strip,
          })
          next
        end

        # # text
        # if match = src.match(@rules.text)
        #   # Top-level should never reach here.
        #   src = delete_match(src, match)
        #   @document.push({
        #     "type" => "text",
        #     "source" => match[0],
        #     "text" => match[0],
        #   })
        #   next
        # end

        break
      end

      @document
    end
  end
end
