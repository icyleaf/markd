require "spec"
require "../src/markd"

def assert_lexer_render(input, output, file = __FILE__, line = __LINE__)
  it "renders #{input.inspect}", file, line do
    Markd::Lexer.new(input).lex.should eq(output), file, line
  end
end