# The renderer class, responsible for actual drawing.
# This is mostly an internal class.

module Crystal2Day
  class Renderer
    Crystal2DayHelper.wrap_type(Pointer(LibSDL::Renderer))

    @current_view : Crystal2Day::View? = nil
    getter original_view : Crystal2Day::View? = nil
    property position_shift : Crystal2Day::Coords = Crystal2Day.xy
    
    getter orig_clip_rect : Crystal2Day::Rect? = nil
    getter clip_rect : Crystal2Day::Rect? = nil

    def initialize
    end

    # 0 for off, 1 for syncing with every refresh, 2 for syncinc with every second refresh, -1 for adaptive
    def vsync=(value : Number)
      LibSDL.set_render_vsync(data, value.to_i32)
    end

    def vsync
      LibSDL.get_render_vsync(data, out result)
      return result
    end

    def create!(from : Crystal2Day::Window)
      free
      @data = LibSDL.create_renderer(from.data, nil)
      LibSDL.get_render_clip_rect(data, out orig_clip_rect_data)
      @orig_clip_rect = Crystal2Day::Rect.new(x: orig_clip_rect_data.x, y: orig_clip_rect_data.y, width: orig_clip_rect_data.w, height: orig_clip_rect_data.h)
      LibSDL.set_render_draw_blend_mode(data, LibSDL::BlendMode::BLEND)
      @original_view = get_bound_view(from)
      @current_view = get_bound_view(from)
    end

    def create!(from : Crystal2Day::RenderSurface)
      free
      @data = LibSDL.create_software_renderer(from.data)
      LibSDL.get_render_clip_rect(data, out orig_clip_rect_data)
      @orig_clip_rect = Crystal2Day::Rect.new(x: orig_clip_rect_data.x, y: orig_clip_rect_data.y, width: orig_clip_rect_data.w, height: orig_clip_rect_data.h)
      LibSDL.set_render_draw_blend_mode(data, LibSDL::BlendMode::BLEND)
      @original_view = get_bound_view(from)
      @current_view = get_bound_view(from)
    end

    def get_bound_view(from : Crystal2Day::RenderTarget)
      LibSDL.get_render_viewport(data, out rect)
      Crystal2Day::View.new(rect, from)
    end

    def view
      @current_view.not_nil!
    end

    def view=(value : Crystal2Day::View)
      @current_view = value
      LibSDL.set_render_viewport(data, value.raw_data_ptr)
    end

    def reset_view
      self.view = self.original_view.not_nil!
    end

    def reset_shift
      @position_shift = Crystal2Day.xy
    end

    def restore_clip_rect
      @clip_rect = @orig_clip_rect
    end

    def reset
      reset_view
      reset_shift
    end

    def clip_rect=(new_rect : Crystal2Day::Rect?)
      if valid_rect = new_rect
        @clip_rect = new_rect
        new_rect_data = @clip_rect.not_nil!.int_data
        LibSDL.set_render_clip_rect(data, pointerof(new_rect_data))
      else
        @clip_rect = nil
        new_rect_data = @orig_clip_rect.not_nil!.int_data
        LibSDL.set_render_clip_rect(data, pointerof(new_rect_data))
      end
    end

    def free
      if @data
        LibSDL.destroy_renderer(data)
        @data = nil
      end
    end

    def finalize
      free
    end
  end
end
