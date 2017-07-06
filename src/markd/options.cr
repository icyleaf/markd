module Markd
  struct Options
    property time, gfm, toc, smart

    def initialize(@time = false, @gfm = false, @toc = false, @smart = true)
    end
  end
end
