module Markd
  module Lexer

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

require "./lexers/*"
