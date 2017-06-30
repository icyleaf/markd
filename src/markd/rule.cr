module Markd
  module Rule
    MAYBE_SPECIAL = /^[#`~*+_=<>0-9-]/
    THEMATIC_BREAK = /^(?:(?:\*[ \t]*){3,}|(?:_[ \t]*){3,}|(?:-[ \t]*){3,})[ \t]*$/
    NONSPACE = /[^ \t\f\v\r\n]/

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

    # parse
    abstract def token(context : Lexer, node : Node) : Void

    # finalize
    abstract def match(context : Lexer, node : Node) : MatchValue

    # continue
    abstract def continue(context : Lexer, node : Node) : Int32

    # accepts_line
    abstract def accepts_lines? : Bool

    def text_clean(context : Lexer) : String
      context.line[context.next_nonspace..-1]
    end

    def char_code_at(context : Lexer, index = context.next_nonspace) : UInt8?
      return nil if context.line.empty?

      context.line.byte_at(index)
    end
  end
end

require "./rules/*"
