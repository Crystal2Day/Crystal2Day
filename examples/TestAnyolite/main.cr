# A simple example program to showcase some of the features of Crystal2Day.

require "../../src/Crystal2Day.cr"

alias CD = Crystal2Day

CD.db.add_entity_proc("FigureHandleEvent") do |entity|
  event = Crystal2Day.last_event
  if valid_event = event
    if valid_event.type == Crystal2Day::Event::WINDOW_MOUSE_ENTER
      puts "You entered the window!"
    end
  end
end

CD.db.add_entity_proc("FigurePostUpdate") do |entity|
end

CD.db.add_entity_proc("PlaySound") do |entity|
  channel = entity.get_state("sound_channel").to_i32
  unless CD.sb.sound_playing?(channel: channel)
    CD.sb.play_sound("ExampleSound.ogg", channel: channel, pitch: entity.get_state("sound_pitch").to_f32)
  end
end

CD.db.add_entity_proc("TileCollisionInitial") do |entity|
  entity.each_tile_collision do |collision|
    next unless collision.tile.get_flag("solid")

    if collision.tile_touching_without_edges_at_the_left?(entity)
      entity.velocity.x = 0 if entity.velocity.x < 0
    end
    
    if collision.tile_touching_without_edges_at_the_right?(entity)
      entity.velocity.x = 0 if entity.velocity.x > 0
    end

    if collision.tile_touching_without_edges_at_the_top?(entity)
      entity.velocity.y = 0 if entity.velocity.y < 0
    end

    if collision.tile_touching_without_edges_at_the_bottom?(entity)
      entity.velocity.y = 0 if entity.velocity.y > 0
    end
  end
end

CD.db.add_entity_proc("TileCollisionAlignment") do |entity|
  entity.align_on_rectangular_map
end

CD.db.add_entity_proc("TileCollisionFinal") do |entity|
  entity.each_tile_collision do |collision|
    if collision.tile.get_flag("harmful") && collision.tile_overlap_on_y_axis?(entity)
      puts "LEFT" if collision.tile_touching_at_the_left?(entity)
      puts "RIGHT" if collision.tile_touching_at_the_right?(entity)
    end
  end
end

WIDTH = 1600
HEIGHT = 900

class CustomScene < CD::Scene
  def init
    init_imgui if CRYSTAL2DAY_CONFIGS_IMGUI

    CD.custom_loading_path = "examples/TestAnyolite"

    tileset = CD::Tileset.new
    tileset.load_from_tiled_file!("ExampleTileset.tsx")

    CD.rm.load_sprite_templates_from_file("SpriteTemplates.json")
    
    map = add_map("Map1")
    map.stream_from_file!("ExampleWorld.json", tileset)
    map.layers[0].z = 2
    map.layers[1].z = 4
    map.pin_all_layers

    bg_sprite = add_sprite("Background", template: CD.rm.get_sprite_template("ExampleSky"), position: CD.xy(-100, -100))
    bg_sprite.parallax = CD.xy(0.1, 0.1)

    ui_camera = CD::Camera.new
    ui_camera.z = 4
    ui_camera.pin

    debug_grid = CD::DebugGrid.new(CD::Rect.new(x: 0, y: 0, width: WIDTH, height: HEIGHT))
    debug_grid.z = 10
    debug_grid.node_distance = CD.xy(50, 50)
    debug_grid.pin

    default_font = CD.rm.load_font(CD::Font.default_font_path, size: 50)
    some_text = CD::Text.new("FPS: 0", default_font)
    some_text.z = 4
    some_text.color = CD::Color.white
    some_text.position = CD.xy(0, 0)
    
    add_ui("FPS").add_text("Tracker", some_text)

    CD.db.load_entity_type_from_file("ExampleEntityStateFigure.json")
    CD.db.load_entity_type_from_file("ExampleEntityStatePlayer.json")

    add_entity_group("PlayerGroup", auto_update: true, auto_physics: true, auto_events: true, auto_draw: true, capacity: 1)
    add_entity_group("FigureGroup", auto_update: true, auto_physics: true, auto_events: true, auto_draw: true, capacity: 5)

    add_entity(group: "PlayerGroup", type: "Player", position: CD.xy(600, -50))
    5.times do |i|
      add_entity(group: "FigureGroup", type: "Figure", position: CD.xy(25 + 100*i, -50), initial_param: i)
    end

    camera = CD::Camera.new
    camera.follow_entity(entity_groups["PlayerGroup"].get_entity(0), shift: CD.xy(-WIDTH/2 + 25, -HEIGHT/2 + 25))
    camera.z = 0
    camera.pin

    # TODO: Make it possible to load this from JSON
    CD.im.set_key_table_entry("action_key", [CD::Keyboard::SPACE])
    CD.im.set_key_table_entry("up", [CD::Keyboard::UP, CD::Keyboard::W])
    CD.im.set_key_table_entry("down", [CD::Keyboard::DOWN, CD::Keyboard::S])
    CD.im.set_key_table_entry("left", [CD::Keyboard::LEFT, CD::Keyboard::A])
    CD.im.set_key_table_entry("right", [CD::Keyboard::RIGHT, CD::Keyboard::D])
    CD.im.set_key_table_entry("fast_mode", [CD::Keyboard::L])

    self.collision_matrix_initial.link(entity_groups["FigureGroup"], maps["Map1"])
    self.collision_matrix_initial.link(entity_groups["PlayerGroup"], maps["Map1"])

    self.collision_matrix_alignment.link(entity_groups["FigureGroup"], maps["Map1"])
    self.collision_matrix_alignment.link(entity_groups["PlayerGroup"], maps["Map1"])

    self.collision_matrix_final.link(entity_groups["FigureGroup"], maps["Map1"])
    self.collision_matrix_final.link(entity_groups["PlayerGroup"], maps["Map1"])
    self.collision_matrix_final.link(entity_groups["FigureGroup"])
    self.collision_matrix_final.link(entity_groups["PlayerGroup"], entity_groups["FigureGroup"])
  end

  def update
    @uis["FPS"].update_text("Tracker", "FPS: #{CD.get_fps.round.to_i}\nThis even works multilined!")
  end

  def draw
  end

  def imgui_draw
    ImGui.window("Test Window") do
      ImGui.text("Hello world!")
    end
  end

  def handle_event(event)
    if event.is_quit_event?
      CD.next_scene = nil
    end

    if CD.im.check_event_for_key_press(event, "action_key")
      puts "R Position: #{entity_groups["PlayerGroup"].get_entity(0).position.inspect}"
      puts "A Position: #{entity_groups["PlayerGroup"].get_entity(0).aligned_position.inspect}"
    end
  end

  def exit
    shutdown_imgui if CRYSTAL2DAY_CONFIGS_IMGUI
    CD.current_window.close
    CD.current_window = nil 
  end
end

CD.run do
  CD::Window.new(title: "Hello", w: WIDTH, h: HEIGHT)
  CD.scene = CustomScene.new
  CD.main_routine
end
