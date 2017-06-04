require "../../spec_helper"

describe Markd::Lexer do
  assert_lexer_render "---\n___", [{
    "type" => :hr
  },
  {
    "type" => :hr
  }]

  assert_lexer_render "+++", [{
    "type" => :paragraph,
    "text" => "+++"
  }]

  assert_lexer_render "===", [{
    "type" => :paragraph,
    "text" => "==="
  }]

  assert_lexer_render "--\n**\n__", [{
    "type" => :paragraph,
    "text" => "--\n**\n__"
  }]

  assert_lexer_render " ***\n  ***\n   ***", [{
    "type" => :hr
  },
  {
    "type" => :hr
  },
  {
    "type" => :hr
  }]

  assert_lexer_render "    ***", [{
    "type" => :code,
    "text" => "***"
  }]

  assert_lexer_render "Foo\n    ***", [{
    "type" => :paragraph,
    "text" => "Foo\n    ***"
  }]

  assert_lexer_render "_____________________________________\n - - -\n **  * ** * ** * **\n-     -      -      -\n- - - -    ", [{
    "type" => :hr
  },
  {
    "type" => :hr
  },
  {
    "type" => :hr
  },
  {
    "type" => :hr
  },
  {
    "type" => :hr
  }]

  assert_lexer_render "_ _ _ _ a\n\na------\n\n---a---", [{
    "type" => :paragraph,
    "text" => "_ _ _ _ a"
  },
  {
    "type" => :paragraph,
    "text" => "a------"
  },
  {
    "type" => :paragraph,
    "text" => "---a---"
  }]

end
