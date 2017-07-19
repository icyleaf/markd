require "benchmark"
require "markdown"
require "markd"
require "crmark"

FILE = File.expand_path("../../../source.md", __FILE__)
SOURCE = File.open(FILE, "r").gets_to_end

def builtin
  Markdown.to_html(SOURCE)
end

def markd
  Markd.to_html(SOURCE)
end

def crmark(flavor)
  parser = MarkdownIt::Parser.new(flavor)
  parser.render(SOURCE)
end

Benchmark.ips do |x|
  x.report("crystal markdown") { builtin }
  x.report("markd") { markd }
  x.report("crmark in :commonmark") { crmark(:commonmark) }
  x.report("crmark in :markdownit") { crmark(:markdownit) }
  # x.report("crystal-cmark") { common_mark }
end
