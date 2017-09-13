require "crmark"

FILE   = File.expand_path("../../../../source.md", __FILE__)
SOURCE = File.open(FILE, "r").gets_to_end

MarkdownIt::Parser.new(:commonmark).render(SOURCE)
