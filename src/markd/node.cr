module Markd
  class Node
    # Node Type
    enum Type
      Document
      Paragraph
      Heading
      List
      Item
      BlockQuote
      ThematicBreak
      CodeBlock
      HTMLBlock
    end

    property type : Type
    property text : String

    property data : Hash(String, String|Int32|Bool)

    property parent : Node?
    property first_child : Node?
    property last_child : Node?
    property pos_range : Array(Array(Int32))
    property open

    property prev : Node?
    property next : Node?

    property is_fenced : Bool
    property last_line_blank : Bool

    def initialize(@type, **options)
      @data = {} of String => String|Int32|Bool
      @text = ""
      @open = true
      @is_fenced = false
      @pos_range = [[1, 1], [0, 0]]

      @last_line_blank = false
      @html_block_type = -1
    end

    def append_child(child : Node)
      child.unlink
      child.parent = self
      if (@last_child)
        @last_child.not_nil!.next = child
        @prev = @last_child
        @last_child = child
      else
        @first_child = child
        @last_child = child
      end
    end

    def unlink
      if @prev
        @prev.not_nil!.next = @next
      elsif @parent
        @parent.not_nil!.first_child = @next
      end

      if @next
        @next.not_nil!.prev = @prev
      elsif @parent
        @parent.not_nil!.last_child = @prev
      end

      @parent = nil
      @next = nil
      @prev = nil
    end

    def fenced?
      @is_fenced == true
    end

    def to_s(io : IO)
      io << "#<" << {{@type.name.id.stringify}} << ":0x"
      object_id.to_s(16, io)

      io << " @type=#{@type}"
      io << " @parent=#{@parent}" if @parent
      io << " @next=#{@next}" if @next

      io << ">"
      nil
    end
  end
end
