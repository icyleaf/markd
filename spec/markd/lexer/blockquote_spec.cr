require "../../spec_helper"

describe Markd::Lexer do
  assert_lexer_render "> # Foo\n> bar\n> baz", [{
    "type" => :blockquote_start
  },
  {
    "type" => :heading,
    "level" => 1,
    "text" => "Foo"
  },
  {
    "type" => :paragraph,
    "text" => "bar\nbaz"
  },
  {
    "type" => :blockquote_end
  }]

  assert_lexer_render "> # Foo\n>bar\n> baz", [{
    "type" => :blockquote_start
  },
  {
    "type" => :heading,
    "level" => 1,
    "text" => "Foo"
  },
  {
    "type" => :paragraph,
    "text" => "bar\nbaz"
  },
  {
    "type" => :blockquote_end
  }]

  assert_lexer_render ">   # Foo\n>   bar\n > baz", [{
    "type" => :blockquote_start
  },
  {
    "type" => :heading,
    "level" => 1,
    "text" => "Foo"
  },
  {
    "type" => :paragraph,
    "text" => "bar\nbaz"
  },
  {
    "type" => :blockquote_end
  }]

  assert_lexer_render "    > # Foo\n    > bar\n    > baz", [{
    "type" => :code,
    "text" => "&gt; # Foo\n&gt; bar\n&gt; baz"
  }]
end