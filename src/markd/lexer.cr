module Markd
  module Lexer
    alias Token = Hash(String, String | Int32)
    alias Document = Array(Token)

    property next : Lexer | Nil

    abstract def call(context : Context)

    def call_next(context : Context)
      if next_handler = @next
        next_handler.call(context)
      end
    end

    def text_clean(src)
      src.gsub(/\r\n|\r/, "\n")
         .gsub(/\t/, "    ")
         .gsub(/\x{00a0}/, " ")
         .gsub(/\x{2424}/, "\n")
    end

    def text_escape(src)
      src.gsub("&", "&amp;")
         .gsub("<", "&lt;")
         .gsub(">", "&gt;")
         .gsub("\"", "&quot;")
    end

    def delete_match(src, match, index = 0)
      src[match[index].size..-1]
    end
  end
end
