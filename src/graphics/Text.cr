# A wrapper around a font texture.
# Use it to draw texts.

# TODO: Rework this using the new SDL3 routines and add more options

module Crystal2Day
  class Text < Crystal2Day::Drawable
    @texture : Crystal2Day::Texture

    getter text : String
    getter font : Crystal2Day::Font
    getter color : Crystal2Day::Color

    property position : Crystal2Day::Coords = Crystal2Day.xy
    property render_rect : Crystal2Day::Rect?
    property angle : Float32 = 0.0f32
    property center : Crystal2Day::Coords?

    def initialize(@text : String, @font : Crystal2Day::Font, @color : Crystal2Day::Color = Crystal2Day::Color.black)
      @texture = Crystal2Day::Texture.new
      super(@texture.render_target)
      update!
    end

    def text=(new_value : String)
      @text = new_value
      update!
    end

    def font=(new_value : Crystal2Day::Font)
      @font = new_value
      update!
    end

    def color=(new_value : Crystal2Day::Color)
      @color = new_value
      update!
    end

    def size
      LibSDL.ttf_size_utf8(@font.data, @text, out w, out h)
      Crystal2Day::Rect.new(@positon.x, @position.y, w, h)
    end

    def update!
      @texture.load_text_from_font!(@text, @font, color: @color)
    end

    def draw_directly(offset : Coords)
      final_source_rect = @texture.raw_boundary_rect
      final_render_rect = (render_rect = @render_rect) ? (render_rect + @position + @render_target.renderer.position_shift + offset).data : @texture.raw_boundary_rect(shifted_by: @position + @render_target.renderer.position_shift + offset)
      flip_flag = LibSDL::FlipMode::NONE
      if center = @center
        final_center_point = center.data
        LibSDL.render_texture_rotated(renderer_data, @texture.data, pointerof(final_source_rect), pointerof(final_render_rect), @angle, pointerof(final_center_point), flip_flag)
      else
        LibSDL.render_texture_rotated(renderer_data, @texture.data, pointerof(final_source_rect), pointerof(final_render_rect), @angle, nil, flip_flag)
      end
    end
  end
end