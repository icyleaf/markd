require "../../../spec_helper"

describe Markd::Lexer do
  assert_common_lexer_render "# Heading 1", [{
    "type" => "heading",
    "level" => 1,
    "text" => "Heading 1",
  }]

  assert_common_lexer_render "## Heading 2", [{
    "type" => "heading",
    "level" => 2,
    "text" => "Heading 2",
  }]

  assert_common_lexer_render "###### Heading 6", [{
    "type" => "heading",
    "level" => 6,
    "text" => "Heading 6",
  }]

  assert_common_lexer_render "## Heading 2\n### Heading 3", [{
    "type" => "heading",
    "level" => 2,
    "text" => "Heading 2",
  },
  {
    "type" => "heading",
    "level" => 3,
    "text" => "Heading 3",
  }]

  assert_common_lexer_render "####### Heading 7", [{
    "type" => "paragraph",
    "text" => "####### Heading 7",
  }]

  assert_common_lexer_render "#Heading 1", [{
    "type" => "paragraph",
    "text" => "#Heading 1",
  }]

  assert_common_lexer_render "#Heading 1", [{
    "type" => "paragraph",
    "text" => "#Heading 1",
  }]

  assert_common_lexer_render "#Heading 1", [{
    "type" => "paragraph",
    "text" => "#Heading 1",
  }]

  assert_common_lexer_render "#Heading 1\n#Heading 2", [{
    "type" => "paragraph",
    "text" => "#Heading 1\n#Heading 2",
  }]
end
