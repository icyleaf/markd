module Markd
  class ExceptionHandler
    include Middlewave

    def call(lexer)
      lexer = lexer.gsub(">", "<")
      call_next(lexer)
    end
  end
end
