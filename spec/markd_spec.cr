require "./spec_helper"

# Commonmark spec examples
describe_spec("fixtures/spec.txt")

# Smart punctuation examples
describe_spec("fixtures/smart_punct.txt", smart: true)

# Regression examples
describe_spec("fixtures/regression.txt")

describe_spec("fixtures/emoji.txt")

describe_spec("fixtures/gfm-spec.txt", gfm: true)

describe_spec("fixtures/gfm-extensions.txt", gfm: true)

describe_spec("fixtures/gfm-regression.txt", gfm: true)

# Alert spec examples
describe_spec("fixtures/alert.txt", gfm: true)

describe Markd do
  # Thanks Ryan Westlund <rlwestlund@gmail.com> feedback via email.
  it "should escape unsafe html" do
    raw = %Q{```"><script>window.location="https://footbar.com"</script>\n```}
    html = %Q{<pre><code class="language-&quot;&gt;&lt;script&gt;window.location=&quot;https://footbar.com&quot;&lt;/script&gt;"></code></pre>\n}

    Markd.to_html(raw).should eq(html)
  end

  it "should add a anchor text to the beginning of the head tag" do
    raw = <<-'HEREDOC'
## foo
## bar
### 标题1
### 标题2
HEREDOC

    options = Markd::Options.new(toc: true)

    html = <<-'HEREDOC'
<h2><a id="anchor-f" class="anchor" href="#anchor-f">§ </a>foo</h2>
<h2><a id="anchor-bar" class="anchor" href="#anchor-bar">§ </a>bar</h2>
<h3><a id="anchor-%E6%A0%87%E9%A2%981" class="anchor" href="#anchor-%E6%A0%87%E9%A2%981">§ </a>标题1</h3>
<h3><a id="anchor-%E6%A0%87%E9%A2%982" class="anchor" href="#anchor-%E6%A0%87%E9%A2%982">§ </a>标题2</h3>

HEREDOC

    Markd.to_html(raw, options).should eq(html)

    options = Markd::Options.new(toc: "@")

    html = <<-'HEREDOC'
<h2><a id="anchor-f" class="anchor" href="#anchor-f">@ </a>foo</h2>
<h2><a id="anchor-bar" class="anchor" href="#anchor-bar">@ </a>bar</h2>
<h3><a id="anchor-%E6%A0%87%E9%A2%981" class="anchor" href="#anchor-%E6%A0%87%E9%A2%981">@ </a>标题1</h3>
<h3><a id="anchor-%E6%A0%87%E9%A2%982" class="anchor" href="#anchor-%E6%A0%87%E9%A2%982">@ </a>标题2</h3>

HEREDOC

    Markd.to_html(raw, options).should eq(html)
  end

  it "should generate a correct anchor on the beginning of the head tag" do
    raw = <<-'HEREDOC'
# h1
# h2
# hh3
HEREDOC

    options = Markd::Options.new(toc: true)

    html = <<-'HEREDOC'
<h1><a id="anchor-h1" class="anchor" href="#anchor-h1">§ </a>h1</h1>
<h2><a id="anchor-h2" class="anchor" href="#anchor-h2">§ </a>h2</h2>
<h2><a id="anchor-hh3" class="anchor" href="#anchor-hh3">§ </a>hh3</h2>
HEREDOC

    Markd.to_html(raw, options).should eq(html)
  end
end
