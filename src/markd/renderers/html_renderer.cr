require "uri"

module Markd
  class HTMLRenderer < Renderer

    @disable_tag = 0
    @last_output = "\n"

    def heading(node : Node, entering : Bool)
      tag_name = "h#{node.data["level"]}"
      if entering
        cr
        tag(tag_name, attrs(node))
        # toc(node) if @options.toc
      else
        tag("/#{tag_name}")
        cr
      end
    end

    def code(node : Node, entering : Bool)
      tag("code")
      out(node.text)
      tag("/code")
    end

    def code_block(node : Node, entering : Bool)
      languages = node.fence_language ? node.fence_language.split(/\s+/) : [] of String
      attrs = attrs(node)

      if languages.size > 0 && (lang = languages[0]) && !lang.empty?
        attrs["class"] = "language-#{lang.strip}"
      end

      cr
      tag("pre")
      tag("code", attrs)
      out(node.text)
      tag("/code")
      tag("/pre")
      cr
    end

    def thematic_break(node : Node, entering : Bool)
      cr
      tag("hr", attrs(node), true)
      cr
    end

    def block_quote(node : Node, entering : Bool)
      cr
      entering ? tag("blockquote", attrs(node)) : tag("/blockquote")
      cr
    end

    def list(node : Node, entering : Bool)
      attrs = attrs(node)
      tag_name = node.data["type"] == "bullet" ? "ul" : "ol"
      if entering && (start = node.data["start"].as(Int32)) && ![-1, 1].includes?(start)
        attrs["start"] = start.to_s
      end

      cr
      entering ? tag(tag_name, attrs) : tag("/#{tag_name}")
      cr
    end

    def item(node : Node, entering : Bool)
      if entering
        tag("li", attrs(node))
      else
        tag("/li")
        cr
      end
    end

    def html_block(node : Node, entering : Bool)
      cr
      content = @options.safe ? "<!-- raw HTML omitted -->" : node.text
      lit(content)
      cr
    end

    def paragraph(node : Node, entering : Bool)
      if (grand_parant = node.parent.not_nil!.parent) && grand_parant.type == Node::Type::List
        return if grand_parant.data["tight"]
      end

      if entering
        cr
        tag("p", attrs(node))
      else
        tag("/p")
        cr
      end
    end

    def emphasis(node : Node, entering : Bool)
      tag(entering ? "em" : "/em");
    end

    def soft_break(node : Node, entering : Bool)
      lit("\n")
    end

    def line_break(node : Node, entering : Bool)
      tag("br", self_closing: true)
      cr
    end

    def strong(node : Node, entering : Bool)
      tag(entering ? "strong" : "/strong");
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
