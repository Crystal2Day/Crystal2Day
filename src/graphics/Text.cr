# A wrapper around a font texture.
# Use it to draw texts.

module Crystal2Day
  class Text < Crystal2Day::Drawable
    Crystal2DayHelper.wrap_type(Pointer(LibSDL::TTFText))

    getter font : Crystal2Day::Font
    getter color : Crystal2Day::Color

    # TODO: Rendering rotated texts currently doesn't work, maybe reenable it somehow?
    # TODO: Add more text options 

    property position : Crystal2Day::Coords

    def initialize(text : String, @font : Crystal2Day::Font, @color : Crystal2Day::Color = Crystal2Day::Color.black, @position : Crystal2Day::Coords = Crystal2Day.xy, render_target : Crystal2Day::RenderTarget = Crystal2Day.current_window)
      super(render_target)
      @data = LibSDL.ttf_create_text(render_target.renderer.text_engine.not_nil!.data, @font.data, text, text.bytesize)
      render_target.renderer.text_engine.not_nil!.register_text(self)
      self.color = color
    end

    def text=(new_value : String)
      LibSDL.ttf_set_text_string(data, new_value, new_value.bytesize)
    end

    def font=(new_value : Crystal2Day::Font)
      LibSDL.ttf_set_text_font(data, new_value.data)
      @font = new_value
    end

    def color=(new_value : Crystal2Day::Color)
      LibSDL.ttf_set_text_color(data, new_value.r, new_value.g, new_value.b, new_value.a)
      @color = new_value
    end

    def size
      LibSDL.ttf_size_utf8(@font.data, @text, out w, out h)
      Crystal2Day::Rect.new(@positon.x, @position.y, w, h)
    end

    def draw_directly(offset : Coords)
      final_position = @position + @render_target.renderer.position_shift + offset
      LibSDL.ttf_draw_renderer_text(data, final_position.x, final_position.y)
    end

    def free
      if @data
        LibSDL.ttf_destroy_text(data)
        @data = nil
      end
    end

    def finalize
      free
    end
  end
end