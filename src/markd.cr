require "./markd/node"
require "./markd/rule"
require "./markd/lexer"
require "./markd/context"
require "./markd/renderer"
require "./markd/parser"
require "./markd/version"

module Markd
  def self.to_html(src, renderer = HTMLRenderer.new)
    parser = Parser.new(src)
    parser.parser(renderer)
  end
end
