module Markd
  module Rule
    ENTITY_STRING = "&(?:#x[a-f0-9]{1,8}|#[0-9]{1,8}|[a-z][a-z0-9]{1,31});"
    ESCAPABLE_STRING = "[!\"#$%&\'()*+,./:;<=>?@[\\\\\\]^_`{|}~-]"

    TAG_NAME_STRING = "[A-Za-z][A-Za-z0-9-]*"
    ATTRIBUTE_NAME_STRING = "[a-zA-Z_:][a-zA-Z0-9:._-]*"
    UNQUOTED_VALUE_STRING = "[^\"'=<>`\\x00-\\x20]+"
    SINGLE_QUOTED_VALUE_STRING = "'[^']*'"
    DOUBLE_QUOTED_VALUE_STRING = "\"[^\"]*\""
    ATTRIBUTE_VALUE_STRING = "(?:" + UNQUOTED_VALUE_STRING + "|" + SINGLE_QUOTED_VALUE_STRING + "|" + DOUBLE_QUOTED_VALUE_STRING + ")"
    ATTRIBUTE_VALUE_SPEC_STRING = "(?:" + "\\s*=" + "\\s*" + ATTRIBUTE_VALUE_STRING + ")"
    ATTRIBUTE = "(?:" + "\\s+" + ATTRIBUTE_NAME_STRING + ATTRIBUTE_VALUE_SPEC_STRING + "?)"

    FINAL_SPACE = / *$/
    INITIAL_SPACE = /^ */

    BACKSLASH_OR_AMP = /[\\&]/
    NONSPACE = /[^ \t\f\v\r\n]/
    MAYBE_SPECIAL = /^[#`~*+_=<>0-9-]/
    THEMATIC_BREAK = /^(?:(?:\*[ \t]*){3,}|(?:_[ \t]*){3,}|(?:-[ \t]*){3,})[ \t]*$/

    ESCAPABLE = /^#{ESCAPABLE_STRING}/
    ENTITY_OR_ESCAPED_CHAR = /\\\\#{ESCAPABLE_STRING}|#{ENTITY_STRING}/i
    ENTITY_HERE = /^#{ENTITY_STRING}/i

    TICKS = /`+/
    TICKS_HERE = /^`+/

    OPEN_TAG = "<" + TAG_NAME_STRING + ATTRIBUTE + "*" + "\\s*/?>"
    CLOSE_TAG = "</" + TAG_NAME_STRING + "\\s*[>]"

    OPEN_TAG_STRING = "<#{TAG_NAME_STRING}#{ATTRIBUTE}*" + "\\s*/?>";
    CLOSE_TAG_STRING = "</#{TAG_NAME_STRING}\\s*[>]"
    COMMENT_STRING = "<!---->|<!--(?:-?[^>-])(?:-?[^-])*-->"
    PROCESSING_INSTRUCTION_STRING = "[<][?].*?[?][>]"
    DECLARATION_STRING = "<![A-Z]+" + "\\s+[^>]*>"
    CDATA_STRING = "<!\\[CDATA\\[[\\s\\S]*?\\]\\]>"
    HTML_TAG_STRING = "(?:#{OPEN_TAG_STRING}|#{CLOSE_TAG_STRING}|#{COMMENT_STRING}|#{PROCESSING_INSTRUCTION_STRING}|#{DECLARATION_STRING}|#{CDATA_STRING})"
    HTML_TAG = /^#{HTML_TAG_STRING}/i

    HTML_BLOCK_OPEN = [
      /^<(?:script|pre|style)(?:\s|>|$)/i,
      /^<!--/,
      /^<[?]/,
      /^<![A-Z]/,
      /^<!\[CDATA\[/,
      /^<[\/]?(?:address|article|aside|base|basefont|blockquote|body|caption|center|col|colgroup|dd|details|dialog|dir|div|dl|dt|fieldset|figcaption|figure|footer|form|frame|frameset|h[123456]|head|header|hr|html|iframe|legend|li|link|main|menu|menuitem|meta|nav|noframes|ol|optgroup|option|p|param|section|source|title|summary|table|tbody|td|tfoot|th|thead|title|tr|track|ul)(?:\s|[\/]?[>]|$)/i,
      /^(?:#{OPEN_TAG}|#{CLOSE_TAG})\\s*$/i
    ]

    HTML_BLOCK_CLOSE = [
      /<\/(?:script|pre|style)>/i,
      /-->/,
      /\?>/,
      />/,
      /\]\]>/
    ]

    EMAIL_AUTO_LINK = /^<([a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*)>/
    AUTO_LINK = /^<[A-Za-z][A-Za-z0-9.+-]{1,31}:[^<>\x00-\x20]*>/i

    CODE_INDENT = 4

    CHAR_CODE_TAB = 9
    CHAR_CODE_NEWLINE = 10
    CHAR_CODE_SPACE = 32
    CHAR_CODE_BANG = 33
    CHAR_CODE_AMPERSAND = 38
    CHAR_CODE_OPEN_PAREN = 40
    CHAR_CODE_CLOSE_PAREN = 41
    CHAR_CODE_ASTERISK = 42
    CHAR_CODE_COLON = 58
    CHAR_CODE_LESSTHAN = 60
    CHAR_CODE_GREATERTHAN = 62
    CHAR_CODE_OPEN_BRACKET = 91
    CHAR_CODE_CLOSE_BRACKET = 93
    CHAR_CODE_BACKSLASH = 92
    CHAR_CODE_UNDERSCORE = 95
    CHAR_CODE_BACKTICK = 96
    CHAR_CODE_SINGLE_QUOTE = 39
    CHAR_CODE_DOUBLE_QUOTE = 34

    # Match Value
    #
    # - None: no match
    # - Container: match container, keep going
    # - Leaf: match leaf, no more block starts
    enum MatchValue
      None
      Container
      Leaf
    end

    # match and parse
    abstract def match(parser : Lexer, container : Node) : MatchValue

    # token finalize
    abstract def token(parser : Lexer, container : Node) : Void

    # continue
    abstract def continue(parser : Lexer, container : Node) : Int32

    # accepts_line
    abstract def accepts_lines? : Bool

    def text_clean(parser : Lexer, index = parser.next_nonspace) : String
      parser.line[index..-1]
    end

    def char_code_at(parser : Lexer, index = parser.next_nonspace) : UInt8
      # return nil if parser.line.empty?
      parser.line.byte_at(index)
    end

    def blank?(code : UInt8, include_nil = false) : Bool
      # return true if include_nil && !code
      [CHAR_CODE_SPACE, CHAR_CODE_TAB].includes?(code)
    end

    def unescape_char(text : String)
      if text.byte_at(0) == CHAR_CODE_BACKSLASH
        text[1]
      else
        HTML.unescape(s)
      end
    end

    def unescape_string(text : String)
      if text =~ BACKSLASH_OR_AMP
        text.gsub(ENTITY_OR_ESCAPED_CHAR, unescape_char)
      else
        text
      end
    end
  end
end

require "./rules/*"
