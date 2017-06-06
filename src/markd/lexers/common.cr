module Markd
  class CommonLexer
    include Lexer

    struct Block
      property newline, code, fences, heading, lheading, hr, blockquote, list, item, html,
               paragraph, text

      HTML_COMMENT = /<!---->|<!--(?:-?[^>-])(?:-?[^-])*-->/
      HTML_TAG = /(?!(?:a|em|strong|small|s|cite|q|dfn|abbr|data|time|code|var|samp|kbd|sub|sup|i|b|u|mark|ruby|rt|rp|bdi|bdo|span|br|wbr|ins|del|img)\b)\w+(?!:\/|[^\w\s@]*@)\b/
      HTML_CLOSED_TAG = /<(#{HTML_TAG})[\s\S]+?<\/\1>/
      HTML_CLOSING_TAG = /<#{HTML_TAG}(?:"[^"]*"|'[^']*'|[^'">])*?>/

      NEWLINE  = /^\n+/
      CODE     = /^( {4}[^\n]+\n*)+/
      FENCES   = /^ *(`{3,}|~{3,})[ \.]*(\S+)? *\n([\s\S]*?)\s*\1 *(?:\n+|$)/
      HEADING  = /^ *(\#{1,6}) +([^\n]+?) *#* *(?:\n+|$)/
      LHEADING = /^([^\n]+)\n *(=|-){2,} *(?:\n+|$)/
      HR       = /^( *[-*_]){3,} *(?:\n+|$)/
      INLINE_LINK = /^ *\[([^\]]+)\]: *<?([^\s>]+)>?(?: +["(]([^\n]+)[")])? *(?:\n+|$)/
      BLOCKQUOTE  = /^( *>[^\n]+(\n(?!#{INLINE_LINK})[^\n]+)*\n*)+/
      PARAGRAPH = /^((?:[^\n]+\n?(?!#{HR}|#{HEADING}|#{LHEADING}|#{BLOCKQUOTE}|<#{HTML_TAG}|#{INLINE_LINK}))+)\n*/
      TEXT      = /^[^\n]+/

      BULLET = /(?:[*+-]|\d+\.)/
      LIST_HR = /\\n+(?=\\1?(?:[-*_] *){3,}(?:\\n+|$))/
      LIST_DEF = /\\n+(?=#{BULLET})/
      LIST = /^( *)(#{BULLET}) [\s\S]+?(?:#{LIST_HR}|#{LIST_DEF}|\n{2,}(?! )(?!\1#{BULLET} )\n*|\s*$)/
      ITEM = /^\s*(a:#{BULLET})\s*[^\n]*(?:\n(?!\1#{BULLET})\s*[^\n]*)*/m

      HTML = /^ *(?:#{HTML_COMMENT} *(?:\n|\s*$)|#{HTML_CLOSED_TAG} *(?:\n{2,}|\s*$)|#{HTML_CLOSING_TAG} *(?:\n{2,}|\s*$))/m

      def initialize
        @newline = NEWLINE
        @code = CODE
        @fences = FENCES
        @heading = HEADING
        @lheading = LHEADING
        @hr = HR
        @blockquote = BLOCKQUOTE
        @list = LIST
        @item = ITEM
        @html = HTML
        @paragraph = PARAGRAPH
        @text = TEXT
      end
    end

    @src : String
    @document = Document.new
    @rules = Block.new

    def initialize(@src = "")
    end

    def call(context : Context)
      @src = text_clean(context.source)
      token(@src, top: true)

      context.document = @document
      call_next(context)
    end

    def token(src : String, top = false, bq = false)
      src = src.gsub(/^ +$/m, "")

      while src
        break if src.empty?

        # newline
        if match = @rules.newline.match(src)
          src = newline(src, match)
        end

        # indented code
        if match = @rules.code.match(src)
          src = code(src, match)
          next
        end

        # fences code
        if match = @rules.fences.match(src)
          src = fences(src, match)
          next
        end

        # ATX heading
        if match = @rules.heading.match(src)
          src = heading(src, match)
          next
        end

        # setext heading
        if match = @rules.lheading.match(src)
          src = lheading(src, match)
          next
        end

        # thematic break(hr)
        if match = @rules.hr.match(src)
          src = hr(src, match)
          next
        end

        # blockquote
        if match = @rules.blockquote.match(src)
          src = blockquote(src, match)
          next
        end

        # list
        # if match = @rules.list.match(src)
        #   src = list(src, match)
        #   next
        # end

        # html
        if match = @rules.html.match(src)
          src = html(src, match)
          next
        end

        # top-level paragraph
        if top && (match = src.match(@rules.paragraph))
          src = paragraph(src, match)
          next
        end

        break
      end

      @document
    end

    def newline(src : String, match : Regex::MatchData)
      if match[0].size > 1
        @document.push({
          "type" => "space",
          "source" => match[0],
        })
      end

      delete_match(src, match)
    end

    def code(src : String, match : Regex::MatchData)
      text = match[0].gsub(/^ {4}/m, "")
      @document.push({
        "type" => "code",
        "source" => match[0],
        "text" => text_escape(text.strip),
      })

      delete_match(src, match)
    end

    def fences(src : String, match : Regex::MatchData)
      token = {
        "type" => "code",
        "source" => match[0],
        "text" => text_escape(match[3]),
      }
      token["lang"] = match[2].downcase if match[2]?
      @document.push(token)

      delete_match(src, match)
    end

    def heading(src : String, match : Regex::MatchData)
      @document.push({
        "type"  => "heading",
        "source" => match[0],
        "level" => match[1].size,
        "text"  => match[2],
      })

      delete_match(src, match)
    end

    def lheading(src : String, match : Regex::MatchData)
      @document.push({
        "type"  => "heading",
        "source" => match[0],
        "level" => match[2] == "=" ? 1 : 2,
        "text"  => match[1].strip,
      })

      delete_match(src, match)
    end

    def hr(src : String, match : Regex::MatchData)
      @document.push({
        "type" => "hr",
        "source" => match[0],
      })

      delete_match(src, match)
    end

    def blockquote(src : String, match : Regex::MatchData)
      @document.push({
        "type" => "blockquote_start",
      })
      text = match[0].gsub(/^ *> ?/m, "")
      token(text, true, bq: true)
      @document.push({
        "type" => "blockquote_end",
      })

      delete_match(src, match)
    end

    def list(src : String, match : Regex::MatchData)
      bullet = match[2]

      @document.push({
        "type" => "list_start",
        "ordered" => bullet.size > 1
      })

      # FIXIT: it could not match multiline items with regex
      cap = @rules.item.match(match[0])

      @document.push({
        "type" => "list_end",
      })

      delete_match(src, match)
    end

    def html(src : String, match : Regex::MatchData)
      @document.push({
        "type" => "html",
        "pre" => ["pre", "script", "style"].includes?(match[1]),
        "source" => match[0],
        "text" => text_escape(match[0]),
      })

      delete_match(src, match)
    end

    def paragraph(src : String, match : Regex::MatchData)
      @document.push({
        "type" => "paragraph",
        "source" => match[0],
        "text" => match[1].strip,
      })

      delete_match(src, match)
    end
  end
end
