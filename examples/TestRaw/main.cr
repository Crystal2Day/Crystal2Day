# A simple example program to showcase some of the features of Crystal2Day.

require "../../src/Crystal2Day.cr"

alias CD = Crystal2Day

WIDTH = 1600
HEIGHT = 900

class CustomScene < CD::Scene
  def init
    CD.custom_loading_path = "examples/TestRaw"

    CD.rm.load_sprite_templates_from_file("SpriteTemplates.json")

    bg_sprite = add_sprite("Background", template: CD.rm.get_sprite_template("ExampleSky"), position: CD.xy(-100, -100))
    bg_sprite.parallax = CD.xy(0.1, 0.1)
  end

  def update
    CD.current_window.title = "FPS: #{CD.get_fps.round.to_i}"
  end

  def draw
  end

  def handle_event(event)
    if event.is_quit_event?
      CD.next_scene = nil
    end
  end

  def exit
    CD.current_window.close
    CD.current_window = nil
  end
end

CD.run do
  CD::Window.new(title: "Hello", w: WIDTH, h: HEIGHT)
  CD.scene = CustomScene.new
  CD.main_routine
end
