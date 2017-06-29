module Markd::Lexer
  class Inline
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
    @document = Node.new(Node::Type::Document)
    @tokens = @document

    def initialize(@src = "")
    end

    def call(context : Context)
      # @document = context.document

      # @document.each_with_index do |token, i|
      #   @tokens = Document.new

      #   case token.type
      #   when Node::Type::Paragraph
      #     paragraph(token, i)
      #   end
      # end

      # context.document = @document
      # call_next(context)
    end

    def paragraph(token : Node, index : Int32)
      @document[index] = Node.new(Node::Type::ParagraphStart)

      token(token.text, top: true).each_with_index do | new_token, shift |
        @document.insert(index + shift + 1, new_token)
      end

      @document.insert(index + @tokens.size + 1, Node.new(Node::Type::ParagraphEnd))
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
          @tokens.push(Node.new(Node::Type::Strong, text: match[2], source: match[0]))
          next
        end

        # text
        if match = @rules.text.match(src)
          # Top-level should never reach here.
          src = delete_match(src, match)
          @tokens.push(Node.new(Node::Type::Text, source: match[0]))
          next
        end

        break
      end

      @tokens
    end
  end
end
