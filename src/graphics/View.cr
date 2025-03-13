# A drawable object, which specifies a viewport for all objects above it.
# This allows for minimaps or split screens.

module Crystal2Day
  class View < Crystal2Day::Drawable
    @data : LibSDL::Rect

    def initialize(rect : Crystal2Day::Rect, render_target : Crystal2Day::RenderTarget = Crystal2Day.current_window)
      super(render_target)
      @data = LibSDL::Rect.new(x: rect.x, y: rect.y, w: rect.width, h: rect.height)
    end

    def x
      @data.x
    end

    def x=(value : Number)
      @data.x = value
    end

    def y
      @data.y
    end

    def y=(value : Number)
      @data.y = value
    end
    
    def width
      @data.w
    end

    def width=(value : Number)
      @data.w = value
    end

    def height
      @data.h
    end

    def height=(value : Number)
      @data.h = value
    end

    def initialize
      @data = LibSDL::Rect.new
      super(Crystal2Day.current_window)
    end

    def initialize(raw_rect : LibSDL::Rect, render_target : Crystal2Day::RenderTarget)
      @data = raw_rect
      super(render_target)
    end

    def draw_directly(offset : Coords)
      @render_target.renderer.view = self
    end

    def raw_data_ptr
      pointerof(@data)
    end
  end
end
