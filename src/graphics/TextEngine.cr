module Crystal2Day
  class TextEngine
    Crystal2DayHelper.wrap_type(Pointer(LibSDL::TTFTextEngine))

    def initialize(renderer : Crystal2Day::Renderer)
      @data = LibSDL.ttf_create_renderer_text_engine(renderer.data)
    end

    def free
      if @data
        LibSDL.ttf_destroy_renderer_text_engine(data)
        @data = nil
      end
    end
  
    def finalize
      free
    end
  end
end
