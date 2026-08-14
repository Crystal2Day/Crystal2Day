# A collection of text fragments forming a whole text.
# This allows for better control over texts.

module Crystal2Day
  class Text
    FRAGMENTS_INITIAL_CAPACITY = 16

    getter font : Crystal2Day::Font
    getter color : Crystal2Day::Color
    getter text : String

    property position : Crystal2Day::Coords

    property z : UInt8 = 0

    @render_target : Crystal2Day::RenderTarget

    @fragments : Array(Crystal2Day::TextFragment) = Array(Crystal2Day::TextFragment).new(initial_capacity: FRAGMENTS_INITIAL_CAPACITY)

    def initialize(@text : String, @font : Crystal2Day::Font, @color : Crystal2Day::Color = Crystal2Day::Color.black, @position : Crystal2Day::Coords = Crystal2Day.xy, @render_target : Crystal2Day::RenderTarget = Crystal2Day.current_window)
      update
    end

    # TODO: Extend this to include pictures and formatting options in some way
    # TODO: Only update when actually necessary instead of each time an attribute changes
    def update
      @fragments.each do |fragment|
        fragment.free
      end
      @fragments.clear

      accumulated_offset = Crystal2Day.xy

      # TODO: Currently this only splits after newlines, but this needs other features as well
      @text.split("\n").each do |subtext|
        new_fragment = TextFragment.new(subtext, @font, @color, accumulated_offset, @render_target)
        @fragments.push(new_fragment)
        accumulated_offset += Crystal2Day.xy(0, new_fragment.size.height)
      end
    end

    def text=(new_value : String)
      @text = new_value
      update
    end

    def font=(new_value : Crystal2Day::Font)
      @font = new_value
      update
    end

    def color=(new_value : Crystal2Day::Color)
      @color = new_value
      update
    end

    # TODO: Maybe recycle text elements?
    def finalize
      @fragments.each do |fragment|
        fragment.free
      end
      @fragments.clear
    end

    def draw(offset : Coords = Crystal2Day.xy)
      @render_target.with_z_offset(@z) do
        @fragments.each do |fragment|
          fragment.draw(@position + offset)
        end
      end
    end
  end
end
