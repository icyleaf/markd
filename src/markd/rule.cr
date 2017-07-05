module Markd
  module Rule
    ENTITY_STRING = "&(?:#x[a-f0-9]{1,8}|#[0-9]{1,8}|[a-z][a-z0-9]{1,31});"
    ESCAPABLE_STRING = "[!\"#$%&\'()*+,./:;<=>?@[\\\\\\]^_`{|}~-]"
    ESCAPED_CHAR_STRING = "\\\\#{ESCAPABLE_STRING}"

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

    MAIN = /^[^\n`\[\]\\!<&*_'"]+/m

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

    LINK_TITLE = Regex.new("^(?:\"(#{ESCAPED_CHAR_STRING}|[^\"\\x00])*\"" +
                 "|\'(#{ESCAPED_CHAR_STRING}|[^\'\\x00])*\'" +
                 "|\\((#{ESCAPED_CHAR_STRING}|[^)\\x00])*\\))")

    LINK_DESTINATION_BRACES = /^(?:[<](?:[^ <>\\t\\n\\\\\\x00]|#{ESCAPED_CHAR_STRING}|\\\\)*[>])/

    EMAIL_AUTO_LINK = /^<([a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*)>/
    AUTO_LINK = /^<[A-Za-z][A-Za-z0-9.+-]{1,31}:[^<>\x00-\x20]*>/i

    UNICODE_WHITESPACE_CHAR = /^\s/
    WHITESPACE_CHAR = /^[ \t\n\x0b\x0c\x0d]/
    WHITESPACE = /[ \t\n\x0b\x0c\x0d]+/
    PUNCTUATION = Regex.new("[!-#%-\*,-/:;\?@\[-\]_\{\}\xA1\xA7\xAB\xB6\xB7\xBB\xBF\u037E\u0387\u055A-\u055F\u0589\u058A\u05BE\u05C0\u05C3\u05C6\u05F3\u05F4\u0609\u060A\u060C\u060D\u061B\u061E\u061F\u066A-\u066D\u06D4\u0700-\u070D\u07F7-\u07F9\u0830-\u083E\u085E\u0964\u0965\u0970\u0AF0\u0DF4\u0E4F\u0E5A\u0E5B\u0F04-\u0F12\u0F14\u0F3A-\u0F3D\u0F85\u0FD0-\u0FD4\u0FD9\u0FDA\u104A-\u104F\u10FB\u1360-\u1368\u1400\u166D\u166E\u169B\u169C\u16EB-\u16ED\u1735\u1736\u17D4-\u17D6\u17D8-\u17DA\u1800-\u180A\u1944\u1945\u1A1E\u1A1F\u1AA0-\u1AA6\u1AA8-\u1AAD\u1B5A-\u1B60\u1BFC-\u1BFF\u1C3B-\u1C3F\u1C7E\u1C7F\u1CC0-\u1CC7\u1CD3\u2010-\u2027\u2030-\u2043\u2045-\u2051\u2053-\u205E\u207D\u207E\u208D\u208E\u2308-\u230B\u2329\u232A\u2768-\u2775\u27C5\u27C6\u27E6-\u27EF\u2983-\u2998\u29D8-\u29DB\u29FC\u29FD\u2CF9-\u2CFC\u2CFE\u2CFF\u2D70\u2E00-\u2E2E\u2E30-\u2E42\u3001-\u3003\u3008-\u3011\u3014-\u301F\u3030\u303D\u30A0\u30FB\uA4FE\uA4FF\uA60D-\uA60F\uA673\uA67E\uA6F2-\uA6F7\uA874-\uA877\uA8CE\uA8CF\uA8F8-\uA8FA\uA8FC\uA92E\uA92F\uA95F\uA9C1-\uA9CD\uA9DE\uA9DF\uAA5C-\uAA5F\uAADE\uAADF\uAAF0\uAAF1\uABEB\uFD3E\uFD3F\uFE10-\uFE19\uFE30-\uFE52\uFE54-\uFE61\uFE63\uFE68\uFE6A\uFE6B\uFF01-\uFF03\uFF05-\uFF0A\uFF0C-\uFF0F\uFF1A\uFF1B\uFF1F\uFF20\uFF3B-\uFF3D\uFF3F\uFF5B\uFF5D\uFF5F-\uFF65]|\uD800[\uDD00-\uDD02\uDF9F\uDFD0]|\uD801\uDD6F|\uD802[\uDC57\uDD1F\uDD3F\uDE50-\uDE58\uDE7F\uDEF0-\uDEF6\uDF39-\uDF3F\uDF99-\uDF9C]|\uD804[\uDC47-\uDC4D\uDCBB\uDCBC\uDCBE-\uDCC1\uDD40-\uDD43\uDD74\uDD75\uDDC5-\uDDC9\uDDCD\uDDDB\uDDDD-\uDDDF\uDE38-\uDE3D\uDEA9]|\uD805[\uDCC6\uDDC1-\uDDD7\uDE41-\uDE43\uDF3C-\uDF3E]|\uD809[\uDC70-\uDC74]|\uD81A[\uDE6E\uDE6F\uDEF5\uDF37-\uDF3B\uDF44]|\uD82F\uDC9F|\uD836[\uDE87-\uDE8B]")
    SPNL = /^ *(?:\n *)?/

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
