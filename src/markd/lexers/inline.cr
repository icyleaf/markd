module Markd
  class InlineLexer
    include Lexer

    struct Block
      property strong, text

      STRONG = /^__([\s\S]+?)__(?!_)|^\*\*([\s\S]+?)\*\*(?!\*)/
      TEXT      = /^[^\n]+/

      def initialize
        @strong = STRONG
        @text = TEXT
      end
    end

    @rules = Block.new
    @document = Document.new
    @tokens = Document.new

    def initialize(@src = "")
    end

    def call(context : Context)
      @document = context.document

      @document.each_with_index do |token, i|
        @tokens = Document.new

        case token["type"]
        when "paragraph"
          paragraph(token, i)
        end
      end

      context.document = @document
      call_next(context)
    end

    def paragraph(token : Token, index : Int32)
      @document[index] = {
        "type" => "paragaph_start",
      }

      token(token["text"], top: true).each_with_index do | new_token, shift|
        @document.insert(index + shift + 1, new_token)
      end

      @document.insert(index + @tokens.size + 1, {
        "type" => "paragaph_end",
      })
    end

    def lex(token : Token, index : Int32)
      token(token.text, top: true)
    end

    def token(src, top = false)
      src = src.to_s.gsub(/^ +$/m, "")

      while src
        break if src.empty?

        # strong
        if match = @rules.strong.match(src)

          src = delete_match(src, match)
          @tokens.push({
            "type" => "strong",
            "source" => match[0],
            "text" => match[2],
          })
          next
        end

        # text
        if match = @rules.text.match(src)
          # Top-level should never reach here.
          src = delete_match(src, match)
          @tokens.push({
            "type" => "text",
            "source" => match[0],
            "text" => match[0],
          })
          next
        end

        break
      end

      @tokens
    end
  end
end
