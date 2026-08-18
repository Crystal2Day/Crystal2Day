# A collection of text fragments forming a whole text.
# This allows for better control over texts.

module Crystal2Day
  class Text
    FRAGMENTS_INITIAL_CAPACITY = 16
    SPRITES_INITIAL_CAPACITY = 16

    getter font : Crystal2Day::Font
    getter color : Crystal2Day::Color
    getter text : String

    property position : Crystal2Day::Coords

    property z : UInt8 = 0

    @render_target : Crystal2Day::RenderTarget

    getter needs_rebuild : Bool = false

    getter fragments : Array(Crystal2Day::TextFragment) = Array(Crystal2Day::TextFragment).new(initial_capacity: FRAGMENTS_INITIAL_CAPACITY)
    getter sprites : Array(Crystal2Day::Sprite) = Array(Crystal2Day::Sprite).new(initial_capacity: SPRITES_INITIAL_CAPACITY)

    def initialize(@text : String, @font : Crystal2Day::Font, @color : Crystal2Day::Color = Crystal2Day::Color.black, @position : Crystal2Day::Coords = Crystal2Day.xy, @render_target : Crystal2Day::RenderTarget = Crystal2Day.current_window)
      # Important: This doesn't immediately rebuild in case you create the text earlier and then pass it somewhere else.
      # The UI class will account for this, but if you don't use it around this Text class, you need to call rebuild at the beginning once manually.
      # Otherwise it won't happen before the next update routine, which might desync things. 
      @needs_rebuild = true
    end

    def update
      rebuild if @needs_rebuild

      @sprites.each do |sprite|
        sprite.update
      end
    end

    # TODO: Extend this to include other options (like formatting) in some way
    def rebuild
      reset

      accumulated_offset = Crystal2Day.xy

      # TODO: Respect maximum line width
      @text.split("\n").each do |subtext|
        max_height = 0
        # TODO: Add option to escape these symbols
        # Looks for $(...) expressions (with ':' symbols allowed inside)
        subtext.split(/(\$\([\w\:]*\))/, remove_empty: true) do |subtext_2|
          if subtext_2.starts_with?("$(") && subtext_2.ends_with?(")")
            command = subtext_2[2..-2]
            if command.starts_with?("sprite:")
              # TODO: Add starting animation
              sprite = Sprite.new(Crystal2Day.rm.get_sprite_template(command[7..-1]), render_target: @render_target)
              sprite.update
              sprite.z = @z
              sprite.base_offset = @position + accumulated_offset
              @sprites.push(sprite)
              accumulated_offset.x += sprite.determine_unscaled_render_rect(Crystal2Day.xy).w
              # TODO: Resize sprites and respect their size, position and animations! This is all still very experimental.
            else
              raise "Unknown text command: #{command}"
            end
          else
            new_fragment = TextFragment.new(subtext_2, @font, @color, @position + accumulated_offset, @render_target)

            fragment_height = new_fragment.size.height
            max_height = fragment_height if fragment_height > max_height
            accumulated_offset.x += new_fragment.size.width

            @fragments.push(new_fragment)
          end
        end
        # New line after this fragment
        accumulated_offset.y += max_height
        accumulated_offset.x = 0
      end

      @needs_rebuild = false
    end

    def text=(new_value : String)
      @text = new_value
      @needs_rebuild = true
    end

    def font=(new_value : Crystal2Day::Font)
      @font = new_value
      @needs_rebuild = true
    end

    def color=(new_value : Crystal2Day::Color)
      @color = new_value
      @needs_rebuild = true
    end

    def reset
      @fragments.each do |fragment|
        fragment.free
      end
      @fragments.clear
      @sprites.clear
    end

    def finalize
      reset
    end

    def draw(offset : Coords = Crystal2Day.xy)
      @render_target.with_z_offset(@z) do
        @fragments.each do |fragment|
          fragment.draw(@position + offset)
        end
        @sprites.each do |sprite|
          sprite.draw(@position + offset)
        end
      end
    end
  end
end
