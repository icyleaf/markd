module Markd
  abstract class Renderer
    abstract def render(token)
  end
end