module Markd
  class Lexer
    alias Token = Hash(String, String | Symbol)

    struct Block
      property newline, paragraph, text

      def initialize
        @newline = /^\n+/
        @paragraph = /^((?:[^\n]+\n?(?!hr|heading|lheading|blockquote|tag|def))+)\n*/
        @text = /^[^\n]+/
      end
    end

    @src : String
    @rules = Block.new
    @tokens = [] of Token

    def initialize(src)
      @src = src.gsub(/\r\n|\r/, "\n")
                .gsub(/\t/, "    ")
      # .gsub(/\u00a0/, " ")
      # .gsub(/\u2424/, "\n")
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
          src = src.[match[0].size..-1]
          if match[0].size > 1
            @tokens.push({
              "type" => :space,
            })
          end
        end

        # top-level paragraph
        if top && (match = src.match(@rules.paragraph))
          src = src[match[0].size..-1]

          @tokens.push({
            "type" => :paragraph,
            "text" => match[1].chomp
          })

          next
        end

        # text
        if match = src.match(@rules.text)
          # Top-level should never reach here.
          src = src[match[0].size..-1]
          @tokens.push({
            "type" => :text,
            "text" => match[0],
          })
          next
        end
      end

      @tokens
    end
  end
end
