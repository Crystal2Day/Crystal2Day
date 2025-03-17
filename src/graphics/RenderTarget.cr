# The abstract class for Window and RenderSurface.

module Crystal2Day
  abstract class RenderTarget
    getter renderer : Crystal2Day::Renderer = Crystal2Day::Renderer.new
    getter render_queue : Crystal2Day::RenderQueue = Crystal2Day::RenderQueue.new

    property resource_manager : Crystal2Day::ResourceManager = Crystal2Day::ResourceManager.new

    property z_offset : UInt8 = 0

    # NOTE: This is relevant for the camera position, NOT the camera center!
    property parallax_center : Crystal2Day::Coords = Crystal2Day.xy

    property background_color : Crystal2Day::Color = Crystal2Day::Color.white

    def initialize
      @renderer.create!(self)
      Crystal2Day.error "Could not create renderer" unless @renderer.data?

      @resource_manager.render_target = self
    end

    def clear
      LibSDL.set_render_draw_color(@renderer.data, @background_color.r, @background_color.g, @background_color.b, @background_color.a)
      LibSDL.render_clear(@renderer.data)
    end

    def draw(obj : Crystal2Day::Drawable, offset : Coords = Crystal2Day.xy)
      @render_queue.add(obj, @z_offset + obj.z, offset)
    end

    def pin(obj : Crystal2Day::Drawable, offset : Coords = Crystal2Day.xy)
      @render_queue.add_static(obj, @z_offset + obj.z, offset)
    end

    def unpin(obj : Crystal2Day::Drawable, offset : Coords = Crystal2Day.xy)
      @render_queue.delete_static(obj, @z_offset + obj.z, offset)
    end

    def unpin_all
      @render_queue.delete_static_content
    end

    def with_z_offset(z_offset : Number)
      @z_offset += z_offset.to_u8
      yield nil
      @z_offset -= z_offset.to_u8
    end
  
    def with_view(view : Crystal2Day::View, z_offset : Number = 0u8)
      with_z_offset(z_offset) do
        self.draw view
        yield nil
      end
    end
  
    def with_pinned_view(view : Crystal2Day::View, z_offset : Number = 0u8)
      with_z_offset(z_offset) do
        self.pin view
        yield nil
      end
    end

    def render
      @renderer.reset
      @render_queue.draw
    end

    def renderer_data
      return @renderer.data
    end

    def display
      LibSDL.render_present(@renderer.data)
    end

    def cleanup
      unpin_all
      # Replace the members with dummy variables to avoid unwanted recursions
      # Otherwise the GC might throw weird warnings
      @resource_manager.clear
      @render_queue = RenderQueue.new
      @resource_manager = ResourceManager.new
      @renderer.free
      @renderer = Renderer.new
    end

    def finalize
      # Just for good measure
      cleanup
    end
  end
end
