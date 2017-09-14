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
      if entering && (start = node.data["start"].as(Int32)) && start != 1
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

    def link(node : Node, entering : Bool)
      if entering
        attrs = attrs(node)
        if !(@options.safe && potentially_unsafe(node.data["destination"].as(String)))
          attrs["href"] = escape(node.data["destination"].as(String))
        end

        if (title = node.data["title"].as(String)) && !title.empty?
          attrs["title"] = escape(title)
        end

        tag("a", attrs)
      else
        tag("/a")
      end
    end

    def image(node : Node, entering : Bool)
      if entering
        if @disable_tag == 0
          if @options.safe && potentially_unsafe(node.data["destionation"].as(String))
            lit("<img src=\"\" alt=\"\"")
          else
            lit("<img src=\"#{escape(node.data["destination"].as(String))}\" alt=\"")
          end
        end
        @disable_tag += 1
      else
        @disable_tag -= 1
        if @disable_tag == 0
          if (title = node.data["title"].as(String)) && !title.empty?
            lit("\" title=\"#{escape(title)}")
          end
          lit("\" />")
        end
      end
    end

    def html_block(node : Node, entering : Bool)
      cr
      content = @options.safe ? "<!-- raw HTML omitted -->" : node.text
      lit(content)
      cr
    end

    def html_inline(node : Node, entering : Bool)
      content = @options.safe ? "<!-- raw HTML omitted -->" : node.text
      lit(content)
    end

    def paragraph(node : Node, entering : Bool)
      if (grand_parant = node.parent?.try &.parent?) && grand_parant.type.list?
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
      tag(entering ? "em" : "/em")
    end

    def soft_break(node : Node, entering : Bool)
      lit("\n")
    end

    def line_break(node : Node, entering : Bool)
      tag("br", self_closing: true)
      cr
    end

    def strong(node : Node, entering : Bool)
      tag(entering ? "strong" : "/strong")
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

    private def potentially_unsafe(url : String)
      url.match(Rule::UNSAFE_PROTOCOL) && !url.match(Rule::UNSAFE_DATA_PROTOCOL)
    end

    private def toc(node : Node)
      return unless node.type.heading?

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
