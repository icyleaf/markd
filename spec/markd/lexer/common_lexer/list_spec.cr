require "../../../spec_helper"

describe Markd::Lexer do
  assert_common_lexer_render "- one\n\n two", [{
    "type" => "list_start",
    "style" => "unordered"
  },
  {
    "type" => "list_item_start"
  },
  {
    "type" => "text",
    "text" => "one"
  },
  {
    "type" => "space",
  },
  {
    "type" => "text",
    "text" => "two",
  },
  {
    "type" => "list_item_end"
  },
  {
    "type" => "list_end"
  }]

  assert_common_lexer_render "- one\n\n  two", [{
    "type" => "list_start",
    "style" => "unordered"
  },
  {
    "type" => "list_item_start"
  },
  {
    "type" => "text",
    "text" => "one"
  },
  {
    "type" => "space",
  },
  {
    "type" => "text",
    "text" => "two",
  },
  {
    "type" => "list_item_end"
  },
  {
    "type" => "list_end"
  }]

  assert_common_lexer_render "123456789. ok", [{
    "type" => "list_start",
    "style" => "ordered"
  },
  {
    "type" => "list_item_start"
  },
  {
    "type" => "text",
    "text" => "ok"
  },
  {
    "type" => "list_item_end"
  },
  {
    "type" => "list_end"
  }]

  assert_common_lexer_render "-one\n\n2.two", [{
    "type" => "paragraph",
    "text" => "-one"
  },
  {
    "type" => "paragraph",
    "text" => "2.two"
  }]

  assert_common_lexer_render "1.  foo\n\n    ```\n    bar\n    ```\n\n    baz\n\n    > bam", [
    {"type" => "list_start", "style" => "ordered"},
    {"type" => "list_item_start"},
    {"type" => "text", "text" => "foo"},
    {"type" => "space"},
    {"type" => "code", "text" => "bar"},
    {"type" => "text", "text" => "baz"},
    {"type" => "space"},
    {"type" => "blockquote_start"},
    {"type" => "paragraph", "text" => "bam"},
    {"type" => "blockquote_end"},
    {"type" => "list_item_end"},
    {"type" => "list_end"}
  ]

end