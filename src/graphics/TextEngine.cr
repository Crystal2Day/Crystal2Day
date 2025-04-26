module Crystal2Day
  class TextEngine
    TEXTS_INITIAL_CAPACITY = 16

    Crystal2DayHelper.wrap_type(Pointer(LibSDL::TTFTextEngine))

    @texts : Array(Crystal2Day::Text) = Array(Crystal2Day::Text).new(initial_capacity: TEXTS_INITIAL_CAPACITY)

    def initialize(renderer : Crystal2Day::Renderer)
      @data = LibSDL.ttf_create_renderer_text_engine(renderer.data)
    end

    def register_text(text : Crystal2Day::Text)
      @texts.push(text)
    end

    def unregister_texts
      @texts.each do |text|
        text.free
      end
      @texts.clear
    end

    def free
      unregister_texts

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
