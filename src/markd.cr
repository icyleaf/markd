require "./markd/node"
require "./markd/rule"
require "./markd/options"
require "./markd/lexer"
require "./markd/renderer"
require "./markd/parser"
require "./markd/version"

module Markd
  def self.to_html(source, renderer = HTMLRenderer.new(Options.new))
    document = Parser.parse(source)
    renderer.render(document)
  end
end
