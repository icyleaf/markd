require "benchmark"
require "markdown"
require "../../../src/markd"

FILE = File.expand_path("../../../source.md", __FILE__)
SOURCE = File.open(FILE, "r").gets_to_end

def builtin
  Markdown.to_html(SOURCE)
end

def markd
  Markd.to_html(SOURCE)
end

Benchmark.ips do |x|
  x.report("Crystal Markdown") { builtin }
  x.report("Markd") { markd }
end
