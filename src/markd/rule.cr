module Markd
  module Rule
    MAYBE_SPECIAL = /^[#`~*+_=<>0-9-]/
    THEMATIC_BREAK = /^(?:(?:\*[ \t]*){3,}|(?:_[ \t]*){3,}|(?:-[ \t]*){3,})[ \t]*$/
    NONSPACE = /[^ \t\f\v\r\n]/

    ATX_HEADING_MARKER = /^ *(\#{1,6}) +([^\n]+?) *#* *(?:\n+|$)/
    SETEXT_HEADING_MARKER = /^(?:=+|-+)[ \t]*$/

    HTMLBLOCKCLOSE = [
      /./, # dummy for 0
      /<\/(?:script|pre|style)>/i,
      /-->/,
      /\?>/,
      />/,
      /\]\]>/
    ]

    # Match Value
    #
    # - None: no match
    # - Container: match container, keep going
    # - Leaf: match leaf, no more block starts
    enum MatchValue
      None
      Container
      Leaf
      Skip
    end

    # parse
    abstract def token(context : Lexer, node : Node) : Void

    # finalize
    abstract def match(context : Lexer, node : Node) : MatchValue

    # continue
    abstract def continue(context : Lexer, node : Node) : Int32

    # accepts_line
    abstract def accepts_lines? : Bool
  end
end

require "./rules/*"
