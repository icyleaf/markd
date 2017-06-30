module Markd
  module Rule
    NONSPACE = /[^ \t\f\v\r\n]/
    MAYBE_SPECIAL = /^[#`~*+_=<>0-9-]/
    THEMATIC_BREAK = /^(?:(?:\*[ \t]*){3,}|(?:_[ \t]*){3,}|(?:-[ \t]*){3,})[ \t]*$/
    HTMLBLOCK_CLOSE = [
      /./, # dummy for 0
      /<\/(?:script|pre|style)>/i,
      /-->/,
      /\?>/,
      />/,
      /\]\]>/
    ]

    CODE_INDENT = 4

    CHAR_CODE_TAB = 9
    CHAR_CODE_NEWLINE = 10
    CHAR_CODE_SPACE = 32
    CHAR_CODE_LESSTHAN = 60
    CHAR_CODE_GREATERTHAN = 62
    CHAR_CODE_OPEN_BRACKET = 91

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

    def peek(parser : Lexer, index = parser.next_nonspace) : String
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
  end
end

require "./rules/*"
