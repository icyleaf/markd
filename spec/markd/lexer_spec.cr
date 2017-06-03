require "../spec_helper"

private def assert_render(input, output)
  it "renders #{input.inspect}" do
    Markd::Lexer.new(input).lex.should eq(output)
  end
end

describe Markd::Lexer do
  assert_render "", [] of Markd::Lexer::Token

  assert_render "Hello", [{
    "type" => :paragraph,
    "text" => "Hello",
  }]

  assert_render "\n\nHello", [
    {
      "type" => :space,
    },
    {
      "type" => :paragraph,
      "text" => "Hello",
    },
  ]

  assert_render "Hello\nWorld", [{
    "type" => :paragraph,
    "text" => "Hello\nWorld",
  }]

  assert_render "Hello\n\nWorld", [{
    "type" => :paragraph,
    "text" => "Hello",
  },
  {
    "type" => :paragraph,
    "text" => "World",
  }]

  assert_render "Hello\n\n\n\n\nWorld", [{
    "type" => :paragraph,
    "text" => "Hello",
  },
  {
    "type" => :paragraph,
    "text" => "World",
  }]

  assert_render "Hello\n  \nWorld", [{
    "type" => :paragraph,
    "text" => "Hello",
  },
  {
    "type" => :paragraph,
    "text" => "World",
  }]
  assert_render "Hello\nWorld\n\nGood\nBye", [{
    "type" => :paragraph,
    "text" => "Hello\nWorld",
  },
  {
    "type" => :paragraph,
    "text" => "Good\nBye",
  }]
end
