require "benchmark"
require "markdown"
require "../../../src/markd"

SOURCE = <<-EOF
## Try CommonMark

You can try CommonMark here.  This dingus is powered by
[commonmark.js](https://github.com/jgm/commonmark.js), the
JavaScript reference implementation.

1. item one
2. item two
   - sublist
   - sublist
EOF

def builtin
  Markdown.to_html(SOURCE)
end

def markd
  Markd.to_html(SOURCE)
end

Benchmark.ips do |x|
  x.report("Crystal Built-in") { builtin }
  x.report("Markd") { markd }
end
