require "spec"
require "../src/markd"

def assert_common_lexer_render(input, output, file = __FILE__, line = __LINE__)
  it "renders #{input.inspect}", file, line do
    context = Markd::Lexer::Context.new(input)
    lexer = Markd::CommonLexer.new.call(context)

    document = Markd::Lexer::Document.new
    context.document.each do |token|
      token.delete("source")
      document.push(token)
    end

    document.should eq(output), file, line
  end
end