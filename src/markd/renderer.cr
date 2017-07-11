module Markd
  abstract class Renderer

    # @output_io : IO
    # @last_output : String

    def initialize
      @options = Options.new
      @output_io = IO::Memory.new
      @last_output = ""
    end

    def initialize(@options : Options)
      @output_io = IO::Memory.new
      @last_output = ""
    end

    def out(string : String)
      lit(string)
    end

    def lit(string : String)
      @output_io << string
      @last_output = string
    end

    def cr
      lit("\n") if @last_output != "\n"
    end

    def render(document : Node)
      walker = document.walker
      while event = walker.next
        node = event["node"].as(Node)
        entering = event["entering"].as(Bool)

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
        when Node::Type::Paragraph
          paragraph(node, entering)
        when Node::Type::Emphasis
          emphasis(node, entering)
        when Node::Type::Strong
          strong(node, entering)
        else
          text(node, entering)
        end
      end

      @output_io.to_s.lstrip
    end
  end
end

require "./renderers/*"
