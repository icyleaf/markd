require "uri"

module Markd
  class HTMLRenderer < Renderer
    @disable_tag = 0
    @last_output = "\n"

    @strong_stack = 0

    HEADINGS = %w[h1 h2 h3 h4 h5 h6]

    def heading(node : Node, entering : Bool) : Nil
      tag_name = HEADINGS[node.data["level"].as(Int32) - 1]
      if entering
        newline
        tag(tag_name, attrs(node))
        toc(node) if @options.toc?
      else
        tag(tag_name, end_tag: true)
        newline
      end
    end

    def code(node : Node, entering : Bool) : Nil
      tag("code") do
        code_body(node)
      end
    end

    def code_body(node : Node)
      output(node.text)
    end

    def code_block(node : Node, entering : Bool, formatter : T?) : Nil forall T
      {% if @top_level.has_constant?("Tartrazine") %}
        render_code_block_use_tartrazine(node, formatter)
      {% else %}
        render_code_block_use_code_tag(node)
      {% end %}
    end

    def code_block_language(languages)
      languages.try(&.first?).try(&.strip.presence)
    end

    def code_block_body(node : Node, lang : String?) : Nil
      output(node.text)
    end

    def thematic_break(node : Node, entering : Bool) : Nil
      newline
      tag("hr", attrs(node), self_closing: true)
      newline
    end

    def block_quote(node : Node, entering : Bool) : Nil
      newline
      if entering
        tag("blockquote", attrs(node))
      else
        tag("blockquote", end_tag: true)
      end
      newline
    end

    def alert(node : Node, entering : Bool) : Nil
      newline
      if entering
        tag("div", {"class" => "alert alert-#{node.data["alert"].to_s.downcase}"})
        tag("p", {"class" => "alert-title"}) do
          output(node.data["title"].as(String))
        end
      else
        tag("div", end_tag: true)
      end
      newline
    end

    def table(node : Node, entering : Bool) : Nil
      has_body = node.data["has_body"]
      newline
      if entering
        tag("table", attrs(node))
      else
        if has_body
          tag("tbody", end_tag: true)
          newline
        end
        tag("table", end_tag: true)
      end
      newline
    end

    def table_row(node : Node, entering : Bool) : Nil
      newline
      is_heading = node.data["heading"]
      has_body = node.data["has_body"]
      if entering
        if is_heading
          tag("thead")
          newline
        end
        tag("tr", attrs(node))
      else
        tag("tr", end_tag: true)
        newline
        if is_heading
          tag("thead", end_tag: true)
          newline
          if has_body
            tag("tbody")
            newline
          end
        end
      end
    end

    def table_cell(node : Node, entering : Bool) : Nil
      tag_name = node.data["heading"] ? "th" : "td"
      if !node.data["align"].to_s.empty?
        attrs = {"align" => node.data["align"]}
      else
        attrs = {} of String => String
      end
      if entering
        newline
        tag(tag_name, attrs)
      else
        tag(tag_name, end_tag: true)
        newline
      end
    end

    def list(node : Node, entering : Bool) : Nil
      tag_name = node.data["type"] == "ordered" ? "ol" : "ul"

      newline
      if entering
        attrs = attrs(node)

        if (start = node.data["start"].as(Int32)) && start != 1
          attrs ||= {} of String => String
          attrs["start"] = start.to_s
        end

        tag(tag_name, attrs)
      else
        tag(tag_name, end_tag: true)
      end
      newline
    end

    def item(node : Node, entering : Bool) : Nil
      if entering
        tag("li", attrs(node))

        if node.data["type"] == "checkbox"
          if node.data["checked"]?
            attributes = {
              "checked"  => "",
              "disabled" => "",
              "type"     => "checkbox",
            }
          else
            attributes = {
              "disabled" => "",
              "type"     => "checkbox",
            }
          end

          tag("input", attributes)
          literal(" ")
        end
      else
        tag("li", end_tag: true)
        newline
      end
    end

    def link(node : Node, entering : Bool) : Nil
      if entering
        attrs = attrs(node)
        destination = node.data["destination"].as(String)

        unless @options.safe? && potentially_unsafe(destination)
          attrs ||= {} of String => String
          destination = resolve_uri(destination, node)
          attrs["href"] = escape(destination)
        end

        if (title = node.data["title"].as(String)) && !title.empty?
          attrs ||= {} of String => String
          attrs["title"] = escape(title)
        end

        tag("a", attrs)
      else
        tag("a", end_tag: true)
      end
    end

    private def resolve_uri(destination, node)
      base_url = @options.base_url
      return destination unless base_url

      uri = URI.parse(destination)
      return destination if uri.absolute?

      base_url.resolve(uri).to_s
    end

    def image(node : Node, entering : Bool) : Nil
      if entering
        if @disable_tag == 0
          destination = node.data["destination"].as(String)
          if @options.safe? && potentially_unsafe(destination)
            literal(%(<img src="" alt=""))
          else
            destination = resolve_uri(destination, node)
            literal(%(<img src="#{escape(destination)}" alt="))
          end
        end
        @disable_tag += 1
      else
        @disable_tag -= 1
        if @disable_tag == 0
          if (title = node.data["title"].as(String)) && !title.empty?
            literal(%(" title="#{escape(title)}))
          end
          literal(%(" />))
        end
      end
    end

    def html_block(node : Node, entering : Bool) : Nil
      newline
      content = @options.safe? ? "<!-- raw HTML omitted -->" : node.text
      literal(content)
      newline
    end

    def html_inline(node : Node, entering : Bool) : Nil
      content = @options.safe? ? "<!-- raw HTML omitted -->" : node.text
      literal(content)
    end

    def paragraph(node : Node, entering : Bool) : Nil
      if (grand_parent = node.parent?.try &.parent?) && grand_parent.type.list?
        return if grand_parent.data["tight"]
      end

      if entering
        newline
        tag("p", attrs(node))
      else
        # If this is the last paragraph in a footnote definition, append backrefs
        if last_paragraph_in_footnote?(node)
          append_footnote_backrefs(node.parent)
        end
        tag("p", end_tag: true)
        newline
      end
    end

    # Check if this paragraph is the last paragraph child of a footnote definition
    private def last_paragraph_in_footnote?(node : Node) : Bool
      parent = node.parent?
      return false unless parent && parent.type.footnote_definition?

      # Check if this is the last paragraph (there might be no more paragraphs after this)
      # but there could be non-paragraph nodes after, so we check if there's no next sibling
      # that is a paragraph
      sibling = node.next?
      while sibling
        return false if sibling.type.paragraph?
        sibling = sibling.next?
      end
      true
    end

    # Encode a string for use in HTML id attributes
    # This matches the old URI.encode behavior for footnote IDs
    private def encode_id_component(string : String) : String
      String.build do |io|
        URI.encode(string, io) do |byte|
          # Allow unreserved chars plus some additional chars that are safe in HTML IDs
          URI.unreserved?(byte) || ['/', '(', ')', '*', '!', '$', '\'', ',', ';', ':', '@', '&', '=', '+'].includes?(byte.chr)
        end
      end
    end

    # Append footnote back-reference links
    # @param in_paragraph If true, adds a space before the backrefs
    private def append_footnote_backrefs(footnote_def : Node, in_paragraph : Bool = true) : Nil
      encoded_title = encode_id_component(footnote_def.data["title"].to_s)
      footnote_number = footnote_def.data["number"].as(Int32)
      ref_count = footnote_def.data["ref_count"].as(Int32)

      # Add a space before the backrefs if we're inside a paragraph
      literal " " if in_paragraph

      # Generate backref(s) - multiple if referenced multiple times
      (1..ref_count).each do |ref_index|
        backref_id = ref_index == 1 ? "fnref-#{encoded_title}" : "fnref-#{encoded_title}-#{ref_index}"
        backref_idx = ref_index == 1 ? footnote_number.to_s : "#{footnote_number}-#{ref_index}"

        tag("a", {
          "href"                      => "##{backref_id}",
          "class"                     => "footnote-backref",
          "data-footnote-backref"     => nil,
          "data-footnote-backref-idx" => backref_idx,
          "aria-label"                => "Back to reference #{backref_idx}",
        })
        literal "↩"
        # For 2nd and later backrefs, add a superscript with the index
        if ref_index > 1
          tag("sup", {"class" => "footnote-ref"})
          literal ref_index.to_s
          tag("sup", end_tag: true)
        end
        tag("a", end_tag: true)
        literal " " if ref_index < ref_count
      end
    end

    def emphasis(node : Node, entering : Bool) : Nil
      if entering
        node.data["strong_stack"] = @strong_stack
        @strong_stack = 0
      end

      tag("em", end_tag: !entering)

      if !entering
        @strong_stack = node.data["strong_stack"].as(Int32)
      end
    end

    def soft_break(node : Node, entering : Bool) : Nil
      literal("\n")
    end

    def line_break(node : Node, entering : Bool) : Nil
      tag("br", self_closing: true)
      newline
    end

    def strong(node : Node, entering : Bool) : Nil
      @strong_stack -= 1 if @options.gfm? && !entering

      tag("strong", end_tag: !entering) if @strong_stack == 0

      @strong_stack += 1 if @options.gfm? && entering
    end

    def strikethrough(node : Node, entering : Bool) : Nil
      tag("del", end_tag: !entering)
    end

    def text(node : Node, entering : Bool) : Nil
      output(node.text)
    end

    def footnote(node : Node, entering : Bool) : Nil
      # Spec says `[^1]` should generate:
      # <sup class=\"footnote-ref\"><a href=\"#fn-1\" id=\"fnref-1\" data-footnote-ref>1</a></sup>
      # For multiple references to the same footnote:
      # First: id="fnref-label", Second: id="fnref-label-2", etc.
      if entering
        tag("sup", {
          "class" => "footnote-ref",
        })
        ref_index = node.data["ref_index"].as(Int32)
        encoded_title = encode_id_component(node.data["title"].to_s)
        id = ref_index == 1 ? "fnref-#{encoded_title}" : "fnref-#{encoded_title}-#{ref_index}"
        tag("a", {
          "href"              => "#fn-#{encoded_title}",
          "id"                => id,
          "data-footnote-ref" => nil,
        })
        # GFM spec says to output the number of the footnote
        output node.data["number"].to_s
        tag("a", end_tag: true)
        tag("sup", end_tag: true)
      end
    end

    def footnote_definition(node : Node, entering : Bool) : Nil
      # A footnote definition by spec should render something like:
      # <li id="fn-1">
      # <p>The actual content of the footnote
      # <a href="#fnref-1" class="footnote-backref" data-footnote-backref data-footnote-backref-idx="1" aria-label="Back to reference 1">↩</a></p>
      # </li>
      # For multiple references, multiple backref links are generated:
      # <a href="#fnref-label" class="footnote-backref" data-footnote-backref data-footnote-backref-idx="1" aria-label="Back to reference 1">↩</a>
      # <a href="#fnref-label-2" class="footnote-backref" data-footnote-backref data-footnote-backref-idx="1-2" aria-label="Back to reference 1-2">↩<sup class="footnote-ref">2</sup></a>
      if entering
        if !node.prev.type.footnote_definition?
          newline
          tag("section", {"class" => "footnotes", "data-footnotes" => nil})
          newline
          tag("ol")
        end
        newline
        tag("li", {
          "id" => "fn-#{encode_id_component(node.data["title"].to_s)}",
        })
        newline
      else
        # If there's no paragraph child, output backrefs here
        # (e.g., for footnote definitions that only contain code blocks)
        unless has_paragraph_child?(node)
          append_footnote_backrefs(node, in_paragraph: false)
          newline
        end
        tag("li", end_tag: true)
        if node == node.parent.last_child
          newline
          tag("ol", end_tag: true)
          newline
          tag("section", end_tag: true)
          newline
        end
      end
    end

    # Check if a node has a paragraph child
    private def has_paragraph_child?(node : Node) : Bool
      child = node.first_child?
      while child
        return true if child.type.paragraph?
        child = child.next?
      end
      false
    end

    private def tag(name : String, attrs = nil, self_closing = false, end_tag = false)
      return if @disable_tag > 0

      @output_io << "<"
      @output_io << "/" if end_tag
      @output_io << name
      attrs.try &.each do |key, value|
        if value.nil?
          @output_io << ' ' << key
        else
          @output_io << ' ' << key << '=' << '"' << value << '"'
        end
      end

      @output_io << " /" if self_closing
      @output_io << ">"
      @last_output = ">"
    end

    private def tag(name : String, attrs = nil, &)
      tag(name, attrs)
      yield
      tag(name, end_tag: true)
    end

    private def potentially_unsafe(url : String)
      url.match(Rule::UNSAFE_PROTOCOL) && !url.match(Rule::UNSAFE_DATA_PROTOCOL)
    end

    private def toc(node : Node)
      return unless node.type.heading?

      {% if compare_versions(Crystal::VERSION, "1.2.0") < 0 %}
        title = URI.encode(node.first_child.text)
        @output_io << %(<a id="anchor-) << title << %(" class="anchor" href="#anchor-) << title << %("></a>)
      {% else %}
        title = URI.encode_path(node.first_child.text)
        @output_io << %(<a id="anchor-) << title << %(" class="anchor" href="#anchor-) << title << %("></a>)
      {% end %}
      @last_output = ">"
    end

    private def attrs(node : Node)
      if @options.source_pos? && (pos = node.source_pos)
        {"data-source-pos" => "#{pos[0][0]}:#{pos[0][1]}-#{pos[1][0]}:#{pos[1][1]}"}
      end
    end

    private def render_code_block_use_tartrazine(node : Node, formatter : Tartrazine::Formatter?)
      languages = node.fence_language ? node.fence_language.split : nil
      lang = code_block_language(languages)

      newline

      if lang
        lexer = Tartrazine.lexer(lang)

        literal(formatter.format(node.text.chomp, lexer))
      else
        code_tag_attrs = attrs(node)
        pre_tag_attrs = if @options.prettyprint?
                          {"class" => "prettyprint"}
                        end

        tag("pre", pre_tag_attrs) do
          tag("code", code_tag_attrs) do
            code_block_body(node, lang)
          end
        end
      end

      newline
    end

    private def render_code_block_use_code_tag(node : Node)
      languages = node.fence_language ? node.fence_language.split : nil
      code_tag_attrs = attrs(node)
      pre_tag_attrs = if @options.prettyprint?
                        {"class" => "prettyprint"}
                      end

      lang = code_block_language(languages)
      if lang
        code_tag_attrs ||= {} of String => String
        code_tag_attrs["class"] = "language-#{escape(lang)}"
      end

      newline
      tag("pre", pre_tag_attrs) do
        tag("code", code_tag_attrs) do
          code_block_body(node, lang)
        end
      end
      newline
    end
  end
end
