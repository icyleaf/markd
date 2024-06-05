module Markd
  abstract class Renderer
    def initialize(@options = Options.new)
      @output_io = String::Builder.new
      @last_output = "\n"
    end

    abstract def output(string : String)
    abstract def block_quote(node : Node, entering : Bool)
    abstract def code_block(node : Node, entering : Bool)
    abstract def code(node : Node, entering : Bool)
    abstract def custom_block(node : Node, entering : Bool)
    abstract def custom_inline(node : Node, entering : Bool)
    abstract def document(node : Node, entering : Bool)
    abstract def emphasis(node : Node, entering : Bool)
    abstract def heading(node : Node, entering : Bool)
    abstract def html_block(node : Node, entering : Bool)
    abstract def html_inline(node : Node, entering : Bool)
    abstract def image(node : Node, entering : Bool)
    abstract def item(node : Node, entering : Bool)
    abstract def line_break(node : Node, entering : Bool)
    abstract def link(node : Node, entering : Bool)
    abstract def list(node : Node, entering : Bool)
    abstract def paragraph(node : Node, entering : Bool)
    abstract def soft_break(node : Node, entering : Bool)
    abstract def strikethrough(node : Node, entering : Bool)
    abstract def strong(node : Node, entering : Bool)
    abstract def text(node : Node, entering : Bool)
    abstract def thematic_break(node : Node, entering : Bool)

    def literal(string : String)
      @output_io << string
      @last_output = string
    end

    # render a Line Feed character
    def newline
      literal("\n") if @last_output != "\n"
    end

    def render(document : Node)
      Utils.timer("rendering", @options.time) do
        walker = document.walker
        while event = walker.next
          node, entering = event

          case node.type
          in Node::Type::Heading
            heading(node, entering)
          in Node::Type::List
            list(node, entering)
          in Node::Type::Item
            item(node, entering)
          in Node::Type::BlockQuote
            block_quote(node, entering)
          in Node::Type::ThematicBreak
            thematic_break(node, entering)
          in Node::Type::CodeBlock
            code_block(node, entering)
          in Node::Type::Code
            code(node, entering)
          in Node::Type::HTMLBlock
            html_block(node, entering)
          in Node::Type::HTMLInline
            html_inline(node, entering)
          in Node::Type::Paragraph
            paragraph(node, entering)
          in Node::Type::Emphasis
            emphasis(node, entering)
          in Node::Type::SoftBreak
            soft_break(node, entering)
          in Node::Type::LineBreak
            line_break(node, entering)
          in Node::Type::Strong
            strong(node, entering)
          in Node::Type::Strikethrough
            strikethrough(node, entering)
          in Node::Type::Link
            link(node, entering)
          in Node::Type::Image
            image(node, entering)
          in Node::Type::Document
            document(node, entering)
          in Node::Type::Text
            text(node, entering)
          in Node::Type::CustomInLine
            custom_inline(node, entering)
          in Node::Type::CustomBlock
            custom_block(node, entering)
          end
        end
      end

      @output_io.to_s.sub("\n", "")
    end
  end
end

require "./renderers/*"
