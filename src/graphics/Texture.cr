# The base texture.
# You can technically draw this directly, but using wrappers like sprites is recommended.
# Keep in mind that these objects are quite large, so you want to avoid creating too many of these.

module Crystal2Day
  class Texture < Crystal2Day::Drawable
    Crystal2DayHelper.wrap_type(Pointer(LibSDL::Texture))

    getter width : Int32 = 0
    getter height : Int32 = 0

    property offset : Crystal2Day::Coords = Crystal2Day.xy

    def initialize(render_target : Crystal2Day::RenderTarget = Crystal2Day.current_window)
      super(render_target)
    end

    def self.load_from_file(filename : String, render_target : Crystal2Day::RenderTarget = Crystal2Day.current_window)
      texture = Crystal2Day::Texture.new(render_target)
      texture.load_from_file!(filename)

      return texture
    end

    def load_from_file!(filename : String)
      free

      full_filename = Crystal2Day.convert_to_absolute_path(filename)

      loaded_surface = LibSDL.img_load(full_filename)
      Crystal2Day.error "Could not load image from file #{full_filename}" unless loaded_surface

      @data = LibSDL.create_texture_from_surface(renderer_data, loaded_surface)
      Crystal2Day.error "Could not create texture from file #{full_filename}" unless @data

      @width = loaded_surface.value.w
      @height = loaded_surface.value.h

      LibSDL.destroy_surface(loaded_surface)
    end

    def load_text_from_font!(text : String, font : Crystal2Day::Font, color : Crystal2Day::Color = Crystal2Day::Color.black)
      free

      text_surface = LibSDL.ttf_render_text_solid_wrapped(font.data, text, text.size, color.data, 0)
      Crystal2Day.error "Could not create texture from rendered text" unless text_surface

      @data = LibSDL.create_texture_from_surface(renderer_data, text_surface)
      Crystal2Day.error "Could not create texture from rendered text surface" unless @data

      @width = text_surface.value.w
      @height = text_surface.value.h

      LibSDL.destroy_surface(text_surface)
    end

    def raw_boundary_rect(shifted_by : Crystal2Day::Coords = Crystal2Day.xy)
      LibSDL::FRect.new(x: @offset.x + shifted_by.x, y: @offset.y + shifted_by.y, w: @width, h: @height)
    end

    def raw_int_boundary_rect(shifted_by : Crystal2Day::Coords = Crystal2Day.xy)
      LibSDL::Rect.new(x: @offset.x + shifted_by.x, y: @offset.y + shifted_by.y, w: @width, h: @height)
    end

    def draw_directly(offset : Coords)
      render_rect = raw_boundary_rect
      render_rect.x += @render_target.renderer.position_shift.x + offset.x
      render_rect.y += @render_target.renderer.position_shift.y + offset.y
      LibSDL.render_texture_rotated(renderer_data, data, nil, pointerof(render_rect), 0.0, nil, LibSDL::FlipMode::NONE)
    end

    def unsafe_set_size(new_width : Int32, new_height : Int32)
      @width = new_width
      @height = new_height
    end

    def free
      if @data
        LibSDL.destroy_texture(data)
        @data = nil
        @width = 0
        @height = 0
      end
    end

    def finalize 
      super
      free
    end
  end
end
