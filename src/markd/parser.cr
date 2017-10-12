module Markd
  module Parser
    def self.parse(source, options = Options.new)
      Block.parse(source, options)
    end
  end
end

require "./parsers/*"
