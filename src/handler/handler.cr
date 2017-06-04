module Markd
  module Middlewave
    property next : Middlewave | Proc | Nil

    abstract def call(lexer : String)

    def call_next(lexer : String)
      if next_handler = @next
        next_handler.call(lexer)
      end
    end

    alias Proc = String ->
  end
end

require "./middlewaves/*"