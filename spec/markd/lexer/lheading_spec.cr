require "../../spec_helper"
require "markdown"

describe Markd::Lexer do
  assert_lexer_render "Heading 1\n=========\n", [{
    "type" => :heading,
    "level" => 1,
    "text" => "Heading 1",
  }]

  assert_lexer_render "Heading 2\n---------\n", [{
    "type" => :heading,
    "level" => 2,
    "text" => "Heading 2",
  }]

  assert_lexer_render "   Heading 2\n---", [{
    "type" => :heading,
    "level" => 2,
    "text" => "Heading 2",
  }]

  assert_lexer_render " Heading 2\n---", [{
    "type" => :heading,
    "level" => 2,
    "text" => "Heading 2",
  }]

  assert_lexer_render "  Heading 2\n  ---", [{
    "type" => :heading,
    "level" => 2,
    "text" => "Heading 2",
  }]

  assert_lexer_render "Heading 2\n   ---     ", [{
    "type" => :heading,
    "level" => 2,
    "text" => "Heading 2",
  }]

  assert_lexer_render "Foo  \n-----", [{
    "type" => :heading,
    "level" => 2,
    "text" => "Foo",
  }]

  assert_lexer_render "Foo\\\n-----", [{
    "type" => :heading,
    "level" => 2,
    "text" => "Foo\\",
  }]


  # TODO: fix it
  # assert_lexer_render "Heading 2\n    ----", [{
  #   "type" => :paragraph,
  #   "text" => "Heading 2\n----",
  # }]

  assert_lexer_render "Foo\n= =\n\nFoo\n--- -", [{
    "type" => :paragraph,
    "text" => "Foo\n= =",
  },
  {
    "type" => :paragraph,
    "text" => "Foo\n--- -",
  }]

end
