require "../../src/Crystal2Day.cr"

alias CD = Crystal2Day

WIDTH = 1600
HEIGHT = 900

class CustomScene < CD::Scene
  property dummy : CD::Entity

  def initialize
    CD.custom_loading_path = "examples/TestCompound"

    CD.rm.load_sprite_templates_from_file("SpriteTemplates.json")

    @dummy = CD::Entity.new(CD::EntityType.from_json_file("Dummy.json"))

    @dummy.compound.part("ArmRight").sprite.flip_x = true
    @dummy.compound.part("LegLeft").sprite.angle = 90
    @dummy.compound.part("LegRight").sprite.angle = 90
    @dummy.compound.part("LegRight").sprite.flip_y = true

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
    @dummy.compound.rotate_by(2)
    @dummy.compound.scale_x_by(1.001)
    @dummy.position += CD.xy(0.2, -0.2)

    @dummy.draw(offset: CD.xy(450, 450))
  end
end

CD.run do
  CD::Window.new(title: "Compound Test", w: WIDTH, h: HEIGHT)
  CD.scene = CustomScene.new
  CD.main_routine
end

# TODO: Include shape handling (if possible)
