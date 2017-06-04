require "../../spec_helper"

describe Markd::Lexer do
  assert_lexer_render "    echo hello world", [{
    "type" => :code,
    "text" => "echo hello world"
  }]

  assert_lexer_render "    echo hello world\n    pwd", [{
    "type" => :code,
    "text" => "echo hello world\npwd"
  }]

  assert_lexer_render "Hello World\n\n    echo hello world", [{
    "type" => :paragraph,
    "text" => "Hello World"
  },
  {
    "type" => :code,
    "text" => "echo hello world"
  }]

  assert_lexer_render "	echo hello world", [
  {
    "type" => :code,
    "text" => "echo hello world"
  }]

  assert_lexer_render "    echo hello world\n\nHello Earch\n\n	echo hello crystal", [
  {
    "type" => :code,
    "text" => "echo hello world"
  },
	{
    "type" => :paragraph,
    "text" => "Hello Earch"
  },
  {
    "type" => :code,
    "text" => "echo hello crystal"
  }]
end
