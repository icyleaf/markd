require "./markd/lexer"
require "./markd/common_lexer"
require "./markd/inline_lexer"

# require "./markd/renderer"
# require "./markd/html_renderer"
# require "./markd/parser"
require "./markd/version"
require "./handler/*"

module Markd
  def self.to_html(src, renderer = HTMLRenderer.new)
    doc = Parser.new(src)
    renderer.render(doc)
  end
end
