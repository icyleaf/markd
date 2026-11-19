require "./spec_helper"

describe "Markdown parser regressions" do
  it "treats CR, CRLF, and LF as line endings" do
    Markd.to_html("line1\rline2\r\nline3\n").should eq("<p>line1\nline2\nline3</p>\n")
  end
end
