# The abstract base class for any drawable objects.
# If you want to implement your own `Drawable`, you need to provide some way to draw it directly.

module Crystal2Day
  abstract class Drawable
    getter z : UInt8 = 0
    getter pinned : Bool = false
    getter render_target : Crystal2Day::RenderTarget

    def initialize(@render_target : Crystal2Day::RenderTarget = Crystal2Day.current_window)
    end

    def draw(offset : Coords = Crystal2Day.xy)
      @render_target.draw(self, offset)
    end

    def finalize
      unpin if @pinned
    end

    def z=(value : Int)
      if value != @z
        if @pinned
          unpin
          @z = value.to_u8
          pin
        else
          @z = value.to_u8
        end
      end
    end

    def pin(offset : Coords = Crystal2Day.xy)
      @pinned = true
      @render_target.pin(self, offset)
    end

    def unpin(offset : Coords = Crystal2Day.xy)
      @pinned = false
      @render_target.unpin(self, offset)
    end

    abstract def draw_directly(offset : Coords)

    def renderer_data
      @render_target.renderer_data
    end

    def unsafe_set_render_target(new_render_target : RenderTarget)
      @render_target = new_render_target
    end
  end
end
