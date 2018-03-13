require "html"

module Markd
  abstract class Renderer
    def initialize(@options = Options.new)
      @output_io = IO::Memory.new
      @last_output = "\n"
    end

    def out(string : String)
      lit(escape(string))
    end

    def lit(string : String)
      @output_io << string
      @last_output = string
    end

    def cr
      lit("\n") if @last_output != "\n"
    end

    def escape(text)
      HTML.escape(text)
    end

    def render(document : Node)
      Utils.timer("renderering", @options.time) do
        walker = document.walker
        while event = walker.next
          node, entering = event

          case node.type
          when Node::Type::Heading
            heading(node, entering)
          when Node::Type::List
            list(node, entering)
          when Node::Type::Item
            item(node, entering)
          when Node::Type::BlockQuote
            block_quote(node, entering)
          when Node::Type::ThematicBreak
            thematic_break(node, entering)
          when Node::Type::CodeBlock
            code_block(node, entering)
          when Node::Type::Code
            code(node, entering)
          when Node::Type::HTMLBlock
            html_block(node, entering)
          when Node::Type::HTMLInline
            html_inline(node, entering)
          when Node::Type::Paragraph
            paragraph(node, entering)
          when Node::Type::Emphasis
            emphasis(node, entering)
          when Node::Type::SoftBreak
            soft_break(node, entering)
          when Node::Type::LineBreak
            line_break(node, entering)
          when Node::Type::Strong
            strong(node, entering)
          when Node::Type::Link
            link(node, entering)
          when Node::Type::Image
            image(node, entering)
          else
            text(node, entering)
          end
        end
      end

      @output_io.to_s.sub("\n", "")
    end
  end
end

require "./renderers/*"
