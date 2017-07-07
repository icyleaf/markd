module Markd
  struct Options
    property time, gfm, toc, smart, source_pos

    def initialize(@time = false, @gfm = false, @toc = false, @smart = true, @source_pos = false)
    end
  end
end
