module Markd
  class Parser
    def self.parse(source)
      self.new(source).document
    end

    def self.parse(source, options)
      self.new(source, options).document
    end

    getter document

    @document : Node

    def initialize(source : String)
      @document = Lexer::Block.parse(source, Options.new)
    end

    def initialize(source : String, options : Options)
      @document = Lexer::Block.parse(source, options)
    end
  end
end
