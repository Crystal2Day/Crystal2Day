module Crystal2Day
  class DebugGrid < Crystal2Day::Drawable
    property color : Crystal2Day::Color = Crystal2Day::Color.black
    property bounding_box : Crystal2Day::Rect
    property node_distance : Crystal2Day::Coords = Crystal2Day.xy(10, 10)

    def initialize(@bounding_box : Crystal2Day::Rect, @renderer : Crystal2Day::Renderer = Crystal2Day.current_window.renderer)
    end

    def draw_directly(offset : Coords)
      LibSDL.set_render_draw_color(@renderer.data, @color.r, @color.g, @color.b, @color.a)
      @bounding_box.x.step(to: @bounding_box.x + @bounding_box.width, by: node_distance.x) do |cx|
        draw_x = cx + @renderer.position_shift.x + offset.x
        LibSDL.render_line(@renderer.data, draw_x, @bounding_box.y, draw_x, @bounding_box.y + @bounding_box.height)
      end
      @bounding_box.y.step(to: @bounding_box.y + @bounding_box.height, by: node_distance.y) do |cy|
        draw_y = cy + @renderer.position_shift.y + offset.y
        LibSDL.render_line(@renderer.data, @bounding_box.x, draw_y, @bounding_box.x + @bounding_box.width, draw_y)
      end
    end
  end
end
