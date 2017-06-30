module Markd::Lexer
  class Inline
    include Lexer

    @text = ""
    @pos = 0
    @refmap = {} of String => String

    def parse_reference(text : String, refmap)
      @text = text
      @pos = 0

      startpos = @pos
      # match_chars = parse_link_label

      # # label
      # return 0 if match_chars == 0
      # raw_label = @text[0..match_chars]

      # # colon
      # if peek == CHAR_CODE_COLON
      #   @pos += 1
      # else
      #   @post = startpos
      #   return 0
      # end

      # # link url
      # spnl

      # dest = parse_link_description
      # if dest.size == 0
      #   @pos = startpos
      #   return 0
      # end

      # before_title = @pos
      # spnl
      # title = parse_link_title
      # unless title
      #   title = ""
      #   @pos = before_title
      # end

      # at_line_end = true
      # unless match(Rule::SPACE_AT_END_OF_LINE)
      #   if title.empty?
      #     at_line_end = false
      #   else
      #     title = ""
      #     @pos = before_title
      #     at_line_end = match(Rule::SPACE_AT_END_OF_LINE) != nil
      #   end
      # end

      # unless at_line_end
      #   @pos = startpos
      #   return 0
      # end

      # normal_label = normalize_reference(raw_label)
      # unless normal_label
      #   @pos = startpos
      #   return 0
      # end

      # unless refmap[normal_label]
      #   refmap[normal_label] = {
      #     "destination" => dest,
      #     "title" => title
      #   }
      # end

      return @pos - startpos
    end
  end
end
