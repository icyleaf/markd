module Markd
  abstract class Renderer

    # @output_io : IO
    # @last_output : String

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

        puts "#{node.type}: #{node.text}"

        case node.type
        when Node::Type::Heading
          heading(node, entering)
        when Node::Type::Paragraph
          paragraph(node, entering)
        else
          text(node, entering)
        end
      end

      @output_io
    end
  end
end

require "./renderers/*"
