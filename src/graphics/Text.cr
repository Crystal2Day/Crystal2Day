# A collection of text fragments forming a whole text.
# This allows for better control over texts.

module Crystal2Day
  class Text
    LINES_INITIAL_CAPACITY = 16
    FRAGMENTS_INITIAL_CAPACITY = 16
    SPRITES_INITIAL_CAPACITY = 16
    DRAWABLES_INITIAL_CAPACITY = 32

    getter font : Crystal2Day::Font
    getter color : Crystal2Day::Color
    getter text : String

    property position : Crystal2Day::Coords

    property z : UInt8 = 0

    @render_target : Crystal2Day::RenderTarget

    getter needs_rebuild : Bool = false

    # Safe lists for text elements, can be modified from outside
    getter fragments : Array(Crystal2Day::TextFragment) = Array(Crystal2Day::TextFragment).new(initial_capacity: FRAGMENTS_INITIAL_CAPACITY)
    getter sprites : Array(Crystal2Day::Sprite) = Array(Crystal2Day::Sprite).new(initial_capacity: SPRITES_INITIAL_CAPACITY)

    getter sprite_placements : Array(Float32) = Array(Float32).new(initial_capacity: SPRITES_INITIAL_CAPACITY)

    # Unsafe render list, should not be used from outside
    @render_list : Array(Array(Crystal2Day::Drawable)) = Array(Array(Crystal2Day::Drawable)).new(initial_capacity: LINES_INITIAL_CAPACITY)

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

      # TODO: Maybe add other options like changing fonts and text sizes

      # TODO: Respect maximum line width
      @text.split("\n").each do |subtext|
        @render_list.push(Array(Crystal2Day::Drawable).new(initial_capacity: DRAWABLES_INITIAL_CAPACITY))
        # TODO: Add option to escape these symbols
        # Looks for $(...) expressions (with ':' symbols allowed inside)
        subtext.split(/(\$\([\w\-.\:\|]*\))/, remove_empty: true) do |subtext_2|
          if subtext_2.starts_with?("$(") && subtext_2.ends_with?(")")
            full_command = subtext_2[2..-2]
            command_parts = full_command.split("|")
            main_command = command_parts[0]
            arguments = {} of String => String
            if main_command.starts_with?("sprite:")
              sprite_placement = 0.0f32
              starting_animation = nil
              command_parts[1..-1].each do |command_part|
                command_part_split = command_part.split(":")
                starting_animation = command_part_split[1] if command_part_split[0] == "animation"
                sprite_placement = command_part_split[1].to_f32 if command_part_split[0] == "placement"
              end
              sprite = Sprite.new(Crystal2Day.rm.get_sprite_template(main_command[7..-1]), render_target: @render_target, starting_animation: starting_animation)
              sprite.z = @z
              @sprites.push(sprite)
              @sprite_placements.push(sprite_placement)
              @render_list.last.push(sprite)
              # TODO: Add ways to resize and reposition sprites
            else
              raise "Unrecognized text command: #{main_command}"
            end
          else
            new_fragment = TextFragment.new(subtext_2, @font, @color, render_target: @render_target)
            @fragments.push(new_fragment)
            @render_list.last.push(new_fragment)
          end
        end
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
      @fragments.clear
      @sprites.clear
      @sprite_placements.clear
    end

    def finalize
      reset
    end

    def draw(offset : Coords = Crystal2Day.xy)
      accumulated_offset = Crystal2Day.xy
      
      sprite_index = 0
      @render_target.with_z_offset(@z) do
        @render_list.each do |render_line|
          max_height = 0
          render_line.each_with_index do |drawable|
            additional_offset = Crystal2Day.xy

            drawable_width = 0
            drawable_height = 0
            if drawable.is_a?(Crystal2Day::TextFragment)
              drawable_size = drawable.as(Crystal2Day::TextFragment).size
              drawable_width = drawable_size.width
              drawable_height = drawable_size.height
            elsif drawable.is_a?(Crystal2Day::Sprite)
              drawable_size = drawable.as(Crystal2Day::Sprite).determine_final_render_rect(Crystal2Day.xy, ignore_camera_shift: true)
              drawable_width = drawable_size.w
              drawable_height = drawable_size.h

              placement = @sprite_placements[sprite_index]

              # TODO: Properly deal with off-centered sprites
              additional_offset = Crystal2Day.xy(-drawable_size.x, -drawable_size.y - (drawable_height - @font.size) / 2 * (1.0 + placement))

              sprite_index += 1
            end

            drawable.draw(@position + offset + accumulated_offset + additional_offset)

            max_height = drawable_height if drawable_height > max_height
            accumulated_offset.x += drawable_width
          end
          # New line after this fragment
          accumulated_offset.y += max_height
          accumulated_offset.x = 0
        end
      end
    end
  end
end
