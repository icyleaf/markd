module Markd
  struct Options
    property time, gfm, toc, smart, source_pos, safe

    def initialize(@time = false, @gfm = false, @toc = false, @smart = false, @source_pos = false, @safe = false)
    end
  end
end
