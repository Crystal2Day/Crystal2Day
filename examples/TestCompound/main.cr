require "../../src/Crystal2Day.cr"

alias CD = Crystal2Day

WIDTH = 1600
HEIGHT = 900

class CustomScene < CD::Scene
  property dummy : CD::Entity

  def initialize
    Crystal2Day.custom_loading_path = "examples/TestCompound"

    @dummy = CD::Entity.new(CD::EntityType.from_json_file("Dummy.json"))

    @dummy.get_part("ArmRight").sprite.flip_x = true
    @dummy.get_part("LegLeft").sprite.angle = 90
    @dummy.get_part("LegRight").sprite.angle = 90
    @dummy.get_part("LegRight").sprite.flip_y = true

    debug_grid = CD::DebugGrid.new(CD::Rect.new(x: 0, y: 0, width: WIDTH, height: HEIGHT))
    debug_grid.z = 10
    debug_grid.node_distance = CD.xy(50, 50)
    debug_grid.pin
  end

  def handle_event(event)
    if event.is_quit_event?
      CD.next_scene = nil
    end
  end

  def draw
    @dummy.get_part().rotate_by(2)
    @dummy.get_part().scale_x_by(1.001)
    @dummy.position += CD.xy(0.2, -0.2)

    @dummy.draw(offset: CD.xy(450, 450))
  end
end

CD.run do
  CD::Window.new(title: "Compound Test", w: WIDTH, h: HEIGHT)
  CD.scene = CustomScene.new
  CD.main_routine
end

# TODO: Remove actual sprites from entity
# TODO: Allocate a default compound, if no compound was specified?
# TODO: Include shape handling (if possible)
# TODO: Fix other examples if necessary
# TODO: Determine sprite source rectangle from texture if no value was given
