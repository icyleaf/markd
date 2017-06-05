require "./markd/lexer"
require "./markd/lexer_context"
require "./markd/common_lexer"
require "./markd/inline_lexer"
require "./markd/renderer"
require "./markd/html_renderer"
require "./markd/parser"
require "./markd/version"

module Markd
  def self.to_html(src, renderer = HTMLRenderer.new)
    parser = Parser.new(src)
    parser.parser(renderer)
  end
end
