require "../../src/Crystal2Day.cr"

alias CD = Crystal2Day

WIDTH = 1600
HEIGHT = 900

class CustomScene < CD::Scene
  property dummy : CD::Part
  property fake_entity : CD::Entity

  def initialize
    Crystal2Day.custom_loading_path = "examples/TestCompound"

    @fake_entity = CD::Entity.new(CD::EntityType.from_json_file("Dummy.json"))
    
    @dummy = CD::Part.new(@fake_entity.get_sprite("Body"))
    head_part = CD::Part.new(@fake_entity.get_sprite("Head"))
    @dummy.connections["Head"] = CD::PartConnection.new(head_part, joint: CD.xy(0.5, 0))

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
    @fake_entity.get_sprite("Body").scale_y += 0.0005
    @fake_entity.get_sprite("Body").scale_x += 0.001
    @fake_entity.get_sprite("Head").scale_x -= 0.0005
    @fake_entity.get_sprite("Body").angle += 2.0
    @fake_entity.get_sprite("Head").angle += 4.0
    @dummy.draw(offset: CD.xy(450, 450))
  end
end

CD.run do
  CD::Window.new(title: "Compound Test", w: WIDTH, h: HEIGHT)
  CD.scene = CustomScene.new
  CD.main_routine
end

# TODO: Add compound loading
# TODO: What to do if no compound was specified? Either don't draw anything or draw all sprites (likely the latter one)
# TODO: Maybe allocate a default compound, if no compound was specified?
# TODO: If a compound was spcified, only draw these, not the sprites. 
# TODO: Add compound logic (referring to others, simulating rotations)
# TODO: Add routine to rotate or scale an entire compound (unless a connection was specified as rigid)