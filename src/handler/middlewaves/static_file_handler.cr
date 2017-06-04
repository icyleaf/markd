module Markd
  class StaticFileHandler
    include Middlewave

    def call(lexer)
      lexer = lexer.sub("a", "b")
    end
  end
end
