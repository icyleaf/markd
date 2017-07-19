require "markdown"

FILE = File.expand_path("../../../../source.md", __FILE__)
SOURCE = File.open(FILE, "r").gets_to_end

Markdown.to_html(SOURCE)
