# The window class.
# You can even create multiples of these (Crystal2Day keeps track of them for you).

module Crystal2Day
  class Window < RenderTarget
    Crystal2DayHelper.wrap_type(Pointer(LibSDL::Window))

    getter width : UInt32
    getter height : UInt32
    getter title : String
    getter fullscreen : Bool

    def initialize(title : String, w : Int, h : Int, x : Int = LibSDL::WINDOWPOS_UNDEFINED, y : Int = LibSDL::WINDOWPOS_UNDEFINED, fullscreen : Bool = false, set_as_current : Bool = true)
      window_flags = fullscreen ? LibSDL::WindowFlags::FULLSCREEN : LibSDL::WindowFlags::None
      @data = LibSDL.create_window(title, w, h, window_flags)
      
      Crystal2Day.error "Could not create window with title \"#{title}\"" unless @data

      LibSDL.set_window_position(@data.not_nil!, x, y)

      @width = w.to_u32
      @height = h.to_u32
      @title = title

      @fullscreen = fullscreen

      Crystal2Day.current_window = self if set_as_current
      Crystal2Day.register_window(self)
      
      super()
    end

    def width=(value : Int)
      @width = value
      LibSDL.set_window_size(data, @width, @height)
    end

    def height=(value : Int)
      @height = value
      LibSDL.set_window_size(data, @width, @height)
    end

    def title=(value : String)
      @title = value
      LibSDL.set_window_title(data, value)
    end

    def fullscreen=(value : Bool)
      @fullscreen = value
      window_flags = @fullscreen ? LibSDL::WindowFlags::FULLSCREEN : LibSDL::WindowFlags::None
      LibSDL.set_window_fullscreen(data, window_flags)
    end

    def enable_fullscreen_stretching
      LibSDL.set_render_logical_presentation(renderer_data, WINDOW_WIDTH, WINDOW_HEIGHT, LibSDL::RendererLogicalPresentation::STRETCH)
    end

    def disable_fullscreen_stretching
      LibSDL.set_render_logical_presentation(renderer_data, WINDOW_WIDTH, WINDOW_HEIGHT, LibSDL::RendererLogicalPresentation::DISABLED)
    end

    def open?
      data?
    end

    def position
      LibSDL.get_window_position(data, out x, out y)
      Crystal2Day::Coords.new(x, y)
    end

    def position=(coords : Crystal2Day::Coords)
      LibSDL.set_window_position(data, coords.x, coords.y)
    end

    def close
      Crystal2Day.current_window = nil if Crystal2Day.current_window_if_any == self
      Crystal2Day.unregister_window(self)
      LibSDL.destroy_window(data)
      @data = nil
    end

    def finalize
      super()
      close
    end
  end
end
