module Markd
  class Node
    # Node Type
    enum Type
      Document
      Paragraph
      Text
      Strong
      Emphasis
      Link
      Image
      Heading
      List
      Item
      BlockQuote
      ThematicBreak
      Code
      CodeBlock
      HTMLBlock
      HTMLInline
      LineBreak
      SoftBreak

      CustomInLine
      CustomBlock
    end

    alias DataValue = String | Int32 | Bool
    alias DataType = Hash(String, DataValue)

    property type : Type
    property text : String

    property data : Hash(String, DataValue)

    property parent : Node?
    def parent?
      @parent
    end
    def parent!
      @parent.not_nil!
    end
    property first_child : Node?
    property last_child : Node?
    property prev : Node?
    property next : Node?

    property source_pos : Array(Array(Int32))
    property? open
    property last_line_blank : Bool

    property fenced : Bool
    property fence_language : String
    property fence_char : String
    property fence_length : Int32
    property fence_offset : Int32

    def initialize(@type, **options)
      @data = {} of String => DataValue
      @source_pos = [[1, 1], [0, 0]]
      @text = ""
      @open = true

      @fenced = false
      @fence_language = ""
      @fence_char = ""
      @fence_length = 0
      @fence_offset = 0

      @last_line_blank = false
    end

    def append_child(child : Node)
      child.unlink
      child.parent = self

      if @last_child
        @last_child.not_nil!.next = child
        child.prev = @last_child.not_nil!
        @last_child = child
      else
        @first_child = child
        @last_child = child
      end
    end

    def insert_after(sibling : Node)
      sibling.unlink
      sibling.next = @next
      if sibling.next
        sibling.next.not_nil!.prev = sibling
      end

      sibling.prev = self
      @next = sibling
      sibling.parent = @parent
      unless sibling.next
        sibling.parent.not_nil!.last_child = sibling
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
      @fenced == true
    end

    def walker
      Walker.new(self)
    end

    def to_s(io : IO)
      io << "#<" << {{@type.name.id.stringify}} << ":0x"
      object_id.to_s(16, io)
      io << " @type=#{@type}"
      io << " @parent=#{@parent}" if @parent
      io << " @next=#{@next}" if @next
      io << " @data=#{@data}" if @data.size > 0
      io << ">"
      nil
    end

    private class Walker
      property current : Node?
      property root : Node
      property entering : Bool

      def initialize(@current : Node)
        @root = @current.not_nil!
        @entering = true
      end

      def next
        return unless @current

        current = @current.not_nil!
        entering = @entering

        if entering && container?(current.type)
          if current.first_child
            @current = current.first_child.not_nil!
            @entering = true
          else
            @entering = false
          end
        elsif current == @root
          @current = nil
        elsif !current.next
          @current = current.parent
          @entering = false
        else
          @current = current.next
          @entering = true
        end

        return {
          entering: entering,
          node: current,
        }
      end

      def resume_at(node : Node, entering : Bool)
        @current = node
        @entering = entering
      end

      private def container?(type)
        [Node::Type::Document, Node::Type::BlockQuote,
         Node::Type::List, Node::Type::Item,
         Node::Type::Paragraph, Node::Type::Heading,
         Node::Type::Strong, Node::Type::Emphasis,
         Node::Type::Link, Node::Type::Image,
         Node::Type::CustomInLine, Node::Type::CustomBlock].includes?(type)
      end
    end
  end
end
