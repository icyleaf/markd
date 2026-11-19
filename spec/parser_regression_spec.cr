require "./spec_helper"

describe "Markdown parser regressions" do
  it "treats CR, CRLF, and LF as line endings" do
    Markd.to_html("line1\rline2\r\nline3\n").should eq("<p>line1\nline2\nline3</p>\n")
  end

  it "keeps the final block's source line with or without a trailing newline" do
    options = Markd::Options.new(source_pos: true)
    ["a", "a\n"].each do |input|
      Markd.to_html(input, options).should eq(%(<p data-source-pos="1:1-1:1">a</p>\n))
    end
  end
end
