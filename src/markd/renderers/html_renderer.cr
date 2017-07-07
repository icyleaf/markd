require "uri"

module Markd
  class HTMLRenderer < Renderer

    @disable_tag = 0
    @last_output = "\n"

    def heading(node : Node, entering : Bool)
      tag_name = "h#{node.data["level"]}"
      attrs = attrs(node)
      if entering
        cr
        tag(tag_name, attrs)
        toc(node) if @options.toc
      else
        tag("/#{tag_name}")
        cr
      end
    end

    def paragraph(node : Node, entering : Bool)
      grand_parant = node.parent.not_nil!.parent
      attrs = attrs(node)

      if grand_parant  && grand_parant.type == Node::Type::List
        return if grand_parant.data["list_tight"]
      end

      if entering
        cr
        tag("p", attrs)
      else
        tag("/p")
        cr
      end
    end

    def text(node : Node, entering : Bool)
      out(node.text)
    end

    private def tag(name : String, attrs = {} of String => String, self_closing = false)
      return if @disable_tag > 0

      @output_io << "<#{name}"
      attrs.each do |k, v|
        @output_io << " #{k}=\"#{v}\""
      end

      @output_io << " /" if self_closing
      @output_io << ">"
      @last_output = ">"
    end

    private def toc(node : Node)
      return if node.type != Node::Type::Heading

      title = URI.escape(node.text)

      @output_io << "<a id=\"anchor-#{title}\" class=\"anchor\" href=\"##{title}\"></a>"
      @last_output = ">"
    end

    private def attrs(node : Node)
      attr = {} of String => String
      if @options.source_pos
        if pos = node.source_pos
          attr["data-source-pos"] = "#{pos[0][0]}:#{pos[0][1]}-#{pos[1][0]}:#{pos[1][1]}"
        end
      end

      attr
    end
  end
end
