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

  it "keeps unmatched link openers from crossing paragraphs" do
    Markd.to_html("[open\n\nclose](url)").should eq("<p>[open</p>\n<p>close](url)</p>\n")
  end

  it "treats malformed entity references as text without swallowing inlines" do
    Markd.to_html("&;").should eq("<p>&amp;;</p>\n")
    Markd.to_html("x & *hi* &amp;").should eq("<p>x &amp; <em>hi</em> &amp;</p>\n")
  end

  it "decodes numeric entities above the basic multilingual plane" do
    Markd.to_html("&#x1F600;").should eq("<p>😀</p>\n")
    Markd.to_html("[x](&#x1F600;)").should eq(%(<p><a href="%F0%9F%98%80">x</a></p>\n))
    Markd.to_html("&#x110000;").should eq("<p>�</p>\n")
  end
end
