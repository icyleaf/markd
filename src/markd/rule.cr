module Markd
  module Rule
    ESCAPABLE_STRING    = %Q([!"#$%&'()*+,./:;<=>?@[\\\\\\]^_`{|}~-])
    ESCAPED_CHAR_STRING = %Q(\\\\) + ESCAPABLE_STRING

    NUMERIC_HTML_ENTITY = /^&#(?:[Xx][0-9a-fA-F]{1,6}|[0-9]{1,7});/
    HTML_ENTITY         = /^&[a-zA-Z0-9]+;/

    TAG_NAME_STRING             = %Q([A-Za-z][A-Za-z0-9-]*)
    ATTRIBUTE_NAME_STRING       = %Q([a-zA-Z_:][a-zA-Z0-9:._-]*)
    UNQUOTED_VALUE_STRING       = %Q([^"'=<>`\\x00-\\x20]+)
    SINGLE_QUOTED_VALUE_STRING  = %Q('[^']*')
    DOUBLE_QUOTED_VALUE_STRING  = %Q("[^"]*")
    ATTRIBUTE_VALUE_STRING      = "(?:" + UNQUOTED_VALUE_STRING + "|" + SINGLE_QUOTED_VALUE_STRING + "|" + DOUBLE_QUOTED_VALUE_STRING + ")"
    ATTRIBUTE_VALUE_SPEC_STRING = "(?:" + "\\s*=" + "\\s*" + ATTRIBUTE_VALUE_STRING + ")"
    ATTRIBUTE                   = "(?:" + "\\s+" + ATTRIBUTE_NAME_STRING + ATTRIBUTE_VALUE_SPEC_STRING + "?)"

    MAYBE_SPECIAL  = {'#', '`', '~', '*', '+', '_', '=', '<', '>', '-', '|'}
    THEMATIC_BREAK = /^(?:(?:\*[ \t]*){3,}|(?:_[ \t]*){3,}|(?:-[ \t]*){3,})[ \t]*$/

    ESCAPABLE = /^#{ESCAPABLE_STRING}/

    TICKS = /`+/

    ELLIPSIS = "..."
    DASH     = /--+/

    OPEN_TAG  = "<" + TAG_NAME_STRING + ATTRIBUTE + "*" + "\\s*/?>"
    CLOSE_TAG = "</" + TAG_NAME_STRING + "\\s*[>]"

    OPEN_TAG_STRING               = "<#{TAG_NAME_STRING}#{ATTRIBUTE}*" + "\\s*/?>"
    CLOSE_TAG_STRING              = "</#{TAG_NAME_STRING}\\s*[>]"
    COMMENT_STRING                = "<!---->|<!--(?:-?[^>-])(?:-?[^-])*-->"
    PROCESSING_INSTRUCTION_STRING = "[<][?].*?[?][>]"
    DECLARATION_STRING            = "<![A-Z]+" + "\\s+[^>]*>"
    CDATA_STRING                  = "<!\\[CDATA\\[[\\s\\S]*?\\]\\]>"
    HTML_TAG_STRING               = "(?:#{OPEN_TAG_STRING}|#{CLOSE_TAG_STRING}|#{COMMENT_STRING}|#{PROCESSING_INSTRUCTION_STRING}|#{DECLARATION_STRING}|#{CDATA_STRING})"
    HTML_TAG                      = /^#{HTML_TAG_STRING}/i

    HTML_BLOCK_OPEN = [
      /^<(?:script|pre|style)(?:\s|>|$)/i,
      /^<!--/,
      /^<[?]/,
      /^<![A-Z]/,
      /^<!\[CDATA\[/,
      /^<[\/]?(?:address|article|aside|base|basefont|blockquote|body|caption|center|col|colgroup|dd|details|dialog|dir|div|dl|dt|fieldset|figcaption|figure|footer|form|frame|frameset|h[123456]|head|header|hr|html|iframe|legend|li|link|main|menu|menuitem|nav|noframes|ol|optgroup|option|p|param|section|source|title|summary|table|tbody|td|tfoot|th|thead|title|tr|track|ul)(?:\s|[\/]?[>]|$)/i,
      Regex.new("^(?:" + OPEN_TAG + "|" + CLOSE_TAG + ")\\s*$", Regex::Options::IGNORE_CASE),
    ]

    HTML_BLOCK_CLOSE = [
      /<\/(?:script|pre|style)>/i,
      /-->/,
      /\?>/,
      />/,
      /\]\]>/,
    ]

    LINK_TITLE = Regex.new("^(?:\"(#{ESCAPED_CHAR_STRING}|[^\"\\x00])*\"" +
                           "|'(#{ESCAPED_CHAR_STRING}|[^'\\x00])*'" +
                           "|\\((#{ESCAPED_CHAR_STRING}|[^)\\x00])*\\))")

    LINK_LABEL = Regex.new("^\\[(?:[^\\\\\\[\\]]|" + ESCAPED_CHAR_STRING + "|\\\\){0,}\\]")

    LINK_DESTINATION_BRACES = Regex.new("^(?:[<](?:[^<>\\t\\n\\\\\\x00]|" + ESCAPED_CHAR_STRING + ")*[>])")

    # A valid domain name is:
    #
    # segments of alphanumeric characters, underscores (_) and hyphens (-)
    # separated by periods (.). No underscores may be present in the last
    # two segments. A URL with a scheme can have a single-label hostname.
    #
    # Alphanumeric characters in this context include emojis.
    LAST_DOMAIN_SEGMENT   = /(?:[a-zA-Z0-9\-\p{Emoji_Presentation}\-]+)/
    OTHER_DOMAIN_SEGMENTS = /(?:[a-zA-Z0-9\p{Emoji_Presentation}\-_]+)/
    # The spec wants to capture greedily, even invalid domain names and then
    # reject the invalid ones later.
    # For example: www.xxx._yyy.zzz is never linked because of the
    # _ in the last segment.
    DOMAIN_NAME       = /(?:#{OTHER_DOMAIN_SEGMENTS}\.)*#{OTHER_DOMAIN_SEGMENTS}/
    VALID_DOMAIN_NAME = /^(?:(?:#{OTHER_DOMAIN_SEGMENTS}\.)*#{LAST_DOMAIN_SEGMENT}\.)?#{LAST_DOMAIN_SEGMENT}$/
    VALID_URL_PATH    = /(?:\/[^\s<]*)?/

    AUTOLINK_PROTOCOLS = /^(?:http|https|ftp):\/\//

    EMAIL_AUTO_LINK          = /^<([a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*)>/
    EXTENDED_EMAIL_AUTO_LINK = /^([a-zA-Z0-9][a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]*@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+)[-_]*/
    AUTO_LINK                = /^<[A-Za-z][A-Za-z0-9.+-]{1,31}:[^<>\x00-\x20]*>/i
    WWW_AUTO_LINK            = /^www\.#{DOMAIN_NAME}#{VALID_URL_PATH}/
    XMPP_AUTO_LINK           = /^xmpp:[A-Za-z0-9]+@#{DOMAIN_NAME}#{VALID_URL_PATH}/
    MAILTO_AUTO_LINK         = /^mailto:[A-Za-z0-9]+@#{DOMAIN_NAME}/
    PROTOCOL_AUTO_LINK       = /#{AUTOLINK_PROTOCOLS}#{DOMAIN_NAME}#{VALID_URL_PATH}/

    WHITESPACE_CHAR    = /^[ \t\n\x0b\x0c\x0d]/
    WHITESPACE         = /[ \t\n\x0b\x0c\x0d]+/
    LINE_ENDING        = /\n|\x0d|\x0d\n/
    PUNCTUATION        = /[\p{P}\p{S}]/
    UNICODE_WHITESPACE = /[\t\n\f\r\p{Zs}]/

    UNSAFE_PROTOCOL      = /^javascript:|vbscript:|file:|data:/i
    UNSAFE_DATA_PROTOCOL = /^data:image\/(?:png|gif|jpeg|webp)/i

    CODE_INDENT = 4

    GFM_DISALLOWED_HTML_TAGS = %w[title textarea style xmp iframe noembed noframes script plaintext]

    TABLE_HEADING_SEPARATOR = /^(\|?\s*:{0,1}-:{0,1}+\s*)+(\||\s*)$/
    TABLE_CELL_SEPARATOR    = /(?<!\\)\|/

    ADMONITION_START = /^> \[!((?:NOTE|TIP|IMPORTANT|CAUTION|WARNING)+)](\s*.*)?$/

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
    abstract def match(parser : Parser, container : Node) : MatchValue

    # token finalize
    abstract def token(parser : Parser, container : Node) : Nil

    # continue
    abstract def continue(parser : Parser, container : Node) : ContinueStatus

    enum ContinueStatus
      Continue
      Stop
      Return
    end

    # accepts_line
    abstract def accepts_lines? : Bool

    private def space_or_tab?(char : Char?) : Bool
      char == ' ' || char == '\t'
    end
  end
end

require "./rules/*"
