# A template for entities.
# Each instance is essentially a different entity type.
# You can add default state values and coroutines.

module Crystal2Day
  struct EntityTypeBase
    include JSON::Serializable
    
    property entity_type : String = ""

    property overwrite_default_state : Bool = false
    property overwrite_options : Bool = false
    property overwrite_coroutine_templates : Bool = false
    property overwrite_sprite_templates : Bool = false
    property overwrite_boxes : Bool = false
    property overwrite_shapes : Bool = false
    property overwrite_hitshapes : Bool = false
    property overwrite_hurtshapes : Bool = false

    def initialize
    end
  end

  class EntityType
    EMPTY_NAME = "<empty>"
    DEFAULT_NAME = "<default$>"

    @default_state = {} of String => Anyolite::RbRef
    @coroutine_templates = {} of String => Crystal2Day::CoroutineTemplate

    @options = Hash(String, Int64).new

    @sprite_templates = Array(Crystal2Day::SpriteTemplate).new
    @boxes = Array(Crystal2Day::CollisionShapeBox).new
    @shapes = Array(Crystal2Day::CollisionShape).new
    @hitshapes = Array(Crystal2Day::CollisionShape).new
    @hurtshapes = Array(Crystal2Day::CollisionShape).new

    @based_on : EntityTypeBase = EntityTypeBase.new
    
    property name : String = EMPTY_NAME

    def initialize(name : String = EMPTY_NAME)
      if name == EMPTY_NAME
        @name = DEFAULT_NAME.gsub("$", object_id.to_s)
      else
        @name = name
      end
    end

    # TODO: Add hitshapes, hurtshapes, etc to the following routine

    def initialize(pull : JSON::PullParser)
      pull.read_object do |key|
        case key
        when "name" then @name = pull.read_string
        when "based_on" then @based_on = EntityTypeBase.from_json(pull.read_raw)
        when "options"
          pull.read_object do |option_key|
            @options[option_key] = pull.read_int
          end
        when "default_state"
          pull.read_object do |state_key|
            add_default_state_from_raw_json(name: state_key, raw_json: pull.read_raw)
          end
        when "sprite_templates"
          pull.read_array do
            add_sprite_template_from_raw_json(raw_json: pull.read_raw)
          end
        when "coroutine_templates"
          pull.read_object do |coroutine_key|
            # TODO: Cache loaded files, similar to textures
            pull.read_object do |coroutine_type|
              case coroutine_type
              when "file"
                coroutine = CD::CoroutineTemplate.from_string(File.read(pull.read_string), "entity")
                add_coroutine_template(coroutine_key, coroutine)
              when "code"
                coroutine = CD::CoroutineTemplate.from_string(pull.read_string, "entity")
                add_coroutine_template(coroutine_key, coroutine)
              when "proc"
                coroutine = CD::CoroutineTemplate.from_proc_name(pull.read_string)
                add_coroutine_template(coroutine_key, coroutine)
              else
                Crystal2Day.error "Unknown EntityType loading option: #{coroutine_type}"
              end
            end
          end
        when "boxes"
          pull.read_array do
            add_collision_box_from_raw_json(raw_json: pull.read_raw)
          end
        when "shapes"
          pull.read_array do
            add_collision_shape_from_raw_json(raw_json: pull.read_raw)
          end
        when "hitshapes"
          # TODO
        when "hurtshapes"
          # TODO
        when "description"
          # TODO
        end
      end
    end
    
    def add_default_state(name : String, value)
      @default_state[name] = Crystal2Day::Interpreter.generate_ref(value)
    end

    def add_default_state_from_raw_json(name : String, raw_json : String)
      @default_state[name] = Crystal2Day::Interpreter.convert_json_to_ref(raw_json)
    end

    def add_coroutine_template(name : String, template : Crystal2Day::CoroutineTemplate)
      @coroutine_templates[name] = template
    end

    # TODO: Decide whether to access sprites by a key or not (same for shapes)

    def add_sprite_template(sprite_template : Crystal2Day::SpriteTemplate)
      @sprite_templates.push sprite_template
    end

    def add_sprite_template_from_raw_json(raw_json : String)
      @sprite_templates.push Crystal2Day::SpriteTemplate.from_json(raw_json)
    end

    def add_collision_box(collision_box : Crystal2Day::CollisionShapeBox)
      @boxes.push collision_box
    end

    def add_collision_box_from_raw_json(raw_json : String)
      @boxes.push Crystal2Day::CollisionShapeBox.from_json(raw_json)
    end

    def add_collision_shape(collision_shape : Crystal2Day::CollisionShape)
      @shapes.push collision_box
    end

    def add_collision_shape_from_raw_json(raw_json : String)
      @shapes.push Crystal2Day::CollisionShape.from_json(raw_json)
    end

    # TODO: Adding routines for hitshapes and hurtshapes

    def transfer_default_state
      unless @based_on.entity_type.empty?
        if @based_on.overwrite_default_state
          @default_state
        else
          Crystal2Day.database.get_entity_type(@based_on.entity_type).transfer_default_state.merge(@default_state)
        end
      else
        @default_state
      end
    end

    def transfer_coroutine_templates
      unless @based_on.entity_type.empty?
        if @based_on.overwrite_coroutine_templates
          @coroutine_templates
        else
          Crystal2Day.database.get_entity_type(@based_on.entity_type).transfer_coroutine_templates.merge(@coroutine_templates)
        end
      else
        @coroutine_templates
      end
    end

    def transfer_sprite_templates
      unless @based_on.entity_type.empty?
        if @based_on.overwrite_sprite_templates
          @sprite_templates
        else
          Crystal2Day.database.get_entity_type(@based_on.entity_type).transfer_sprite_templates + @sprite_templates
        end
      else
        @sprite_templates
      end
    end

    def transfer_boxes
      unless @based_on.entity_type.empty?
        if @based_on.overwrite_boxes
          @boxes
        else
          Crystal2Day.database.get_entity_type(@based_on.entity_type).transfer_boxes + @boxes
        end
      else
        @boxes
      end
    end

    def transfer_shapes
      unless @based_on.entity_type.empty?
        if @based_on.overwrite_shapes
          @shapes
        else
          Crystal2Day.database.get_entity_type(@based_on.entity_type).transfer_shapes + @shapes
        end
      else
        @shapes
      end
    end

    def transfer_hitshapes
      unless @based_on.entity_type.empty?
        if @based_on.overwrite_hitshapes
          @hitshapes
        else
          Crystal2Day.database.get_entity_type(@based_on.entity_type).transfer_hitshapes + @hitshapes
        end
      else
        @hitshapes
      end
    end

    def transfer_hurtshapes
      unless @based_on.entity_type.empty?
        if @based_on.overwrite_hurtshapes
          @hurtshapes
        else
          Crystal2Day.database.get_entity_type(@based_on.entity_type).transfer_hurtshapes + @hurtshapes
        end
      else
        @hurtshapes
      end
    end

    def transfer_options
      unless @based_on.entity_type.empty?
        if @based_on.overwrite_options
          @options
        else
          Crystal2Day.database.get_entity_type(@based_on.entity_type).transfer_options.merge(@options)
        end
      else
        @options
      end
    end
  end
end
