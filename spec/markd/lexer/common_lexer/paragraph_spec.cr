require "../../../spec_helper"

describe Markd::Lexer do
  assert_common_lexer_render "", [] of Markd::Lexer::Token

  assert_common_lexer_render "Hello", [{
    "type" => "paragraph",
    "text" => "Hello",
  }]

  assert_common_lexer_render "\n\nHello", [
    {
      "type" => "space",
    },
    {
      "type" => "paragraph",
      "text" => "Hello",
    },
  ]

  assert_common_lexer_render "Hello\nWorld", [{
    "type" => "paragraph",
    "text" => "Hello\nWorld",
  }]

  assert_common_lexer_render "Hello\n\nWorld", [{
    "type" => "paragraph",
    "text" => "Hello",
  },
  {
    "type" => "paragraph",
    "text" => "World",
  }]

  assert_common_lexer_render "Hello\n\n\n\n\nWorld", [{
    "type" => "paragraph",
    "text" => "Hello",
  },
  {
    "type" => "paragraph",
    "text" => "World",
  }]

  assert_common_lexer_render "Hello\n  \nWorld", [{
    "type" => "paragraph",
    "text" => "Hello",
  },
  {
    "type" => "paragraph",
    "text" => "World",
  }]
  assert_common_lexer_render "Hello\nWorld\n\nGood\nBye", [{
    "type" => "paragraph",
    "text" => "Hello\nWorld",
  },
  {
    "type" => "paragraph",
    "text" => "Good\nBye",
  }]
end
