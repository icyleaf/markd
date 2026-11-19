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

  it "preserves URI escapes in inline links, references, and autolinks" do
    Markd.to_html("[x](a%2Fb)").should eq(%(<p><a href="a%2Fb">x</a></p>\n))
    Markd.to_html("[r]: /a%3Fb%26c\n\n[r]").should eq(%(<p><a href="/a%3Fb%26c">r</a></p>\n))
    Markd.to_html("<https://example.com/a%26b>").should eq(
      %(<p><a href="https://example.com/a%26b">https://example.com/a%26b</a></p>\n)
    )
  end

  it "resolves one-character labels" do
    Markd.to_html("[r]: /url\n\n[x][r]").should eq(%(<p><a href="/url">x</a></p>\n))
  end

  it "collapses whitespace in reference labels" do
    Markd.to_html("[a  b]: /url\n\n[a b]").should eq(%(<p><a href="/url">a b</a></p>\n))
    Markd.to_html("[a\tb]: /url\t\n\n[a b]").should eq(%(<p><a href="/url">a b</a></p>\n))
  end

  it "uses Unicode spaces and symbols to determine emphasis boundaries" do
    Markd.to_html("a*💡*").should eq("<p>a*💡*</p>\n")
    Markd.to_html("a\u2002*💡*").should eq("<p>a\u2002<em>💡</em></p>\n")
    Markd.to_html("*a*\u00A0b").should eq("<p><em>a</em>\u00A0b</p>\n")
    Markd.to_html("*a\u2002* b").should eq("<p>*a\u2002* b</p>\n")
  end

  it "recognizes Setext headings inside block quotes" do
    Markd.to_html("> foo\n> ---").should eq("<blockquote>\n<h2>foo</h2>\n</blockquote>\n")
  end

  it "ends a table before an ATX heading that contains a pipe" do
    options = Markd::Options.new(gfm: true)
    html = Markd.to_html("A | B\n--- | ---\n# Heading | Text", options)
    html.should eq("<table>\n<thead>\n<tr>\n<th>A</th>\n<th>B</th>\n</tr>\n</thead>\n</table>\n<h1>Heading | Text</h1>\n")
  end

  it "preserves UTF-8 characters while scanning autolinks" do
    options = Markd::Options.new(autolink: true)
    Markd.to_html("ä @foo", options).should eq("<p>ä @foo</p>\n")
  end
end
