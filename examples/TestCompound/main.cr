require "../../src/Crystal2Day.cr"

alias CD = Crystal2Day

WIDTH = 1600
HEIGHT = 900

class CustomScene < CD::Scene
  property dummy : CD::Entity

  def initialize
    Crystal2Day.custom_loading_path = "examples/TestCompound"

    @dummy = CD::Entity.new(CD::EntityType.from_json_file("Dummy.json"))

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
    @dummy.compound.not_nil!.sprite.scale_y += 0.0005
    @dummy.compound.not_nil!.sprite.scale_x += 0.001
    @dummy.compound.not_nil!.connections["Head"].part.sprite.scale_x -= 0.0005
    @dummy.compound.not_nil!.sprite.angle += 2.0
    @dummy.compound.not_nil!.connections["Head"].part.sprite.angle += 4.0

    @dummy.compound.not_nil!.connections["ArmRight"].part.sprite.center = CD.xy(1, 0.5)
    @dummy.compound.not_nil!.connections["ArmLeft"].part.sprite.angle += 1.0
    @dummy.compound.not_nil!.connections["ArmRight"].part.sprite.angle += 3.0

    @dummy.compound.not_nil!.draw(offset: CD.xy(450, 450))

    @dummy.draw(offset: CD.xy(450, 450))
  end
end

CD.run do
  CD::Window.new(title: "Compound Test", w: WIDTH, h: HEIGHT)
  CD.scene = CustomScene.new
  CD.main_routine
end

# TODO: Finish compound loading
# TODO: What to do if no compound was specified? Either don't draw anything or draw all sprites (likely the latter one)
# TODO: Maybe allocate a default compound, if no compound was specified?
# TODO: If a compound was spcified, only draw these, not the sprites. 
# TODO: Add compound logic (referring to others, simulating rotations)
# TODO: Add routine to rotate or scale an entire compound (unless a connection was specified as rigid)