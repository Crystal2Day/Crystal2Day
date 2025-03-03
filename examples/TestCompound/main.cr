require "../../src/Crystal2Day.cr"

alias CD = Crystal2Day

WIDTH = 1600
HEIGHT = 900

class CustomScene < CD::Scene
  def initialize
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