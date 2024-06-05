module Markd
  class MarkdownRenderer < Renderer
    def output(string : String)
      literal(string)
    end

    def block_quote(node : Node, entering : Bool)
      if entering
        newline
        output("> ")
      end
    end

    def code_block(node : Node, entering : Bool)
      newline
      output("```#{node.fence_language}")
      newline
      output(node.text)
      output("```")
      newline
    end

    def code(node : Node, entering : Bool)
      output("`")
      output(node.text)
      output("`")
    end

    def custom_block(node : Node, entering : Bool)
      text(node, entering)
    end

    def custom_inline(node : Node, entering : Bool)
      text(node, entering)
    end

    def document(node : Node, entering : Bool)
      text(node, entering)
    end

    def emphasis(node : Node, entering : Bool)
      output("*")
    end

    def heading(node : Node, entering : Bool)
      if entering
        newline
        output("#" * node.data["level"].as(Int32))
      end
    end

    def html_block(node : Node, entering : Bool)
      newline
      content = @options.safe? ? "<!-- raw HTML omitted -->" : node.text
      output(content)
      newline
    end

    def html_inline(node : Node, entering : Bool)
      content = @options.safe? ? "<!-- raw HTML omitted -->" : node.text
      output(content)
    end

    def image(node : Node, entering : Bool)
      if entering
        output("![")
      else
        output("](#{node.data["destination"].as(String)})")
      end
    end

    def item(node : Node, entering : Bool)
      newline

      if entering
        output("- ")
      end
    end

    def line_break(node : Node, entering : Bool)
      newline
    end

    def link(node : Node, entering : Bool)
      if entering
        output("[")
      else
        output("](#{node.data["destination"].as(String)})")
      end
    end

    def list(node : Node, entering : Bool)
    end

    def paragraph(node : Node, entering : Bool)
      newline
    end

    def soft_break(node : Node, entering : Bool)
      newline
    end

    def strikethrough(node : Node, entering : Bool)
      output("~")
    end

    def strong(node : Node, entering : Bool)
      output("**")
    end

    def text(node : Node, entering : Bool)
      output(node.text)
    end

    def thematic_break(node : Node, entering : Bool)
      newline
      output("---")
      newline
    end
  end
end
