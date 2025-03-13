{% if CRYSTAL2DAY_CONFIGS_ANYOLITE %}
  module Crystal2Day
    @[Anyolite::SpecializeInstanceMethod("initialize")]
    class CollisionShape; end

    @[Anyolite::SpecializeInstanceMethod("initialize", [position : Crystal2Day::Coords = Crystal2Day.xy])]
    @[Anyolite::SpecializeInstanceMethod("inspect")]
    class CollisionShapePoint; end

    @[Anyolite::SpecializeInstanceMethod("initialize", [position : Crystal2Day::Coords = Crystal2Day.xy, line : Crystal2Day::Coords = Crystal2Day.xy])]
    @[Anyolite::SpecializeInstanceMethod("inspect")]
    class CollisionShapeLine; end

    @[Anyolite::SpecializeInstanceMethod("initialize", [position : Crystal2Day::Coords = Crystal2Day.xy, radius : Float32 = 0.0f32])]
    @[Anyolite::SpecializeInstanceMethod("inspect")]
    class CollisionShapeCircle; end

    @[Anyolite::SpecializeInstanceMethod("initialize", [position : Crystal2Day::Coords = Crystal2Day.xy, size : Crystal2Day::Coords = Crystal2Day.xy])]
    @[Anyolite::SpecializeInstanceMethod("inspect")]
    class CollisionShapeBox; end

    @[Anyolite::SpecializeInstanceMethod("initialize", [position : Crystal2Day::Coords = Crystal2Day.xy, side_1 : Crystal2Day::Coords = Crystal2Day.xy, side_2 : Crystal2Day::Coords = Crystal2Day.xy])]
    @[Anyolite::SpecializeInstanceMethod("inspect")]
    class CollisionShapeTriangle; end

    @[Anyolite::SpecializeInstanceMethod("initialize", [position : Crystal2Day::Coords = Crystal2Day.xy, semiaxes : Crystal2Day::Coords = Crystal2Day.xy])]
    @[Anyolite::SpecializeInstanceMethod("inspect")]
    class CollisionShapeEllipse; end

    @[Anyolite::SpecializeInstanceMethod("initialize", [r : Number = 0, g : Number = 0, b : Number = 0, a : Number = 255])]
    class Color; end

    @[Anyolite::SpecializeInstanceMethod("initialize", [x : Number = 0.0, y : Number = 0.0])]
    class Coords; end

    @[Anyolite::ExcludeInstanceMethod("add_entity_proc")]
    class Database; end

    @[Anyolite::ExcludeInstanceMethod("initialize", nil)]
    @[Anyolite::ExcludeInstanceMethod("add_hook_from_template")]
    @[Anyolite::ExcludeInstanceMethod("init")]
    @[Anyolite::ExcludeInstanceMethod("update")]
    @[Anyolite::ExcludeInstanceMethod("post_update")]
    @[Anyolite::ExcludeInstanceMethod("handle_event")]
    @[Anyolite::ExcludeInstanceMethod("update_physics")]
    @[Anyolite::ExcludeInstanceMethod("call_existing_hook")]
    @[Anyolite::ExcludeInstanceMethod("call_hook")]
    @[Anyolite::ExcludeInstanceMethod("call_hook_or")]
    @[Anyolite::ExcludeInstanceMethod("delete")]
    @[Anyolite::ExcludeInstanceMethod("call_collision_hooks")]
    @[Anyolite::SpecializeInstanceMethod("set_state", [index : String, value : Crystal2Day::Parameter])]
    @[Anyolite::ExcludeInstanceMethod("update_parts")]
    @[Anyolite::ExcludeInstanceMethod("acceleration_step")]
    @[Anyolite::ExcludeInstanceMethod("update_physics_internal")]
    @[Anyolite::SpecializeInstanceMethod("check_for_collision_with", [other : Entity])]
    @[Anyolite::AddBlockArgInstanceMethod("each_tile_collision", 1, Nil)]
    @[Anyolite::AddBlockArgInstanceMethod("each_entity_collision", 1, Nil)]
    class Entity; end

    @[Anyolite::SpecializeInstanceMethod("initialize", [sprite : Crystal2Day::Sprite])]
    class Part; end

    @[Anyolite::SpecializeInstanceMethod("initialize", [part : Crystal2Day::Part, joint : Crystal2Day::Coords = Crystal2Day.xy, rigid : Bool = false])]
    class PartConnection; end

    @[Anyolite::SpecializeInstanceMethod("initialize", [other_event : Crystal2Day::Event])]
    @[Anyolite::ExcludeInstanceMethod("data")]
    class Event; end

    @[Anyolite::SpecializeInstanceMethod("set_state", [index : String, value : Crystal2Day::Parameter])]
    class GameData; end

    @[Anyolite::ExcludeInstanceMethod("set_key_table_entry")]
    class InputManager; end

    @[Anyolite::SpecializeInstanceMethod("initialize", [x : Number = 0.0, y : Number = 0.0, width : Number = 0.0, height : Number = 0.0])]
    class Rect; end

    @[Anyolite::SpecializeInstanceMethod("initialize", [from_texture : Crystal2Day::Texture = Crystal2Day::Texture.new, source_rect : Crystal2Day::Rect? = nil])]
    class Sprite; end

    @@refs : Array(Anyolite::RbRef) = Array(Anyolite::RbRef).new

    def self.run_interpreter
      Crystal2Day::Interpreter.start
      Crystal2Day::Interpreter.expose_module_only(Crystal2Day)
      # TODO: Maybe just use Anyolite for the whole module
      Crystal2Day::Interpreter.expose_class(Crystal2Day::Coords, under: Crystal2Day)
      Crystal2Day::Interpreter.expose_class(Crystal2Day::Color, under: Crystal2Day)
      Crystal2Day::Interpreter.expose_class(Crystal2Day::CollisionReference, under: Crystal2Day)
      Crystal2Day::Interpreter.expose_class(Crystal2Day::Entity, under: Crystal2Day)
      Crystal2Day::Interpreter.expose_class(Crystal2Day::GameData, under: Crystal2Day)
      Crystal2Day::Interpreter.expose_class(Crystal2Day::Event, under: Crystal2Day)
      Crystal2Day::Interpreter.expose_class(Crystal2Day::Keyboard, under: Crystal2Day)
      Crystal2Day::Interpreter.expose_class(Crystal2Day::Mouse, under: Crystal2Day)
      Crystal2Day::Interpreter.expose_class(Crystal2Day::Rect, under: Crystal2Day)
      Crystal2Day::Interpreter.expose_class(Crystal2Day::InputManager, under: Crystal2Day)
      Crystal2Day::Interpreter.expose_class(Crystal2Day::CollisionShape, under: Crystal2Day)
      Crystal2Day::Interpreter.expose_class(Crystal2Day::SoundBoard, under: Crystal2Day)
      Crystal2Day::Interpreter.expose_class(Crystal2Day::Sprite, under: Crystal2Day)
      Crystal2Day::Interpreter.expose_class(Crystal2Day::Tile, under: Crystal2Day)
      Crystal2Day::Interpreter.expose_class(Crystal2Day::Part, under: Crystal2Day)
      Crystal2Day::Interpreter.expose_class(Crystal2Day::PartConnection, under: Crystal2Day)
      Crystal2Day::Interpreter.expose_class(Crystal2Day::CollisionShapePoint, under: Crystal2Day, connect_to_superclass: true)
      Crystal2Day::Interpreter.expose_class(Crystal2Day::CollisionShapeLine, under: Crystal2Day, connect_to_superclass: true)
      Crystal2Day::Interpreter.expose_class(Crystal2Day::CollisionShapeCircle, under: Crystal2Day, connect_to_superclass: true)
      Crystal2Day::Interpreter.expose_class(Crystal2Day::CollisionShapeBox, under: Crystal2Day, connect_to_superclass: true)
      Crystal2Day::Interpreter.expose_class(Crystal2Day::CollisionShapeTriangle, under: Crystal2Day, connect_to_superclass: true)
      Crystal2Day::Interpreter.expose_class(Crystal2Day::CollisionShapeEllipse, under: Crystal2Day, connect_to_superclass: true)
      Crystal2Day::Interpreter.expose_class_property(Crystal2Day, game_data, Crystal2Day::GameData)
      Crystal2Day::Interpreter.expose_class_property(Crystal2Day, physics_time_step, Float32)
      Crystal2Day::Interpreter.expose_class_property(Crystal2Day, last_event, Crystal2Day::Event)
      Crystal2Day::Interpreter.expose_class_property(Crystal2Day, last_colliding_entity, Crystal2Day::Entity)
      Crystal2Day::Interpreter.expose_class_property(Crystal2Day, input_manager, Crystal2Day::InputManager)
      Crystal2Day::Interpreter.expose_class_property(Crystal2Day, im, Crystal2Day::InputManager)
      Crystal2Day::Interpreter.expose_class_property(Crystal2Day, sb, Crystal2Day::SoundBoard)
      Crystal2Day::Interpreter.expose_class_function(Crystal2Day, xy, [x : Float32 = 0.0f32, y : Float32 = 0.0f32])
      
      # TODO: Is there a better way to protect these?
      @@refs.push Interpreter.generate_ref(input_manager)
      @@refs.push Interpreter.generate_ref(game_data)
      @@refs.push Interpreter.generate_ref(sound_board)

      # TODO: Maybe there's a better way to do this?
      # TODO: Maybe add a module to put these into
      Anyolite.eval("def pause; Fiber.yield; end")
      Anyolite.eval("def pause_times(n); n.times {pause}; end")
      Anyolite.eval("def each_frame; loop do; yield; pause; end; end")
      Anyolite.eval("def for_n_frames(n); n.times do; yield; pause; end; end")

      yield

      Crystal2Day::Interpreter.close
    end
  end
{% end %}