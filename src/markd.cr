require "./markd/utils"
require "./markd/node"
require "./markd/rule"
require "./markd/options"
require "./markd/lexer"
require "./markd/renderer"
require "./markd/parser"
require "./markd/version"

module Markd
  def self.to_html(source, options = Options.new)
    document = Parser.parse(source, options)
    renderer = HTMLRenderer.new(options)
    renderer.render(document)
  end
end
