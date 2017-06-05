require "../../../spec_helper"

describe Markd::Lexer do
  assert_common_lexer_render "```\necho hello world\n```", [{
    "type" => "code",
    "text" => "echo hello world"
  }]

  assert_common_lexer_render "```bash\necho hello world\npwd```", [{
    "type" => "code",
    "lang" => "bash",
    "text" => "echo hello world\npwd",
  }]

  assert_common_lexer_render "`````\nhi ther `` ok ```\n`````", [{
    "type" => "code",
    "text" => "hi ther `` ok ```"
  }]

  assert_common_lexer_render "```\n<\n >\n```", [{
    "type" => "code",
    "text" => "&lt;\n &gt;"
  }]

  assert_common_lexer_render "~~~\n<\n >\n~~~", [{
    "type" => "code",
    "text" => "&lt;\n &gt;"
  }]

  assert_common_lexer_render "```\naaa\n~~~\n```", [{
    "type" => "code",
    "text" => "aaa\n~~~"
  }]

  assert_common_lexer_render "~~~\naaa\n```\n~~~", [{
    "type" => "code",
    "text" => "aaa\n```"
  }]

  # TODO: fix it
  # assert_common_lexer_render "````\naaa\n```\n``````", [{
  #   "type" => "code",
  #   "text" => "aaa\n```"
  # }]

  # assert_common_lexer_render "~~~~\naaa\n~~~\n~~~~~", [{
  #   "type" => "code",
  #   "text" => "aaa\n~~~"
  # }]
end
