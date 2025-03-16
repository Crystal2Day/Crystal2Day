# A virtual rendering surface that you can render to.

module Crystal2Day
  class RenderSurface < RenderTarget
    Crystal2DayHelper.wrap_type(Pointer(LibSDL::Surface))

    getter width : UInt32
    getter height : UInt32

    DEFAULT_PIXEL_FORMAT = LibSDL::PixelFormat::RGBA8888

    # TODO: Maybe store references to these somewhere, since they are REQUIRED to call cleanup when not using them anymore
    def initialize(width : Int, height : Int)
      @data = LibSDL.create_surface(width, height, DEFAULT_PIXEL_FORMAT)
      
      @width = width.to_u32
      @height = height.to_u32

      super()
    end

    def get_pixel_at(coords : Coords)
      LibSDL.read_surface_pixel(data, coords.x.to_i32, coords.y.to_i32, out r, out g, out b, out a)
      return Color.new(r: r, g: g, b: b, a: a)
    end

    def write_pixel_at(coords : Coords, color : Color)
      LibSDL.write_surface_pixel(data, coords.x.to_i32, coords.y.to_i32, color.r, color.g, color.g, color.a)
    end

    def finalize
      super()
      LibSDL.destroy_surface(data) if @data
      @data = nil
    end
  end
end
