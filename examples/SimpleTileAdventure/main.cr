require "../../src/Crystal2Day.cr"

alias CD = Crystal2Day

WIDTH = 1600
HEIGHT = 900

CD.db.add_entity_proc("FigureMove") do |entity|
  speed = entity.get_state("speed").to_i32
  remaining_distance = entity.get_state("remaining_distance").to_i32

  max_steps = {remaining_distance, speed}.min
  remaining_distance -= max_steps
  entity.set_state("remaining_distance", remaining_distance)

  moving_direction = entity.get_state("moving_direction").to_i32

  if remaining_distance == 0
    if Crystal2Day.im.key_down?("left")
      entity.set_state("moving_direction", 4)
      entity.set_state("remaining_distance", 50)
    elsif Crystal2Day.im.key_down?("right")
      entity.set_state("moving_direction", 6)
      entity.set_state("remaining_distance", 50)
    elsif Crystal2Day.im.key_down?("up")
      entity.set_state("moving_direction", 8)
      entity.set_state("remaining_distance", 50)
    elsif Crystal2Day.im.key_down?("down")
      entity.set_state("moving_direction", 2)
      entity.set_state("remaining_distance", 50)
    else
      entity.set_state("moving_direction", 0)
    end
  end

  case moving_direction
  when 2 then
    entity.position.y += max_steps
  when 4 then
    entity.position.x -= max_steps
  when 6 then
    entity.position.x += max_steps
  when 8 then
    entity.position.y -= max_steps
  end
end

CD.db.add_entity_proc("TileCollision") do |entity|
  entity.each_tile_collision do |collision|
    next if Crystal2Day.im.key_down?("debug_pass_through")

    tile_width = collision.tileset.tile_width
    tile_height = collision.tileset.tile_height

    entity_width = entity.map_boxes["MapBox"].size.x
    entity_height = entity.map_boxes["MapBox"].size.y

    moving_direction = entity.get_state("moving_direction").to_i32
    remaining_distance = entity.get_state("remaining_distance").to_i32

    next if remaining_distance != 50
    if collision.tile.get_flag("solid")
      # Collision right
      if moving_direction == 6 && entity.position.x + 25 == collision.other_position.x && entity.position.y - 25 == collision.other_position.y
        entity.velocity.x = 0
        entity.set_state("remaining_distance", 0)
        entity.set_state("moving_direction", 0)
      end
      # Collision left
      if moving_direction == 4 && entity.position.x - 75 == collision.other_position.x && entity.position.y - 25 == collision.other_position.y
        entity.velocity.x = 0
        entity.set_state("remaining_distance", 0)
        entity.set_state("moving_direction", 0)
      end
      # Collision down
      if moving_direction == 2 && entity.position.y + 25 == collision.other_position.y && entity.position.x - 25 == collision.other_position.x
        entity.velocity.y = 0
        entity.set_state("remaining_distance", 0)
        entity.set_state("moving_direction", 0)
      end
      # Collision up
      if moving_direction == 8 && entity.position.y - 75 == collision.other_position.y && entity.position.x - 25 == collision.other_position.x
        entity.velocity.y = 0
        entity.set_state("remaining_distance", 0)
        entity.set_state("moving_direction", 0)
      end
    end
  end
end

class CustomScene < CD::Scene
  def init
    CD.custom_loading_path = "examples/SimpleTileAdventure"

    CD.rm.load_sprite_templates_from_file("SpriteTemplates.json")

    # Physics steps need to be called manually, as we have no true velocities in this scenario
    CD.number_of_physics_steps = 1

    tileset = CD::Tileset.new
    tileset.load_from_tiled_file!("ExampleTileset.tsx")

    map = add_map("Map1")
    map.stream_from_file!("ExampleWorld.json", tileset)
    map.layers[0].z = 2
    map.layers[1].z = 4
    map.layers[0].content.background_tile = 4
    map.pin_all_layers

    ui_camera = CD::Camera.new
    ui_camera.z = 5
    ui_camera.pin

    default_font = CD.rm.load_font(CD::Font.default_font_path, size: 50)

    some_text = CD::Text.new("FPS: 0", default_font)
    some_text.z = 5
    some_text.color = CD::Color.black
    some_text.position = CD.xy(0, 0)

    add_ui("FPS").add_text("Tracker", some_text)
    
    CD.db.load_entity_type_from_file("ExampleEntityStatePlayer.json")
    add_entity_group("PlayerGroup", auto_update: true, auto_physics: true, auto_events: true, auto_draw: true, capacity: 1)
    add_entity(group: "PlayerGroup", type: "Player", position: CD.xy(425, 125))

    camera = CD::Camera.new
    camera.follow_entity(entity_groups["PlayerGroup"].get_entity(0), shift: CD.xy(-WIDTH/2 + 25, -HEIGHT/2 + 25))
    camera.z = 0
    camera.pin

    CD.im.set_key_table_entry("up", [CD::Keyboard::UP, CD::Keyboard::W])
    CD.im.set_key_table_entry("down", [CD::Keyboard::DOWN, CD::Keyboard::S])
    CD.im.set_key_table_entry("left", [CD::Keyboard::LEFT, CD::Keyboard::A])
    CD.im.set_key_table_entry("right", [CD::Keyboard::RIGHT, CD::Keyboard::D])
    CD.im.set_key_table_entry("debug_pass_through", [CD::Keyboard::LCTRL, CD::Keyboard::RCTRL]) if CD.debug?

    self.collision_matrix_alignment.link(entity_groups["PlayerGroup"], maps["Map1"])
  end

  def update
    @uis["FPS"].update_text("Tracker", "FPS: #{CD.get_fps.round.to_i}")
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

CD.run(debug: true) do
  CD::Window.new(title: "Simple Tile Adventure", w: WIDTH, h: HEIGHT)
  CD.scene = CustomScene.new
  CD.main_routine
end
